package com.unchained.unchained

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.app.NotificationCompat
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.Inet4Address
import java.net.InetAddress
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.RejectedExecutionException

private val BLOCKLIST = setOf(
    "pornhub.com",
    "xvideos.com",
    "xnxx.com",
    "redtube.com",
    "youporn.com",
    "xhamster.com",
    "spankbang.com",
    "porn.com",
)

// SharedPreferences storage for the user's custom lists (see UserLists).
const val LISTS_PREFS = "unchained_user_lists"
const val KEY_USER_BLOCKLIST = "user_blocklist"
const val KEY_USER_ALLOWLIST = "user_allowlist"

// Domains that must always pass through, even if a blocklist rule would match
// them. Loaded once at service start from assets/allowlist.txt (one domain per
// line). Checked BEFORE the blocklist, so it can only ever un-block — it never
// blocks anything. Adult domains are deliberately kept out of this file.
@Volatile
private var ALLOWLIST: Set<String> = emptySet()

// User-managed lists, set from the UI via the method channel and persisted to
// SharedPreferences so they survive a service restart. USER_ALLOWLIST un-blocks
// (checked before any block rule); USER_BLOCKLIST blocks extra domains on top
// of the built-in BLOCKLIST.
@Volatile
private var USER_BLOCKLIST: Set<String> = emptySet()
@Volatile
private var USER_ALLOWLIST: Set<String> = emptySet()

private fun matchesAny(lowerDomain: String, list: Set<String>): Boolean {
    if (list.isEmpty()) return false
    return list.any { lowerDomain == it || lowerDomain.endsWith(".$it") }
}

private fun isAllowed(lowerDomain: String): Boolean =
    matchesAny(lowerDomain, ALLOWLIST) || matchesAny(lowerDomain, USER_ALLOWLIST)

private fun isBlocked(domain: String): Boolean {
    if (domain.isEmpty()) return false
    val lower = domain.lowercase()
    // Allowlist wins: a listed domain (or its subdomains) is never blocked.
    if (isAllowed(lower)) return false
    return matchesAny(lower, BLOCKLIST) || matchesAny(lower, USER_BLOCKLIST)
}

