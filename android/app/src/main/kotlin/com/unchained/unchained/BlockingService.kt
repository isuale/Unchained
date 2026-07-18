package com.unchained.unchained

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.LinkProperties
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
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
import java.util.concurrent.ArrayBlockingQueue
import java.util.concurrent.ExecutorService
import java.util.concurrent.RejectedExecutionException
import java.util.concurrent.ThreadPoolExecutor
import java.util.concurrent.TimeUnit

// A tiny hardcoded core, kept as a safety net even if the asset fails to load.
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

// The large built-in porn blocklist (~1000 most-viewed adult domains), loaded
// once from assets/blocklist.txt. Kept separate from the hardcoded core so the
// core still works if the asset is missing. Loaded lazily so the UI can read
// the count without the VPN service running.
@Volatile
private var BUILTIN_EXTRA: Set<String> = emptySet()

// Well-known DNS-over-HTTPS (DoH) provider endpoints, plus the Firefox "canary".
//
// This is the reason a freshly-added blocked site still loads in the browser:
// modern browsers (Firefox enables this BY DEFAULT) don't ask the system DNS
// for the page. They first resolve a DoH provider here over plain DNS, then send
// every *real* lookup encrypted over HTTPS (port 443) straight to that provider —
// which our port-53 sinkhole never sees, so none of our block rules ever apply.
//
// We defeat the bypass two ways, both keyed off entries in this set:
//   1. `use-application-dns.net` is Firefox's "canary domain". When a network's
//      DNS answers NXDOMAIN for it, Firefox treats that as "this network filters
//      DNS on purpose" and turns DoH OFF, falling back to the system resolver we
//      control. Sinkholing it is the clean, standard opt-out.
//   2. The provider hostnames themselves are sinkholed, so even a browser that
//      ignores the canary can't bootstrap its encrypted resolver and falls back
//      to the system DNS (which routes through this VPN and gets filtered).
//
// Checked BEFORE the allowlist so it can never be re-opened — allowing a DoH
// endpoint would silently reinstate the tunnel around every other rule.
private val DOH_BOOTSTRAP = setOf(
    "use-application-dns.net",      // Firefox canary — NXDOMAIN here disables its DoH
    "cloudflare-dns.com",           // covers mozilla.cloudflare-dns.com (Firefox default)
    "one.one.one.one",
    "dns.google",
    "dns.google.com",
    "dns.quad9.net",
    "doh.opendns.com",
    "dns.nextdns.io",
    "doh.cleanbrowsing.org",
    "dns.adguard.com",
    "dns.adguard-dns.com",
    "mozilla.cloudflare-dns.com",
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

// True if [lowerDomain] equals a list entry or is a subdomain of one. Instead of
// scanning every entry (O(list size) with a string allocation per entry — far too
// slow on the read loop now that the built-in list is ~1000 domains), we hash-look-up
// the domain and each of its parent suffixes: O(number of labels), allocation-light,
// and constant no matter how large the list grows. Semantically identical to the old
// `lowerDomain == it || lowerDomain.endsWith(".$it")` check.
private fun matchesAny(lowerDomain: String, list: Set<String>): Boolean {
    if (list.isEmpty() || lowerDomain.isEmpty()) return false
    if (list.contains(lowerDomain)) return true
    var dot = lowerDomain.indexOf('.')
    while (dot != -1) {
        // Substring after the dot == "lowerDomain ends with .<suffix>".
        if (list.contains(lowerDomain.substring(dot + 1))) return true
        dot = lowerDomain.indexOf('.', dot + 1)
    }
    return false
}

private fun isBlocked(domain: String): Boolean {
    if (domain.isEmpty()) return false
    val lower = domain.lowercase()
    // DoH bootstrap is blocked unconditionally, even past every list: if a
    // browser's encrypted resolver comes up it tunnels around every rule below.
    if (matchesAny(lower, DOH_BOOTSTRAP)) return true
    // The user's OWN choices come first, so he can block (or un-block) ANY
    // domain himself — even one the built-in safelist would otherwise protect
    // (youtube.com, reddit.com, tiktok.com, …). Without this, a user block of a
    // safelisted site was silently swallowed by the allowlist below and the
    // site kept loading. A user un-block wins over a user block if both match.
    if (matchesAny(lower, USER_ALLOWLIST)) return false
    if (matchesAny(lower, USER_BLOCKLIST)) return true
    // Built-in safelist un-blocks; then the built-in porn blocklists block.
    if (matchesAny(lower, ALLOWLIST)) return false
    return matchesAny(lower, BLOCKLIST) ||
        matchesAny(lower, BUILTIN_EXTRA)
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
    // Keeps [underlyingNetwork]/[upstreamDns] live for as long as the VPN runs. Without
    // this, a one-time snapshot goes stale the moment the real network changes underneath
    // the app (Wi-Fi reconnect, handover to cellular, waking from Doze) — every upstream
    // DNS query then binds to a dead Network and fails for the full timeout, forever,
    // until protection is toggled off/on. That's what produced the "internet gets slower
    // and slower until nothing" symptom: failures pile up in the unbounded worker queue
    // and never clear because nothing ever succeeds again.
    private var networkCallback: ConnectivityManager.NetworkCallback? = null

    companion object {
        const val TAG = "BlockingService"
        const val CHANNEL_ID = "unchained_protection"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START = "com.unchained.action.START"
        const val ACTION_STOP = "com.unchained.action.STOP"

        @Volatile
        var isRunning: Boolean = false
            private set

        /// The small hardcoded core, exposed for callers that want a sample.
        fun builtinBlocklist(): List<String> = BLOCKLIST.toList()

        /// Loads assets/blocklist.txt (~1000 porn domains) into [BUILTIN_EXTRA].
        /// Idempotent: skips if already loaded. Non-fatal on failure — the
        /// hardcoded core still blocks the top sites. Lazily callable from the
        /// UI (via [builtinBlocklistCount]) without the VPN service running.
        fun loadBuiltinExtra(context: android.content.Context) {
            if (BUILTIN_EXTRA.isNotEmpty()) return
            try {
                val domains = context.assets.open("blocklist.txt").bufferedReader().useLines { lines ->
                    lines.map { it.trim().lowercase() }
                        .filter { it.isNotEmpty() && !it.startsWith("#") }
                        .toHashSet()
                }
                BUILTIN_EXTRA = domains
            } catch (e: Exception) {
                BUILTIN_EXTRA = emptySet()
            }
        }

        /// Total number of always-blocked built-in domains (core + asset),
        /// for the "N sites blocked" summary in the Blocklist UI.
        fun builtinBlocklistCount(context: android.content.Context): Int {
            loadBuiltinExtra(context)
            return (BLOCKLIST + BUILTIN_EXTRA).size
        }

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
        loadBuiltinExtra(this)
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
        if (cm != null) registerNetworkCallback(cm)

        val builder = Builder()
            .addAddress("10.0.0.2", 30)
            .addRoute("10.0.0.0", 30)
            .addDnsServer("10.0.0.1")
            .setSession("Unchained")
            .setBlocking(true)
            .setMtu(1500)
        vpnInterface = builder.establish()
        Log.d(TAG, "VPN interface established: ${vpnInterface != null}")

        // Bounded queue + drop-oldest: if upstream DNS is ever unreachable for a stretch
        // (bad handover, dead zone), stale queued lookups get discarded in favor of fresh
        // ones instead of piling up forever and dragging every later lookup down with them.
        executor = ThreadPoolExecutor(
            8, 8, 0L, TimeUnit.MILLISECONDS,
            ArrayBlockingQueue(64),
            ThreadPoolExecutor.DiscardOldestPolicy(),
        )

        shouldRun = true
        tunnelThread = Thread { runTunnelLoop() }.apply {
            name = "UnchainedTunnel"
            start()
        }
    }

    /**
     * Keeps [underlyingNetwork] and [upstreamDns] pointed at whatever the real default
     * network currently is, for as long as the VPN runs. Requesting NOT_VPN means this
     * never fires for our own tunnel — only for the actual Wi-Fi/cellular link — so it
     * keeps tracking correctly even after establish() makes [ConnectivityManager] report
     * our own VPN as the process's active network.
     */
    private fun registerNetworkCallback(cm: ConnectivityManager) {
        val request = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .addCapability(NetworkCapabilities.NET_CAPABILITY_NOT_VPN)
            .build()
        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                underlyingNetwork = network
                upstreamDns = resolveUpstreamServers(cm, network)
                Log.d(TAG, "Underlying network available: $network, upstream DNS: ${upstreamDns.joinToString { it.hostAddress ?: "?" }}")
            }

            override fun onLinkPropertiesChanged(network: Network, linkProperties: LinkProperties) {
                if (network != underlyingNetwork) return
                upstreamDns = resolveUpstreamServers(cm, network)
                Log.d(TAG, "Underlying network DNS changed, upstream DNS: ${upstreamDns.joinToString { it.hostAddress ?: "?" }}")
            }

            override fun onLost(network: Network) {
                if (network != underlyingNetwork) return
                Log.d(TAG, "Underlying network lost: $network")
                underlyingNetwork = null
                upstreamDns = emptyList()
            }
        }
        try {
            cm.registerNetworkCallback(request, callback)
            networkCallback = callback
        } catch (e: Exception) {
            Log.e(TAG, "Failed to register network callback; upstream DNS will not track network changes", e)
        }
    }

    private fun stopVpn() {
        shouldRun = false
        executor?.shutdownNow()
        executor = null
        val cm = getSystemService(ConnectivityManager::class.java)
        networkCallback?.let {
            try {
                cm?.unregisterNetworkCallback(it)
            } catch (e: Exception) {
                Log.e(TAG, "Error unregistering network callback", e)
            }
        }
        networkCallback = null
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
            // Don't count DoH bootstrap hits — that's DNS plumbing hygiene, not the
            // user visiting a blocked site, and would pollute the Progress-tab trend.
            if (!matchesAny(domain.lowercase(), DOH_BOOTSTRAP)) {
                BlockingStats.recordBlocked(this)
            }
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
