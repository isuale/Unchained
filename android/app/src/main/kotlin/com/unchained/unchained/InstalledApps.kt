package com.unchained.unchained

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.util.Base64
import java.io.ByteArrayOutputStream

/**
 * Enumerates the phone's launchable apps for the prayer app-locker's picker.
 *
 * Uses the MAIN/LAUNCHER query (declared in the manifest's <queries>) so it sees
 * every home-screen app without the sensitive QUERY_ALL_PACKAGES permission.
 * Each entry carries the package name, its user-visible label, and a small PNG
 * icon encoded as base64 so Flutter can render it directly.
 */
object InstalledApps {

    private const val ICON_PX = 96

    /** One map per launchable app: {"package", "label", "icon"} (icon = base64 PNG). */
    fun list(context: Context): List<Map<String, String>> {
        val pm = context.packageManager
        val intent = Intent(Intent.ACTION_MAIN, null)
            .addCategory(Intent.CATEGORY_LAUNCHER)
        val resolved = pm.queryIntentActivities(intent, 0)

        val self = context.packageName
        val seen = HashSet<String>()
        val out = ArrayList<Map<String, String>>()

        for (ri in resolved) {
            val pkg = ri.activityInfo.packageName
            // Skip ourselves (locking the locker makes no sense) and de-dupe
            // apps that expose more than one launcher activity.
            if (pkg == self || !seen.add(pkg)) continue
            val label = ri.loadLabel(pm)?.toString()?.trim().takeUnless { it.isNullOrEmpty() }
                ?: pkg
            val icon = try {
                encodeIcon(ri.loadIcon(pm))
            } catch (e: Exception) {
                ""
            }
            out.add(mapOf("package" to pkg, "label" to label, "icon" to icon))
        }

        out.sortWith(compareBy(String.CASE_INSENSITIVE_ORDER) { it["label"] ?: "" })
        return out
    }

    private fun encodeIcon(drawable: Drawable): String {
        val bmp = drawableToBitmap(drawable)
        val stream = ByteArrayOutputStream()
        bmp.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)
    }

    private fun drawableToBitmap(drawable: Drawable): Bitmap {
        if (drawable is BitmapDrawable && drawable.bitmap != null) {
            return Bitmap.createScaledBitmap(drawable.bitmap, ICON_PX, ICON_PX, true)
        }
        val bmp = Bitmap.createBitmap(ICON_PX, ICON_PX, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bmp
    }
}