class BlockingService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null

    @Volatile private var tunnelThread: Thread? = null
    @Volatile private var shouldRun: Boolean = false

    // Worker pool so a slow/failed upstream DNS lookup never stalls the read loop.
    @Volatile private var executor: ExecutorService? = null
    // Writes to the tun must be serialized across worker threads + the loop thread.
    private val writeLock = Any()
    // Upstream DNS resolvers, resolved from the underlying (non-VPN) network at start,
    // with public fallbacks appended. Captured once when the tunnel comes up.
    @Volatile private var upstreamDns: List<InetAddress> = emptyList()
    // The real network (Wi-Fi/cellular) our upstream queries must go out on. Captured
    // before establish() so it's the actual default link, not our own VPN.
    @Volatile private var underlyingNetwork: Network? = null

    companion object {
        const val TAG = "BlockingService"
        const val CHANNEL_ID = "unchained_protection"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START = "com.unchained.action.START"
        const val ACTION_STOP = "com.unchained.action.STOP"

        @Volatile
        var isRunning: Boolean = false
            private set

        /// The built-in always-blocked domains, exposed for the UI to display.
        fun builtinBlocklist(): List<String> = BLOCKLIST.toList()

        /// Replaces the in-memory user lists and persists them to prefs so the
        /// running tunnel and any later restart both see the change. Domains are
        /// stored lowercased; empties are dropped. Safe to call from any thread.
        fun setUserLists(context: android.content.Context, block: List<String>, allow: List<String>) {
            val b = block.map { it.trim().lowercase() }.filter { it.isNotEmpty() }.toHashSet()
            val a = allow.map { it.trim().lowercase() }.filter { it.isNotEmpty() }.toHashSet()
            USER_BLOCKLIST = b
            USER_ALLOWLIST = a
            context.getSharedPreferences(LISTS_PREFS, Context.MODE_PRIVATE).edit()
                .putStringSet(KEY_USER_BLOCKLIST, b)
                .putStringSet(KEY_USER_ALLOWLIST, a)
                .apply()
        }

        /// Loads the persisted user lists into memory (called on service start).
        fun loadUserLists(context: android.content.Context) {
            val prefs = context.getSharedPreferences(LISTS_PREFS, Context.MODE_PRIVATE)
            USER_BLOCKLIST = prefs.getStringSet(KEY_USER_BLOCKLIST, emptySet())?.toHashSet() ?: hashSetOf()
            USER_ALLOWLIST = prefs.getStringSet(KEY_USER_ALLOWLIST, emptySet())?.toHashSet() ?: hashSetOf()
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        loadAllowlist()
        loadUserLists(this)
    }

    /// Reads assets/allowlist.txt into [ALLOWLIST]. Each non-blank, non-comment
    /// line is one domain. Failure is non-fatal: the allowlist just stays empty
    /// and blocking falls back to the blocklist alone.
    private fun loadAllowlist() {
        try {
            val domains = assets.open("allowlist.txt").bufferedReader().useLines { lines ->
                lines.map { it.trim().lowercase() }
                    .filter { it.isNotEmpty() && !it.startsWith("#") }
                    .toHashSet()
            }
            ALLOWLIST = domains
            Log.i(TAG, "Allowlist loaded: ${domains.size} domains")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load allowlist; continuing without it", e)
            ALLOWLIST = emptySet()
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Protection Status",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                setShowBadge(false)
                lockscreenVisibility = Notification.VISIBILITY_SECRET
            }
            getSystemService(NotificationManager::class.java)
                ?.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pi = PendingIntent.getActivity(
            this, 0,
            launchIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(applicationInfo.icon)
            .setContentTitle("Unchained Protection Active")
            .setContentText("Tap to open")
            .setContentIntent(pi)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        Log.d(TAG, "onStartCommand action=$action")

        if (action == ACTION_STOP) {
            stopVpn()
            return START_NOT_STICKY
        }

        // startForeground MUST be called within 5 seconds. Call before anything that can throw.
        // Use the 2-arg overload so the foregroundServiceType comes from the manifest
        // (declared there as "specialUse"). Specifying a type in code that isn't a subset
        // of the manifest's declared type throws IllegalArgumentException and the system
        // then kills us with ForegroundServiceDidNotStartInTimeException.
        try {
            startForeground(NOTIFICATION_ID, buildNotification())
        } catch (e: Exception) {
            Log.e(TAG, "startForeground failed", e)
            stopSelf()
            return START_NOT_STICKY
        }

        try {
            startVpn()
            isRunning = true
        } catch (e: Exception) {
            Log.e(TAG, "startVpn failed", e)
            stopVpn()
            return START_NOT_STICKY
        }

        return START_STICKY
    }

    private fun startVpn() {
        if (vpnInterface != null) {
            Log.d(TAG, "VPN already running, ignoring start")
            return
        }
        // Resolve the underlying network + its DNS servers BEFORE establishing the VPN.
        // Once establish() runs, ConnectivityManager.activeNetwork becomes our own VPN,
        // and scanning *all* networks picks up resolvers from an inactive link (e.g. the
        // cellular DNS while we're actually on Wi-Fi). Those aren't reachable on the active
        // link, so every query to them stalls for the full socket timeout before falling
        // through to a working server — which is why non-blocked sites were so slow.
        val cm = getSystemService(ConnectivityManager::class.java)
        underlyingNetwork = pickUnderlyingNetwork(cm)
        upstreamDns = resolveUpstreamServers(cm, underlyingNetwork)
        Log.d(TAG, "Underlying network: $underlyingNetwork, upstream DNS: ${upstreamDns.joinToString { it.hostAddress ?: "?" }}")

        val builder = Builder()
            .addAddress("10.0.0.2", 30)
            .addRoute("10.0.0.0", 30)
            .addDnsServer("10.0.0.1")
            .setSession("Unchained")
            .setBlocking(true)
            .setMtu(1500)
        vpnInterface = builder.establish()
        Log.d(TAG, "VPN interface established: ${vpnInterface != null}")

        executor = Executors.newFixedThreadPool(8)

        shouldRun = true
        tunnelThread = Thread { runTunnelLoop() }.apply {
            name = "UnchainedTunnel"
            start()
        }
    }

    private fun stopVpn() {
        shouldRun = false
        executor?.shutdownNow()
        executor = null
        try {
            vpnInterface?.close()
        } catch (e: Exception) {
            Log.e(TAG, "Error closing vpnInterface", e)
        }
        vpnInterface = null
        underlyingNetwork = null
        try {
            tunnelThread?.join(2000)
        } catch (e: InterruptedException) {
            Log.e(TAG, "Interrupted while joining tunnel thread", e)
        }
        tunnelThread = null
        isRunning = false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    override fun onDestroy() {
        stopVpn()
        super.onDestroy()
    }

    override fun onRevoke() {
        stopVpn()
        super.onRevoke()
    }

    // ------------------------------------------------------------------------
    // Tunnel loop + DNS handling
    // ------------------------------------------------------------------------

    private fun runTunnelLoop() {
        val fd = vpnInterface ?: return
        val tunIn = FileInputStream(fd.fileDescriptor)
        val tunOut = FileOutputStream(fd.fileDescriptor)
        val buffer = ByteArray(32767)

        while (shouldRun) {
            val length = try {
                tunIn.read(buffer)
            } catch (e: IOException) {
                break
            }
            if (length <= 0) continue

            try {
                handlePacket(buffer, length, tunOut)
            } catch (e: Exception) {
                Log.e(TAG, "handlePacket error", e)
            }
        }
        Log.d(TAG, "Tunnel loop exited")
    }

    private fun handlePacket(buf: ByteArray, length: Int, tunOut: FileOutputStream) {
        if (length < 28) return  // min: IPv4 (20) + UDP (8)

        val ipVersion = (buf[0].toInt() shr 4) and 0xF
        if (ipVersion != 4) return  // skip IPv6 for now

        val ihl = (buf[0].toInt() and 0xF) * 4
        val protocol = buf[9].toInt() and 0xFF
        if (protocol != 17) return  // not UDP

        val udpStart = ihl
        val srcPort = readU16(buf, udpStart)
        val dstPort = readU16(buf, udpStart + 2)
        if (dstPort != 53) return  // not DNS

        val srcIp = buf.copyOfRange(12, 16)
        val dstIp = buf.copyOfRange(16, 20)

        val dnsStart = udpStart + 8
        if (dnsStart >= length) return
        val dnsPayload = buf.copyOfRange(dnsStart, length)

        val domain = extractFirstQuestionName(dnsPayload)
        Log.d(TAG, "DNS query: '$domain'")

        // Blocked domains are answered immediately (no network needed) right here.
        if (isBlocked(domain)) {
            Log.i(TAG, "BLOCKED: $domain")
            writeResponse(tunOut, srcIp, dstIp, srcPort, craftNxDomainResponse(dnsPayload))
            return
        }

        // Everything else is forwarded upstream on a worker thread, so a slow or
        // failing lookup never freezes the read loop (and therefore all other DNS).
        val exec = executor ?: return
        try {
            exec.execute {
                val responseDns = try {
                    forwardDnsUpstream(dnsPayload)
                } catch (e: Exception) {
                    Log.e(TAG, "Upstream forward failed for $domain", e)
                    return@execute  // drop; the client will retry
                }
                writeResponse(tunOut, srcIp, dstIp, srcPort, responseDns)
            }
        } catch (e: RejectedExecutionException) {
            // Pool is shutting down (stopVpn) — drop the query.
        }
    }

    /**
     * Wraps a DNS payload in an IPv4/UDP packet addressed back to the client and writes
     * it to the tun. Source/destination are swapped so the reply looks like it came from
     * the DNS server the client queried. Writes are serialized because multiple worker
     * threads share the same tun descriptor.
     */
    private fun writeResponse(
        tunOut: FileOutputStream,
        origSrcIp: ByteArray,
        origDstIp: ByteArray,
        origSrcPort: Int,
        dns: ByteArray,
    ) {
        // A late upstream reply can land after the tunnel was torn down; the fd is then
        // closed and writing throws EBADF. Skip quietly instead of logging a stack trace.
        if (!shouldRun) return
        val responsePacket = buildIpv4UdpPacket(
            srcIp = origDstIp,    // swap src/dst
            dstIp = origSrcIp,
            srcPort = 53,
            dstPort = origSrcPort,
            payload = dns,
        )
        synchronized(writeLock) {
            try {
                tunOut.write(responsePacket)
            } catch (e: IOException) {
                Log.e(TAG, "Failed to write response", e)
            }
        }
    }

    /**
     * Picks the real network our upstream DNS queries should go out on. Called BEFORE the
     * VPN is established, so [ConnectivityManager.getActiveNetwork] still returns the OS's
     * actual default link (Wi-Fi when present, otherwise cellular) rather than our VPN.
     * Falls back to the first non-VPN network with internet if there's no active network.
     */
    private fun pickUnderlyingNetwork(cm: ConnectivityManager?): Network? {
        if (cm == null) return null
        val active = cm.activeNetwork
        if (active != null) {
            val caps = cm.getNetworkCapabilities(active)
            if (caps != null &&
                caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
                caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_VPN)
            ) return active
        }
        for (network in cm.allNetworks) {
            val caps = cm.getNetworkCapabilities(network) ?: continue
            if (!caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)) continue
            if (!caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_VPN)) continue
            return network
        }
        return null
    }

    /**
     * The DNS servers to forward non-blocked queries to. Uses the resolvers of the active
     * underlying network only (the ones reachable on the link traffic actually flows over —
     * pulling DNS from an inactive network, e.g. cellular while on Wi-Fi, gives unreachable
     * servers that stall every lookup). Public fallbacks are appended last.
     */
    private fun resolveUpstreamServers(cm: ConnectivityManager?, network: Network?): List<InetAddress> {
        val servers = LinkedHashSet<InetAddress>()
        try {
            if (cm != null && network != null) {
                val lp = cm.getLinkProperties(network)
                if (lp != null) {
                    for (dns in lp.dnsServers) {
                        if (dns is Inet4Address) servers.add(dns)  // packet builder is IPv4-only
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to read system DNS servers", e)
        }
        // Public fallbacks, used only if the system servers are empty or unreachable.
        try { servers.add(InetAddress.getByName("1.1.1.1")) } catch (_: Exception) {}
        try { servers.add(InetAddress.getByName("8.8.8.8")) } catch (_: Exception) {}
        return servers.toList()
    }

    // ------------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------------

    private fun readU16(buf: ByteArray, offset: Int): Int =
        ((buf[offset].toInt() and 0xFF) shl 8) or (buf[offset + 1].toInt() and 0xFF)

    private fun writeU16(buf: ByteArray, offset: Int, value: Int) {
        buf[offset] = ((value shr 8) and 0xFF).toByte()
        buf[offset + 1] = (value and 0xFF).toByte()
    }

    private fun extractFirstQuestionName(dns: ByteArray): String {
        // DNS header is 12 bytes. Question name starts at byte 12.
        if (dns.size < 13) return ""
        val sb = StringBuilder()
        var idx = 12
        while (idx < dns.size) {
            val len = dns[idx].toInt() and 0xFF
            if (len == 0) break
            if ((len and 0xC0) != 0) return ""  // compression pointer in query — unexpected
            if (idx + 1 + len > dns.size) return ""
            if (sb.isNotEmpty()) sb.append('.')
            sb.append(String(dns, idx + 1, len, Charsets.US_ASCII))
            idx += 1 + len
        }
        return sb.toString()
    }

    private fun craftNxDomainResponse(query: ByteArray): ByteArray {
        val response = query.copyOf()
        if (response.size < 12) return response
        // Flags byte 1: set QR=1 (response), keep RD bit, set RA=1 (recursion available)
        response[2] = (response[2].toInt() or 0x80.toByte().toInt()).toByte()
        // Flags byte 2: set RCODE = 3 (NXDOMAIN)
        response[3] = ((response[3].toInt() and 0x70) or 0x80 or 3).toByte()
        // ANCOUNT, NSCOUNT, ARCOUNT all 0
        writeU16(response, 6, 0)
        writeU16(response, 8, 0)
        writeU16(response, 10, 0)
        return response
    }

    private fun forwardDnsUpstream(query: ByteArray): ByteArray {
        val servers = upstreamDns.ifEmpty {
            val cm = getSystemService(ConnectivityManager::class.java)
            resolveUpstreamServers(cm, underlyingNetwork)
        }
        val net = underlyingNetwork
        var lastError: Exception? = null
        for (server in servers) {
            val socket = DatagramSocket()
            try {
                protect(socket)        // CRITICAL: keep this query off our own VPN
                net?.bindSocket(socket)  // and force it out the active link (Wi-Fi/cellular)
                socket.soTimeout = 2000
                socket.send(DatagramPacket(query, query.size, server, 53))
                val recv = ByteArray(4096)
                val pkt = DatagramPacket(recv, recv.size)
                socket.receive(pkt)
                return recv.copyOfRange(0, pkt.length)
            } catch (e: Exception) {
                lastError = e  // this server failed; try the next one
            } finally {
                socket.close()
            }
        }
        throw lastError ?: IOException("No upstream DNS server reachable")
    }

    private fun buildIpv4UdpPacket(
        srcIp: ByteArray,
        dstIp: ByteArray,
        srcPort: Int,
        dstPort: Int,
        payload: ByteArray,
    ): ByteArray {
        val totalLength = 20 + 8 + payload.size
        val pkt = ByteArray(totalLength)

        // IPv4 header
        pkt[0] = 0x45.toByte()                  // version 4, IHL 5
        pkt[1] = 0                              // ToS
        writeU16(pkt, 2, totalLength)           // total length
        writeU16(pkt, 4, 0)                     // identification
        writeU16(pkt, 6, 0x4000)                // flags: don't fragment
        pkt[8] = 64                             // TTL
        pkt[9] = 17                             // protocol UDP
        // checksum placeholder at 10..11
        System.arraycopy(srcIp, 0, pkt, 12, 4)
        System.arraycopy(dstIp, 0, pkt, 16, 4)
        val ipChecksum = ipChecksum(pkt, 0, 20)
        writeU16(pkt, 10, ipChecksum)

        // UDP header
        writeU16(pkt, 20, srcPort)
        writeU16(pkt, 22, dstPort)
        writeU16(pkt, 24, 8 + payload.size)     // UDP length
        writeU16(pkt, 26, 0)                    // UDP checksum 0 (optional in IPv4)

        // Payload
        System.arraycopy(payload, 0, pkt, 28, payload.size)
        return pkt
    }

    private fun ipChecksum(buf: ByteArray, offset: Int, length: Int): Int {
        var sum = 0L
        var i = offset
        while (i < offset + length - 1) {
            sum += readU16(buf, i)
            i += 2
        }
        if (i < offset + length) {
            sum += (buf[i].toInt() and 0xFF) shl 8
        }
        while ((sum shr 16) != 0L) {
            sum = (sum and 0xFFFF) + (sum shr 16)
        }
        return (sum.inv().toInt() and 0xFFFF)
    }
}
