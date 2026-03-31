package com.multando.sdk.ui

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Divider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.multando.sdk.models.InfractionResponse
import com.multando.sdk.models.InfractionSeverity
import com.multando.sdk.models.LocationData
import com.multando.sdk.models.ReportCreate
import com.multando.sdk.models.ReportDetail
import com.multando.sdk.models.ReportSource
import com.multando.sdk.services.InfractionService
import com.multando.sdk.services.ReportService
import kotlinx.coroutines.launch
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

/**
 * A Jetpack Compose screen that guides the user through a 3-step report creation:
 *
 * 1. Select an infraction from the list.
 * 2. Enter details: plate number, location, date/time.
 * 3. Review and submit.
 *
 * @param infractionService Service used to fetch available infractions.
 * @param reportService Service used to create the report.
 * @param onReportCreated Callback invoked with the created report.
 */
@Composable
fun ReportFormScreen(
    infractionService: InfractionService,
    reportService: ReportService,
    onReportCreated: (ReportDetail) -> Unit,
) {
    val scope = rememberCoroutineScope()

    var currentStep by remember { mutableIntStateOf(0) }

    // Step 1 state
    var infractions by remember { mutableStateOf<List<InfractionResponse>>(emptyList()) }
    var isLoadingInfractions by remember { mutableStateOf(true) }
    var loadError by remember { mutableStateOf<String?>(null) }
    var selectedInfraction by remember { mutableStateOf<InfractionResponse?>(null) }

    // Step 2 state
    var plateNumber by remember { mutableStateOf(TextFieldValue("")) }
    var locationText by remember { mutableStateOf(TextFieldValue("")) }
    var occurredAt by remember { mutableStateOf(LocalDateTime.now()) }

    // Step 3 state
    var isSubmitting by remember { mutableStateOf(false) }
    var submitError by remember { mutableStateOf<String?>(null) }

    // Load infractions on first composition
    LaunchedEffect(Unit) {
        try {
            infractions = infractionService.list()
            isLoadingInfractions = false
        } catch (e: Exception) {
            loadError = e.message
            isLoadingInfractions = false
        }
    }

    Column(modifier = Modifier.fillMaxSize()) {
        // Step indicator
        StepIndicator(
            currentStep = currentStep,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 12.dp),
        )

        Divider()

        // Content
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
        ) {
            when (currentStep) {
                0 -> InfractionPickerStep(
                    infractions = infractions,
                    isLoading = isLoadingInfractions,
                    error = loadError,
                    selectedId = selectedInfraction?.id,
                    onSelect = { selectedInfraction = it },
                    onRetry = {
                        scope.launch {
                            isLoadingInfractions = true
                            loadError = null
                            try {
                                infractions = infractionService.list(forceRefresh = true)
                            } catch (e: Exception) {
                                loadError = e.message
                            }
                            isLoadingInfractions = false
                        }
                    },
                )
                1 -> DetailsStep(
                    plateNumber = plateNumber,
                    onPlateChange = { plateNumber = it },
                    locationText = locationText,
                    onLocationChange = { locationText = it },
                    occurredAt = occurredAt,
                )
                2 -> ReviewStep(
                    infraction = selectedInfraction,
                    plateNumber = plateNumber.text,
                    locationText = locationText.text,
                    occurredAt = occurredAt,
                    submitError = submitError,
                )
            }
        }

        Divider()

        // Navigation buttons
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            if (currentStep > 0) {
                OutlinedButton(
                    onClick = { currentStep-- },
                    enabled = !isSubmitting,
                ) {
                    Text("Back")
                }
            } else {
                Spacer(modifier = Modifier.width(1.dp))
            }

            if (currentStep < 2) {
                Button(
                    onClick = { currentStep++ },
                    enabled = when (currentStep) {
                        0 -> selectedInfraction != null
                        1 -> plateNumber.text.isNotBlank() && locationText.text.isNotBlank()
                        else -> true
                    },
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MultandoColors.Primary,
                    ),
                ) {
                    Text("Next")
                }
            } else {
                Button(
                    onClick = {
                        scope.launch {
                            isSubmitting = true
                            submitError = null
                            try {
                                val report = ReportCreate(
                                    infractionId = selectedInfraction!!.id,
                                    vehicleTypeId = "",
                                    licensePlate = plateNumber.text.trim(),
                                    description = "Report via SDK",
                                    location = LocationData(
                                        latitude = 0.0,
                                        longitude = 0.0,
                                        address = locationText.text.trim(),
                                    ),
                                    occurredAt = occurredAt.format(DateTimeFormatter.ISO_LOCAL_DATE_TIME),
                                    source = ReportSource.SDK,
                                )
                                val detail = reportService.create(report)
                                onReportCreated(detail)
                            } catch (e: Exception) {
                                submitError = e.message ?: "Submission failed"
                                isSubmitting = false
                            }
                        }
                    },
                    enabled = !isSubmitting,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MultandoColors.Primary,
                    ),
                ) {
                    if (isSubmitting) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(18.dp),
                            color = Color.White,
                            strokeWidth = 2.dp,
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                    }
                    Text(if (isSubmitting) "Submitting..." else "Submit Report")
                }
            }
        }
    }
}

@Composable
private fun StepIndicator(currentStep: Int, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier,
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Center,
    ) {
        StepDot(index = 0, currentStep = currentStep, label = "Infraction")
        StepLine(completed = currentStep > 0, modifier = Modifier.weight(1f))
        StepDot(index = 1, currentStep = currentStep, label = "Details")
        StepLine(completed = currentStep > 1, modifier = Modifier.weight(1f))
        StepDot(index = 2, currentStep = currentStep, label = "Submit")
    }
}

