package com.focusguard.focusguard

import android.app.usage.UsageStatsManager
import android.content.Context
import java.util.Calendar

/**
 * Reads today's per-package foreground usage time. Requires the Usage
 * Access special permission (see PermissionUtils.isUsageAccessGranted) -
 * callers must check that before calling, since without it this simply
 * returns an empty map rather than throwing.
 */
object UsageStatsHelper {

    fun getTodayUsageMillis(context: Context): Map<String, Long> {
        val usageStatsManager =
            context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
                ?: return emptyMap()

        val startOfDay = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
        val now = System.currentTimeMillis()

        val statsList = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startOfDay,
            now,
        ) ?: return emptyMap()

        // Multiple UsageStats entries can exist per package within the
        // queried window (e.g. across a daily boundary edge case) - sum
        // them rather than assuming one entry per package.
        val totals = mutableMapOf<String, Long>()
        for (stats in statsList) {
            if (stats.totalTimeInForeground <= 0) continue
            totals[stats.packageName] = (totals[stats.packageName] ?: 0L) + stats.totalTimeInForeground
        }
        return totals
    }
}
