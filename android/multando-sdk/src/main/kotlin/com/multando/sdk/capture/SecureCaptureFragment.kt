package com.multando.sdk.capture

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.location.Location
import android.net.Uri
import android.os.Bundle
import android.view.LayoutInflater
import android.view.ViewGroup
import android.view.WindowManager
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import androidx.lifecycle.compose.LocalLifecycleOwner
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.google.android.gms.tasks.CancellationTokenSource
import java.io.File
import java.text.SimpleDateFormat
import java.time.Instant
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine
import kotlin.math.abs
import kotlin.math.sqrt
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Fragment hosting a Jetpack Compose secure capture UI.
 *
 * Uses CameraX for camera capture, PhotoPicker for gallery selection,
 * FusedLocationProviderClient for GPS, and the Android SensorManager for
 * motion detection. Supports both camera and gallery (gallery is essential
 * for emulator testing).
 */
class SecureCaptureFragment : Fragment() {

    /** Callback set by the host activity/fragment. */
    var onEvidence: ((SecureEvidence) -> Unit)? = null
    var onClose: (() -> Unit)? = null

    private val permissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { /* permissions handled in Compose state */ }

    // Gallery picker result holder — consumed by the Compose layer
    private var galleryResultUri = mutableStateOf<Uri?>(null)

    private val galleryLauncher = registerForActivityResult(
        ActivityResultContracts.PickVisualMedia()
    ) { uri ->
        galleryResultUri.value = uri
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?,
    ) = ComposeView(requireContext()).apply {
        setContent {
            SecureCaptureScreen(
                onEvidence = { onEvidence?.invoke(it) },
                onClose = { onClose?.invoke() },
                requestPermissions = {
                    permissionLauncher.launch(
                        arrayOf(
                            Manifest.permission.CAMERA,
                            Manifest.permission.ACCESS_FINE_LOCATION,
                        )
                    )
                },
                onPickGallery = {
                    galleryLauncher.launch(
                        PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                    )
                },
                galleryResultUri = galleryResultUri,
            )
        }
    }

    override fun onResume() {
        super.onResume()
        // Prevent screenshots while capturing
        activity?.window?.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE,
        )
    }

    override fun onPause() {
        super.onPause()
        activity?.window?.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}

// ---------------------------------------------------------------------------
// Compose UI
// ---------------------------------------------------------------------------