@Composable
private fun StepDot(index: Int, currentStep: Int, label: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Surface(
            modifier = Modifier.size(if (index == currentStep) 14.dp else 10.dp),
            shape = CircleShape,
            color = if (index <= currentStep) MultandoColors.Primary else MultandoColors.Border,
        ) {}
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = label,
            fontSize = 10.sp,
            fontWeight = if (index <= currentStep) FontWeight.SemiBold else FontWeight.Normal,
            color = if (index <= currentStep) MultandoColors.Primary else MultandoColors.TextSecondary,
        )
    }
}

@Composable
private fun StepLine(completed: Boolean, modifier: Modifier = Modifier) {
    Surface(
        modifier = modifier
            .height(2.dp)
            .padding(horizontal = 4.dp),
        color = if (completed) MultandoColors.Primary else MultandoColors.Border,
    ) {}
}

@Composable
private fun InfractionPickerStep(
    infractions: List<InfractionResponse>,
    isLoading: Boolean,
    error: String?,
    selectedId: String?,
    onSelect: (InfractionResponse) -> Unit,
    onRetry: () -> Unit,
) {
    if (isLoading) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 40.dp),
            contentAlignment = Alignment.Center,
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                CircularProgressIndicator(color = MultandoColors.Primary)
                Spacer(modifier = Modifier.height(12.dp))
                Text("Loading infractions...")
            }
        }
        return
    }

    if (error != null) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 40.dp),
            contentAlignment = Alignment.Center,
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text("Failed to load infractions", color = MultandoColors.Danger)
                Spacer(modifier = Modifier.height(4.dp))
                Text(error, style = MaterialTheme.typography.labelMedium, color = MultandoColors.TextSecondary)
                Spacer(modifier = Modifier.height(8.dp))
                OutlinedButton(onClick = onRetry) { Text("Retry") }
            }
        }
        return
    }

    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        infractions.forEach { infraction ->
            val isSelected = infraction.id == selectedId
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { onSelect(infraction) },
                shape = RoundedCornerShape(10.dp),
                border = BorderStroke(
                    1.dp,
                    if (isSelected) MultandoColors.Primary else MultandoColors.Border,
                ),
                colors = CardDefaults.cardColors(
                    containerColor = if (isSelected) MultandoColors.PrimaryLight else Color.White,
                ),
            ) {
                Row(
                    modifier = Modifier.padding(12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = infraction.name,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
                        )
                        Text(
                            text = infraction.description,
                            style = MaterialTheme.typography.labelMedium,
                            maxLines = 2,
                            overflow = TextOverflow.Ellipsis,
                        )
                    }
                    Spacer(modifier = Modifier.width(8.dp))
                    SeverityPill(severity = infraction.severity)
                }
            }
        }
    }
}

@Composable
private fun SeverityPill(severity: InfractionSeverity) {
    val (label, color) = when (severity) {
        InfractionSeverity.LOW -> "Low" to MultandoColors.Success
        InfractionSeverity.MEDIUM -> "Medium" to MultandoColors.Warning
        InfractionSeverity.HIGH -> "High" to MultandoColors.Danger
        InfractionSeverity.CRITICAL -> "Critical" to Color(0xFF7C3AED)
    }

    Surface(
        shape = RoundedCornerShape(8.dp),
        color = color.copy(alpha = 0.15f),
    ) {
        Text(
            text = label,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp),
            color = color,
            fontSize = 11.sp,
            fontWeight = FontWeight.SemiBold,
        )
    }
}

@Composable
private fun DetailsStep(
    plateNumber: TextFieldValue,
    onPlateChange: (TextFieldValue) -> Unit,
    locationText: TextFieldValue,
    onLocationChange: (TextFieldValue) -> Unit,
    occurredAt: LocalDateTime,
) {
    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        OutlinedTextField(
            value = plateNumber,
            onValueChange = onPlateChange,
            label = { Text("Vehicle Plate") },
            placeholder = { Text("e.g. ABC-1234") },
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
        )

        OutlinedTextField(
            value = locationText,
            onValueChange = onLocationChange,
            label = { Text("Location") },
            placeholder = { Text("Street address or description") },
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
        )

        Column {
            Text(
                text = "Date & Time",
                style = MaterialTheme.typography.labelMedium,
                color = MultandoColors.TextSecondary,
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = occurredAt.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm")),
                style = MaterialTheme.typography.bodyMedium,
            )
        }
    }
}

@Composable
private fun ReviewStep(
    infraction: InfractionResponse?,
    plateNumber: String,
    locationText: String,
    occurredAt: LocalDateTime,
    submitError: String?,
) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        ReviewRow(label = "Infraction", value = infraction?.name ?: "-")
        ReviewRow(
            label = "Severity",
            value = infraction?.severity?.name?.lowercase()?.replaceFirstChar { it.uppercase() } ?: "-",
        )
        ReviewRow(label = "Plate", value = plateNumber.ifBlank { "-" })
        ReviewRow(label = "Location", value = locationText.ifBlank { "-" })
        ReviewRow(
            label = "Date",
            value = occurredAt.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm")),
        )

        if (submitError != null) {
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = submitError,
                color = MultandoColors.Danger,
                style = MaterialTheme.typography.labelMedium,
            )
        }
    }
}

@Composable
private fun ReviewRow(label: String, value: String) {
    Column {
        Text(
            text = label,
            style = MaterialTheme.typography.labelMedium,
            color = MultandoColors.TextSecondary,
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
        )
    }
}
