package com.multando.sdk.ui

import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import com.multando.sdk.models.ReportStatus

/**
 * Brand colors for the Multando design system.
 */
object MultandoColors {
    val Primary = Color(0xFF3B5EEF)
    val Success = Color(0xFF10B981)
    val Danger = Color(0xFFEF4444)
    val Warning = Color(0xFFF59E0B)

    val PrimaryLight = Color(0xFFE8EDFD)
    val SuccessLight = Color(0xFFD1FAE5)
    val DangerLight = Color(0xFFFEE2E2)
    val WarningLight = Color(0xFFFEF3C7)

    val TextPrimary = Color(0xFF1F2937)
    val TextSecondary = Color(0xFF6B7280)
    val Surface = Color(0xFFF9FAFB)
    val Border = Color(0xFFE5E7EB)

    /**
     * Returns the appropriate color for a report status.
     */
    fun statusColor(status: ReportStatus): Color = when (status) {
        ReportStatus.PENDING -> Warning
        ReportStatus.UNDER_REVIEW -> Warning
        ReportStatus.VERIFIED -> Success
        ReportStatus.REJECTED -> Danger
        ReportStatus.APPEALED -> Warning
        ReportStatus.RESOLVED -> Success
    }

    /**
     * Returns a light background tint for a report status.
     */
    fun statusBackgroundColor(status: ReportStatus): Color = when (status) {
        ReportStatus.PENDING -> WarningLight
        ReportStatus.UNDER_REVIEW -> WarningLight
        ReportStatus.VERIFIED -> SuccessLight
        ReportStatus.REJECTED -> DangerLight
        ReportStatus.APPEALED -> WarningLight
        ReportStatus.RESOLVED -> SuccessLight
    }

    /**
     * Returns a human-readable label for a report status.
     */
    fun statusLabel(status: ReportStatus): String = when (status) {
        ReportStatus.PENDING -> "Pending"
        ReportStatus.UNDER_REVIEW -> "Under Review"
        ReportStatus.VERIFIED -> "Verified"
        ReportStatus.REJECTED -> "Rejected"
        ReportStatus.APPEALED -> "Appealed"
        ReportStatus.RESOLVED -> "Resolved"
    }
}

private val MultandoLightColorScheme: ColorScheme = lightColorScheme(
    primary = MultandoColors.Primary,
    onPrimary = Color.White,
    secondary = MultandoColors.Success,
    onSecondary = Color.White,
    error = MultandoColors.Danger,
    onError = Color.White,
    background = Color.White,
    onBackground = MultandoColors.TextPrimary,
    surface = MultandoColors.Surface,
    onSurface = MultandoColors.TextPrimary,
)

private val MultandoDarkColorScheme: ColorScheme = darkColorScheme(
    primary = MultandoColors.Primary,
    onPrimary = Color.White,
    secondary = MultandoColors.Success,
    onSecondary = Color.White,
    error = MultandoColors.Danger,
    onError = Color.White,
)

private val MultandoTypography = Typography(
    headlineMedium = TextStyle(
        fontWeight = FontWeight.Bold,
        fontSize = 20.sp,
        color = MultandoColors.TextPrimary,
    ),
    titleMedium = TextStyle(
        fontWeight = FontWeight.SemiBold,
        fontSize = 16.sp,
        color = MultandoColors.TextPrimary,
    ),
    bodyMedium = TextStyle(
        fontWeight = FontWeight.Normal,
        fontSize = 14.sp,
        color = MultandoColors.TextPrimary,
    ),
    labelMedium = TextStyle(
        fontWeight = FontWeight.Medium,
        fontSize = 12.sp,
        color = MultandoColors.TextSecondary,
    ),
)

/**
 * Wraps content in the Multando Material3 theme.
 *
 * ```kotlin
 * MultandoTheme {
 *     ReportFormScreen(onReportCreated = { ... })
 * }
 * ```
 */
@Composable
fun MultandoTheme(
    darkTheme: Boolean = false,
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colorScheme = if (darkTheme) MultandoDarkColorScheme else MultandoLightColorScheme,
        typography = MultandoTypography,
        content = content,
    )
}