@Composable
private fun SecureCaptureScreen(
    onEvidence: (SecureEvidence) -> Unit,
    onClose: () -> Unit,
    requestPermissions: () -> Unit,
    onPickGallery: () -> Unit,
    galleryResultUri: MutableState<Uri?>,
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current

    val hasCameraPerm = ContextCompat.checkSelfPermission(
        context, Manifest.permission.CAMERA
    ) == PackageManager.PERMISSION_GRANTED
    val hasLocPerm = ContextCompat.checkSelfPermission(
        context, Manifest.permission.ACCESS_FINE_LOCATION
    ) == PackageManager.PERMISSION_GRANTED

    var capturing by remember { mutableStateOf(false) }
    var signing by remember { mutableStateOf(false) }
    var flashOn by remember { mutableStateOf(false) }
    var useFront by remember { mutableStateOf(false) }
    var previewEvidence by remember { mutableStateOf<SecureEvidence?>(null) }
    var previewBytes by remember { mutableStateOf<ByteArray?>(null) }

    val imageCapture = remember { ImageCapture.Builder().build() }
    val coroutineScope = rememberCoroutineScope()

    // Observe gallery pick results
    val pickedUri = galleryResultUri.value
    LaunchedEffect(pickedUri) {
        if (pickedUri != null) {
            galleryResultUri.value = null
            capturing = true
            signing = true
            try {
                val (evidence, bytes) = processGalleryUri(context, pickedUri)
                previewEvidence = evidence
                previewBytes = bytes
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                capturing = false
                signing = false
            }
        }
    }

    // Permission gate
    if (!hasCameraPerm || !hasLocPerm) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.Black),
            contentAlignment = Alignment.Center,
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    "Camera and Location permissions required.",
                    color = Color.White,
                    fontSize = 16.sp,
                )
                Spacer(Modifier.height(16.dp))
                Button(onClick = requestPermissions) {
                    Text("Grant Permissions")
                }
            }
        }
        return
    }

    // Preview mode
    if (previewEvidence != null && previewBytes != null) {
        val bitmap = remember(previewBytes) {
            BitmapFactory.decodeByteArray(previewBytes, 0, previewBytes!!.size)
        }
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.Black)
        ) {
            Box(modifier = Modifier.weight(1f)) {
                if (bitmap != null) {
                    Image(
                        bitmap = bitmap.asImageBitmap(),
                        contentDescription = "Captured evidence",
                        modifier = Modifier.fillMaxSize(),
                        contentScale = ContentScale.Fit,
                    )
                }
                // Gradient overlay
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(60.dp)
                        .align(Alignment.TopCenter)
                        .background(
                            Brush.verticalGradient(
                                listOf(Color.Black.copy(alpha = 0.4f), Color.Transparent)
                            )
                        )
                )
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(60.dp)
                        .align(Alignment.BottomCenter)
                        .background(
                            Brush.verticalGradient(
                                listOf(Color.Transparent, Color.Black.copy(alpha = 0.5f))
                            )
                        )
                )

                // Top: branding + signed badge
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(12.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                ) {
                    // MULTANDO badge
                    Text(
                        "MULTANDO",
                        color = Color.White,
                        fontWeight = FontWeight.ExtraBold,
                        fontSize = 12.sp,
                        letterSpacing = 1.sp,
                        modifier = Modifier
                            .background(
                                Color.Red.copy(alpha = 0.8f),
                                RoundedCornerShape(6.dp),
                            )
                            .padding(horizontal = 8.dp, vertical = 4.dp),
                    )
                    // Signed badge
                    Text(
                        "SIGNED",
                        color = Color.White,
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier
                            .background(
                                Color.Green.copy(alpha = 0.8f),
                                RoundedCornerShape(6.dp),
                            )
                            .padding(horizontal = 8.dp, vertical = 4.dp),
                    )
                }

                // Bottom: capture method + metadata
                Column(
                    modifier = Modifier
                        .align(Alignment.BottomStart)
                        .padding(12.dp),
                ) {
                    // Capture method
                    Text(
                        text = if (previewEvidence!!.captureMethod == "camera") "Camera" else "Gallery",
                        color = Color.White,
                        fontSize = 9.sp,
                        fontWeight = FontWeight.SemiBold,
                        modifier = Modifier
                            .background(
                                Color(0xFF6366F1).copy(alpha = 0.7f),
                                RoundedCornerShape(4.dp),
                            )
                            .padding(horizontal = 6.dp, vertical = 2.dp),
                    )
                    Spacer(Modifier.height(4.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                    ) {
                        Text(
                            formatTimestamp(previewEvidence!!.timestamp),
                            color = Color.White,
                            fontSize = 11.sp,
                            fontWeight = FontWeight.SemiBold,
                        )
                        Text(
                            formatGps(previewEvidence!!.latitude, previewEvidence!!.longitude),
                            color = Color.White,
                            fontSize = 11.sp,
                            fontWeight = FontWeight.SemiBold,
                        )
                    }
                }
            }
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(Color.Black.copy(alpha = 0.85f))
                    .padding(vertical = 20.dp, horizontal = 16.dp),
                horizontalArrangement = Arrangement.SpaceEvenly,
            ) {
                Button(
                    onClick = { previewEvidence = null; previewBytes = null },
                    colors = ButtonDefaults.buttonColors(containerColor = Color.Gray),
                ) { Text("Retake") }
                Button(
                    onClick = {
                        previewEvidence?.let(onEvidence)
                        previewEvidence = null
                        previewBytes = null
                    },
                ) { Text("Confirm") }
            }
        }
        return
    }

    // Camera
    Box(modifier = Modifier.fillMaxSize().background(Color.Black)) {
        // CameraX preview
        AndroidView(
            factory = { ctx ->
                val previewView = androidx.camera.view.PreviewView(ctx)
                val cameraProviderFuture = ProcessCameraProvider.getInstance(ctx)
                cameraProviderFuture.addListener({
                    val cameraProvider = cameraProviderFuture.get()
                    val preview = Preview.Builder().build().also {
                        it.surfaceProvider = previewView.surfaceProvider
                    }
                    val selector = if (useFront) CameraSelector.DEFAULT_FRONT_CAMERA
                    else CameraSelector.DEFAULT_BACK_CAMERA
                    cameraProvider.unbindAll()
                    cameraProvider.bindToLifecycle(
                        lifecycleOwner, selector, preview, imageCapture
                    )
                }, ContextCompat.getMainExecutor(ctx))
                previewView
            },
            modifier = Modifier.fillMaxSize(),
        )

        // Live watermark
        Text(
            "MULTANDO",
            color = Color.White.copy(alpha = 0.75f),
            fontWeight = FontWeight.ExtraBold,
            fontSize = 12.sp,
            letterSpacing = 1.sp,
            modifier = Modifier
                .padding(12.dp)
                .background(
                    Color.Red.copy(alpha = 0.8f),
                    RoundedCornerShape(6.dp),
                )
                .padding(horizontal = 8.dp, vertical = 4.dp),
        )

        // Signing overlay
        if (signing) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.5f)),
                contentAlignment = Alignment.Center,
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    CircularProgressIndicator(color = Color.White)
                    Spacer(Modifier.height(12.dp))
                    Text(
                        "Signing evidence...",
                        color = Color.White,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.SemiBold,
                    )
                }
            }
        }

        // Controls
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .align(Alignment.BottomCenter)
                .background(Color.Black.copy(alpha = 0.7f))
                .padding(vertical = 20.dp, horizontal = 16.dp)
                .padding(bottom = 20.dp),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            // Close
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .clip(CircleShape)
                    .background(Color.White.copy(alpha = 0.15f))
                    .clickable { onClose() },
                contentAlignment = Alignment.Center,
            ) { Text("✕", color = Color.White, fontSize = 20.sp) }

            // Flash
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .clip(CircleShape)
                    .background(Color.White.copy(alpha = 0.15f))
                    .clickable {
                        flashOn = !flashOn
                        imageCapture.flashMode =
                            if (flashOn) ImageCapture.FLASH_MODE_ON else ImageCapture.FLASH_MODE_OFF
                    },
                contentAlignment = Alignment.Center,
            ) { Text(if (flashOn) "⚡" else "⚡\u0336", color = Color.White, fontSize = 20.sp) }

            // Capture button
            Box(
                modifier = Modifier
                    .size(72.dp)
                    .clip(CircleShape)
                    .clickable(enabled = !capturing) {
                        coroutineScope.launch {
                            captureEvidence(
                                context = context,
                                imageCapture = imageCapture,
                                onCapturing = { capturing = it },
                                onSigning = { signing = it },
                                onResult = { evidence, bytes ->
                                    previewEvidence = evidence
                                    previewBytes = bytes
                                },
                            )
                        }
                    },
                contentAlignment = Alignment.Center,
            ) {
                Box(
                    modifier = Modifier
                        .size(72.dp)
                        .clip(CircleShape)
                        .background(Color.Transparent),
                )
                if (capturing) {
                    CircularProgressIndicator(
                        color = Color.White,
                        modifier = Modifier.size(32.dp),
                        strokeWidth = 3.dp,
                    )
                } else {
                    Box(
                        modifier = Modifier
                            .size(56.dp)
                            .clip(CircleShape)
                            .background(Color.White),
                    )
                }
            }

            // Gallery button
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .clip(CircleShape)
                    .background(Color.White.copy(alpha = 0.15f))
                    .clickable { onPickGallery() },
                contentAlignment = Alignment.Center,
            ) { Text("🖼", fontSize = 20.sp) }

            // Flip camera
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .clip(CircleShape)
                    .background(Color.White.copy(alpha = 0.15f))
                    .clickable { useFront = !useFront },
                contentAlignment = Alignment.Center,
            ) { Text("🔄", fontSize = 20.sp) }
        }
    }
}

