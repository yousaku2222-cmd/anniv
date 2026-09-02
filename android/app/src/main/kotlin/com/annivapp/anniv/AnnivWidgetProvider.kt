package com.annivapp.anniv

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import kotlin.math.roundToInt

/**
 * Home-screen widget backing view. Data is pushed from Flutter via the
 * `home_widget` plugin (see AppHomeWidgetService); this class just renders
 * whatever keys are currently stored.
 */
class AnnivWidgetProvider : HomeWidgetProvider() {

    /**
     * The `home_widget` plugin's saveWidgetData stores a Dart `int` as either
     * a Kotlin Int or Long depending on the platform channel's encoding of its
     * magnitude (e.g. an opaque ARGB colour always exceeds Int32 range and
     * arrives as Long) — [SharedPreferences.getInt] throws ClassCastException
     * if the stored value is actually a Long, so read leniently instead.
     */
    private fun readInt(widgetData: SharedPreferences, key: String, default: Int): Int =
        when (val v = widgetData.all[key]) {
            is Int -> v
            is Long -> v.toInt()
            else -> default
        }

    /**
     * Renders the event's colour + Material icon glyph as a bitmap in our own
     * process. RemoteViews are inflated by the launcher's process, which does
     * not reliably resolve a custom `android:fontFamily` bundled in our APK
     * (observed as a "tofu" placeholder box on-device) — baking pixels here
     * and handing the launcher a plain bitmap sidesteps that entirely.
     */
    private fun renderIconChip(context: Context, codePoint: Int, color: Int): Bitmap {
        val density = context.resources.displayMetrics.density
        // 2x oversample the 20dp layout slot so the glyph stays crisp.
        val sizePx = (20 * density * 2).roundToInt()
        val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { this.color = color }
        val radius = sizePx * 0.3f
        canvas.drawRoundRect(RectF(0f, 0f, sizePx.toFloat(), sizePx.toFloat()), radius, radius, bgPaint)

        val glyphPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = android.graphics.Color.WHITE
            textSize = sizePx * 0.6f
            textAlign = Paint.Align.CENTER
            typeface = iconTypeface(context)
        }
        val glyph = String(Character.toChars(codePoint))
        val textY = sizePx / 2f - (glyphPaint.descent() + glyphPaint.ascent()) / 2f
        canvas.drawText(glyph, sizePx / 2f, textY, glyphPaint)

        return bitmap
    }

    private fun iconTypeface(context: Context): Typeface =
        cachedTypeface ?: Typeface.createFromAsset(
            context.applicationContext.assets,
            "fonts/materialicons_regular.otf",
        ).also { cachedTypeface = it }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.anniv_widget).apply {
                val empty = widgetData.getBoolean("anniv_empty", true)
                val title = widgetData.getString("anniv_title", null) ?: "記念日を追加"
                val count = widgetData.getString("anniv_count", null) ?: "—"
                val unit = widgetData.getString("anniv_unit", null) ?: ""
                val caption = widgetData.getString("anniv_caption", null) ?: ""
                // Defaults mirror WidgetSnapshot.none (Icons.auto_awesome_outlined, Anniv brand).
                val iconCodePoint = readInt(widgetData, "anniv_icon_codepoint", 0xeea9)
                val color = readInt(widgetData, "anniv_color", 0xFFE85D43.toInt())

                setTextViewText(R.id.anniv_widget_title, title)
                setTextViewText(R.id.anniv_widget_count, if (empty) "—" else count + unit)
                setTextViewText(R.id.anniv_widget_caption, caption)
                setImageViewBitmap(
                    R.id.anniv_widget_icon,
                    renderIconChip(context, iconCodePoint, color),
                )
                setTextColor(R.id.anniv_widget_count, color)

                setOnClickPendingIntent(
                    R.id.anniv_widget_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    companion object {
        @Volatile
        private var cachedTypeface: Typeface? = null
    }
}
