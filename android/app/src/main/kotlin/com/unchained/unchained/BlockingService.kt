package com.unchained.unchained

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.ServiceInfo
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
import java.net.InetAddress

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

private fun isBlocked(domain: String): Boolean {
    if (domain.isEmpty()) return false
    val lower = domain.lowercase()
    return BLOCKLIST.any { lower == it || lower.endsWith(".$it") }
}

class BlockingService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null

    @Volatile private var tunnelThread: Thread? = null
    @Volatile private var shouldRun: Boolean = false

    companion object {
        const val TAG = "BlockingService"
        const val CHANNEL_ID = "unchained_protection"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START = "com.unchained.action.START"
        const val ACTION_STOP = "com.unchained.action.STOP"

        @Volatile
        var isRunning: Boolean = false
            private set
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
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
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    buildNotification(),
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                )
            } else {
                startForeground(NOTIFICATION_ID, buildNotification())
            }
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
        val builder = Builder()
            .addAddress("10.0.0.2", 30)
            .addRoute("10.0.0.0", 30)
            .addDnsServer("10.0.0.1")
            .setSession("Unchained")
            .setBlocking(true)
            .setMtu(1500)
        vpnInterface = builder.establish()
        Log.d(TAG, "VPN interface established: ${vpnInterface != null}")

        shouldRun = true
        tunnelThread = Thread { runTunnelLoop() }.apply {
            name = "UnchainedTunnel"
            start()
        }
    }

    private fun stopVpn() {
        shouldRun = false
        try {
            vpnInterface?.close()
        } catch (e: Exception) {
            Log.e(TAG, "Error closing vpnInterface", e)
        }
        vpnInterface = null
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

        val responseDns: ByteArray = if (isBlocked(domain)) {
            Log.i(TAG, "BLOCKED: $domain")
            craftNxDomainResponse(dnsPayload)
        } else {
            try {
                forwardDnsUpstream(dnsPayload)
            } catch (e: Exception) {
                Log.e(TAG, "Upstream forward failed for $domain", e)
                return  // drop on upstream failure
            }
        }

        val responsePacket = buildIpv4UdpPacket(
            srcIp = dstIp,    // swap src/dst
            dstIp = srcIp,
            srcPort = 53,
            dstPort = srcPort,
            payload = responseDns,
        )
        try {
            tunOut.write(responsePacket)
        } catch (e: IOException) {
            Log.e(TAG, "Failed to write response", e)
        }
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
        val socket = DatagramSocket()
        try {
            protect(socket)  // CRITICAL: prevent loop through our own VPN
            socket.soTimeout = 5000
            val upstream = InetAddress.getByName("1.1.1.1")
            socket.send(DatagramPacket(query, query.size, upstream, 53))
            val recv = ByteArray(4096)
            val pkt = DatagramPacket(recv, recv.size)
            socket.receive(pkt)
            return recv.copyOfRange(0, pkt.length)
        } finally {
            socket.close()
        }
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