// ---------------------------------------------------------------------------
// Formatting helpers
// ---------------------------------------------------------------------------

private fun formatTimestamp(iso: String): String {
    return try {
        val instant = Instant.parse(iso)
        val sdf = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US)
        sdf.timeZone = TimeZone.getTimeZone("UTC")
        sdf.format(Date.from(instant)) + " UTC"
    } catch (_: Exception) {
        iso
    }
}

private fun formatGps(lat: Double, lon: Double): String {
    val latDir = if (lat >= 0) "N" else "S"
    val lonDir = if (lon >= 0) "E" else "W"
    return "%.4f%s %.4f%s".format(abs(lat), latDir, abs(lon), lonDir)
}

// ---------------------------------------------------------------------------
// Camera capture logic
// ---------------------------------------------------------------------------

private suspend fun captureEvidence(
    context: Context,
    imageCapture: ImageCapture,
    onCapturing: (Boolean) -> Unit,
    onSigning: (Boolean) -> Unit,
    onResult: (SecureEvidence, ByteArray) -> Unit,
) {
    onCapturing(true)
    onSigning(true)
    try {
        // Motion detection
        var motionDetected = false
        val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        val listener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                val mag = sqrt(
                    event.values[0] * event.values[0] +
                        event.values[1] * event.values[1] +
                        event.values[2] * event.values[2]
                )
                if (abs(mag - 9.81f) > 4.9f) motionDetected = true
            }

            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
        }
        sensorManager.registerListener(listener, accelerometer, SensorManager.SENSOR_DELAY_UI)

        // GPS
        val location = withContext(Dispatchers.IO) {
            suspendCoroutine<Location?> { cont ->
                val client = LocationServices.getFusedLocationProviderClient(context)
                try {
                    client.getCurrentLocation(
                        Priority.PRIORITY_HIGH_ACCURACY,
                        CancellationTokenSource().token,
                    ).addOnSuccessListener { cont.resume(it) }
                        .addOnFailureListener { cont.resume(null) }
                } catch (e: SecurityException) {
                    cont.resume(null)
                }
            }
        }

        // Photo
        val tempFile = File.createTempFile("evidence_", ".jpg", context.cacheDir)
        val outputOptions = ImageCapture.OutputFileOptions.Builder(tempFile).build()

        val photoUri = withContext(Dispatchers.IO) {
            suspendCoroutine<String> { cont ->
                imageCapture.takePicture(
                    outputOptions,
                    ContextCompat.getMainExecutor(context),
                    object : ImageCapture.OnImageSavedCallback {
                        override fun onImageSaved(output: ImageCapture.OutputFileResults) {
                            cont.resume(tempFile.absolutePath)
                        }

                        override fun onError(exception: ImageCaptureException) {
                            cont.resumeWithException(exception)
                        }
                    },
                )
            }
        }

        // Wait for motion window
        delay(2000)
        sensorManager.unregisterListener(listener)

        val imageBytes = tempFile.readBytes()
        val timestamp = Instant.now().toString()

        val evidence = EvidenceSigner.signEvidence(
            context = context,
            imageBytes = imageBytes,
            imageUri = photoUri,
            timestamp = timestamp,
            latitude = location?.latitude ?: 0.0,
            longitude = location?.longitude ?: 0.0,
            altitude = location?.altitude,
            accuracy = location?.accuracy?.toDouble() ?: 0.0,
            motionVerified = motionDetected,
            captureMethod = "camera",
        )

        onResult(evidence, imageBytes)
    } catch (e: Exception) {
        e.printStackTrace()
    } finally {
        onCapturing(false)
        onSigning(false)
    }
}

