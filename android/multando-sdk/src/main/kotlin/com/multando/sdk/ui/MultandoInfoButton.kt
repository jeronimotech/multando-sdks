package com.multando.sdk.ui

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.multando.sdk.R

private const val PRINCIPLES_URL = "https://multando.com/principles"

/**
 * A small info button that opens a bottom sheet explaining Multando's
 * responsible reporting principles.
 *
 * Place this anywhere the user can initiate a report (for example next
 * to a "Submit report" action) so the anonymity notice, rate limits
 * and penalties are discoverable at the moment they matter.
 *
 * @param primaryColor Brand tint for the icon and the call-to-action.
 * @param modifier Optional [Modifier] passed to the [IconButton].
 */
@Composable
fun MultandoInfoButton(
    primaryColor: Color = Color(0xFFF97316),
    modifier: Modifier = Modifier,
) {
    var showSheet by remember { mutableStateOf(false) }
    IconButton(onClick = { showSheet = true }, modifier = modifier) {
        Icon(
            imageVector = Icons.Outlined.Info,
            contentDescription = stringResource(R.string.multando_info_button_content_description),
            tint = primaryColor,
        )
    }
    if (showSheet) {
        PrinciplesBottomSheet(
            primaryColor = primaryColor,
            onDismiss = { showSheet = false },
        )
    }
}

/**
 * Modal bottom sheet that lists the five responsible reporting
 * principles and links to the full page at /principles.
 *
 * Public so SDK consumers can trigger it directly (e.g. from a menu
 * item) without rendering [MultandoInfoButton].
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PrinciplesBottomSheet(
    primaryColor: Color = Color(0xFFF97316),
    onDismiss: () -> Unit,
) {
    val context = LocalContext.current
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp)
                .padding(bottom = 24.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text(
                text = stringResource(R.string.multando_responsible_reporting_title),
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface,
            )

            Spacer(modifier = Modifier.size(4.dp))

            PrincipleBullet(
                primaryColor = primaryColor,
                text = stringResource(R.string.multando_responsible_reporting_bullet_1),
            )
            PrincipleBullet(
                primaryColor = primaryColor,
                text = stringResource(R.string.multando_responsible_reporting_bullet_2),
            )
            PrincipleBullet(
                primaryColor = primaryColor,
                text = stringResource(R.string.multando_responsible_reporting_bullet_3),
            )
            PrincipleBullet(
                primaryColor = primaryColor,
                text = stringResource(R.string.multando_responsible_reporting_bullet_4),
            )
            PrincipleBullet(
                primaryColor = primaryColor,
                text = stringResource(R.string.multando_responsible_reporting_bullet_5),
            )

            Spacer(modifier = Modifier.size(8.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                OutlinedButton(
                    onClick = onDismiss,
                    modifier = Modifier.weight(1f),
                ) {
                    Text("Close")
                }
                Button(
                    onClick = {
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(PRINCIPLES_URL))
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        context.startActivity(intent)
                    },
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(containerColor = primaryColor),
                ) {
                    Text(stringResource(R.string.multando_learn_more))
                }
            }
        }
    }
}

@Composable
private fun PrincipleBullet(
    primaryColor: Color,
    text: String,
) {
    Row(verticalAlignment = Alignment.Top) {
        Text(
            text = "•",
            color = primaryColor,
            fontWeight = FontWeight.Bold,
            fontSize = 16.sp,
        )
        Spacer(modifier = Modifier.width(8.dp))
        Text(
            text = text,
            style = MaterialTheme.typography.bodyMedium,
        )
    }
}
