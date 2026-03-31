package com.multando.example

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.multando.sdk.MultandoSDK
import com.multando.sdk.core.MultandoConfig
import com.multando.sdk.models.LoginRequest
import com.multando.sdk.models.ReportDetail
import com.multando.sdk.ui.MultandoColors
import com.multando.sdk.ui.MultandoTheme
import com.multando.sdk.ui.ReportFormScreen
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val client = MultandoSDK.initialize(
            context = this,
            config = MultandoConfig(
                baseUrl = "https://api.multando.io",
                apiKey = "example-api-key",
            ),
        )

        setContent {
            MultandoTheme {
                var isAuthenticated by remember { mutableStateOf(false) }
                var createdReportId by remember { mutableStateOf<String?>(null) }

                if (!isAuthenticated) {
                    LoginScreen(
                        onLoggedIn = { isAuthenticated = true },
                    )
                } else if (createdReportId != null) {
                    SuccessScreen(
                        reportId = createdReportId!!,
                        onCreateAnother = { createdReportId = null },
                    )
                } else {
                    ReportScreen(
                        onReportCreated = { detail ->
                            createdReportId = detail.id
                        },
                    )
                }
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        MultandoSDK.dispose()
    }
}

@Composable
private fun LoginScreen(onLoggedIn: () -> Unit) {
    val scope = rememberCoroutineScope()
    var email by remember { mutableStateOf("demo@multando.io") }
    var password by remember { mutableStateOf("password123") }
    var isLoading by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text(
            text = "Multando",
            fontSize = 28.sp,
            fontWeight = FontWeight.Bold,
            color = MultandoColors.Primary,
        )

        Spacer(modifier = Modifier.height(4.dp))

        Text(
            text = "Report traffic infractions",
            style = MaterialTheme.typography.bodyMedium,
            color = MultandoColors.TextSecondary,
        )

        Spacer(modifier = Modifier.height(32.dp))

        OutlinedTextField(
            value = email,
            onValueChange = { email = it },
            label = { Text("Email") },
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
        )

        Spacer(modifier = Modifier.height(12.dp))

        OutlinedTextField(
            value = password,
            onValueChange = { password = it },
            label = { Text("Password") },
            singleLine = true,
            visualTransformation = PasswordVisualTransformation(),
            modifier = Modifier.fillMaxWidth(),
        )

        if (error != null) {
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = error!!,
                color = MultandoColors.Danger,
                style = MaterialTheme.typography.labelMedium,
            )
        }

        Spacer(modifier = Modifier.height(24.dp))

        Button(
            onClick = {
                scope.launch {
                    isLoading = true
                    error = null
                    try {
                        MultandoSDK.auth.login(LoginRequest(email, password))
                        onLoggedIn()
                    } catch (e: Exception) {
                        error = e.message ?: "Login failed"
                    }
                    isLoading = false
                }
            },
            enabled = !isLoading,
            modifier = Modifier
                .fillMaxWidth()
                .height(48.dp),
            colors = ButtonDefaults.buttonColors(
                containerColor = MultandoColors.Primary,
            ),
        ) {
            if (isLoading) {
                CircularProgressIndicator(
                    modifier = Modifier.size(20.dp),
                    color = Color.White,
                    strokeWidth = 2.dp,
                )
            } else {
                Text("Sign In")
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ReportScreen(onReportCreated: (ReportDetail) -> Unit) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Create Report") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MultandoColors.Primary,
                    titleContentColor = Color.White,
                ),
            )
        },
    ) { padding ->
        Column(modifier = Modifier.padding(padding)) {
            ReportFormScreen(
                infractionService = MultandoSDK.infractions,
                reportService = MultandoSDK.reports,
                onReportCreated = onReportCreated,
            )
        }
    }
}

@Composable
private fun SuccessScreen(reportId: String, onCreateAnother: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text(
            text = "Report Created",
            fontSize = 22.sp,
            fontWeight = FontWeight.Bold,
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = "ID: $reportId",
            style = MaterialTheme.typography.labelMedium,
            color = MultandoColors.TextSecondary,
        )

        Spacer(modifier = Modifier.height(24.dp))

        Button(
            onClick = onCreateAnother,
            colors = ButtonDefaults.buttonColors(
                containerColor = MultandoColors.Primary,
            ),
        ) {
            Text("Create Another")
        }
    }
}