// ---------------------------------------------------------------------------
// Gallery processing logic
// ---------------------------------------------------------------------------

private suspend fun processGalleryUri(
    context: Context,
    uri: Uri,
): Pair<SecureEvidence, ByteArray> {
    // Read image bytes from content URI
    val imageBytes = withContext(Dispatchers.IO) {
        context.contentResolver.openInputStream(uri)?.readBytes()
            ?: throw IllegalStateException("Cannot read gallery image")
    }

    // GPS
    val location = withContext(Dispatchers.IO) {
        suspendCoroutine<Location?> { cont ->
            val client = LocationServices.getFusedLocationProviderClient(context)
            try {
                client.getCurrentLocation(
                    Priority.PRIORITY_HIGH_ACCURACY,
                    CancellationTokenSource().token,
                ).addOnSuccessListener { cont.resume(it) }
                    .addOnFailureListener { cont.resume(null) }
            } catch (e: SecurityException) {
                cont.resume(null)
            }
        }
    }

    // Save to temp file for URI
    val tempFile = withContext(Dispatchers.IO) {
        File.createTempFile("evidence_gallery_", ".jpg", context.cacheDir).also {
            it.writeBytes(imageBytes)
        }
    }

    val timestamp = Instant.now().toString()

    val evidence = EvidenceSigner.signEvidence(
        context = context,
        imageBytes = imageBytes,
        imageUri = tempFile.absolutePath,
        timestamp = timestamp,
        latitude = location?.latitude ?: 0.0,
        longitude = location?.longitude ?: 0.0,
        altitude = location?.altitude,
        accuracy = location?.accuracy?.toDouble() ?: 0.0,
        motionVerified = false,
        captureMethod = "gallery",
    )

    return evidence to imageBytes
}
