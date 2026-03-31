package com.multando.sdk.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.multando.sdk.models.ReportSummary

/**
 * A Compose card that displays a report summary.
 *
 * @param report The report summary data.
 * @param onClick Called when the card is tapped.
 * @param modifier Optional [Modifier].
 */
@Composable
fun ReportCard(
    report: ReportSummary,
    modifier: Modifier = Modifier,
    onClick: (() -> Unit)? = null,
) {
    val shortId = if (report.id.length > 8) {
        report.id.take(8).uppercase()
    } else {
        report.id.uppercase()
    }

    Card(
        modifier = modifier
            .fillMaxWidth()
            .then(
                if (onClick != null) Modifier.clickable(onClick = onClick)
                else Modifier
            ),
        shape = RoundedCornerShape(12.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            // Row 1: Short ID + Status badge
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = "#$shortId",
                    style = MaterialTheme.typography.labelMedium,
                    color = MultandoColors.TextSecondary,
                    fontWeight = FontWeight.SemiBold,
                )

                StatusBadge(status = report.status)
            }

            // Row 2: Description
            Text(
                text = report.description,
                style = MaterialTheme.typography.titleMedium,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )

            // Row 3: Location + Date
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                report.location.address?.let { address ->
                    Text(
                        text = address,
                        style = MaterialTheme.typography.labelMedium,
                        color = MultandoColors.TextSecondary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f),
                    )
                } ?: Spacer(modifier = Modifier.weight(1f))

                Spacer(modifier = Modifier.width(8.dp))

                Text(
                    text = report.createdAt,
                    style = MaterialTheme.typography.labelMedium,
                    color = MultandoColors.TextSecondary,
                )
            }
        }
    }
}

/**
 * Pill-shaped status badge.
 */
@Composable
fun StatusBadge(
    status: com.multando.sdk.models.ReportStatus,
    modifier: Modifier = Modifier,
) {
    val color = MultandoColors.statusColor(status)
    val bgColor = MultandoColors.statusBackgroundColor(status)
    val label = MultandoColors.statusLabel(status)

    Surface(
        modifier = modifier,
        shape = RoundedCornerShape(12.dp),
        color = bgColor,
    ) {
        Text(
            text = label,
            modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp),
            color = color,
            fontSize = 11.sp,
            fontWeight = FontWeight.SemiBold,
        )
    }
}
