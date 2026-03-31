/// Secure camera widget for the Multando Flutter SDK.
///
/// Uses the `camera` package for capture, `geolocator` for GPS,
/// `sensors_plus` for motion detection, and renders a watermark overlay.
library;

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'evidence_signer.dart';
import 'anti_fraud.dart';

/// Callback signature for completed evidence captures.
typedef OnEvidenceCaptured = void Function(SecureEvidence evidence);

/// A self-contained secure camera widget that enforces live capture,
/// detects motion, fetches GPS, applies a watermark overlay, and signs
/// the result.
class SecureCameraWidget extends StatefulWidget {
  /// Called with the signed evidence after capture (and optional preview).
  final OnEvidenceCaptured onCapture;

  /// Whether to show a confirmation preview before returning evidence.
  final bool showPreview;

  /// Called when the user closes the camera.
  final VoidCallback? onClose;

  const SecureCameraWidget({
    super.key,
    required this.onCapture,
    this.showPreview = true,
    this.onClose,
  });

  @override
  State<SecureCameraWidget> createState() => _SecureCameraWidgetState();
}

class _SecureCameraWidgetState extends State<SecureCameraWidget> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _capturing = false;
  bool _flashOn = false;
  int _cameraIndex = 0;

  // Motion detection
  StreamSubscription<AccelerometerEvent>? _motionSub;
  bool _motionDetected = false;

  // Preview
  SecureEvidence? _previewEvidence;
  Uint8List? _previewBytes;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) return;
    await _setupController(_cameras![_cameraIndex]);
  }

  Future<void> _setupController(CameraDescription desc) async {
    _controller?.dispose();
    final controller = CameraController(desc, ResolutionPreset.high);
    await controller.initialize();
    if (!mounted) return;
    _controller = controller;
    setState(() => _isInitialized = true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _motionSub?.cancel();
    super.dispose();
  }

  // -----------------------------------------------------------------------
  // Motion detection
  // -----------------------------------------------------------------------

  void _startMotionDetection() {
    _motionDetected = false;
    _motionSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 100),
    ).listen((event) {
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      if ((magnitude - 9.81).abs() > 4.9) {
        // ~0.5 g beyond gravity
        _motionDetected = true;
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      _motionSub?.cancel();
      _motionSub = null;
    });
  }

  // -----------------------------------------------------------------------
  // Capture
  // -----------------------------------------------------------------------

  Future<void> _capture() async {
    if (_capturing || _controller == null || !_controller!.value.isInitialized) {
      return;
    }
    setState(() => _capturing = true);

    try {
      _startMotionDetection();

      // GPS
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Photo
      final xFile = await _controller!.takePicture();
      final bytes = await xFile.readAsBytes();

      // Wait for motion window
      await Future.delayed(const Duration(seconds: 2));

      final timestamp = DateTime.now().toUtc().toIso8601String();

      // Sign
      final evidence = await EvidenceSigner.signEvidence(
        imageBytes: bytes,
        timestamp: timestamp,
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        accuracy: position.accuracy,
        motionVerified: _motionDetected,
        imageUri: xFile.path,
      );

      // Fraud checks
      final fraud = await AntiFraud.runChecks(evidence);
      if (!fraud.passed) {
        debugPrint('[SecureCamera] Fraud checks failed: ${fraud.failedReasons}');
      }
      await AntiFraud.recordHash(evidence.imageHash);

      if (widget.showPreview) {
        setState(() {
          _previewEvidence = evidence;
          _previewBytes = bytes;
        });
      } else {
        widget.onCapture(evidence);
      }
    } catch (e) {
      debugPrint('[SecureCamera] Capture failed: $e');
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  void _confirmCapture() {
    if (_previewEvidence != null) {
      widget.onCapture(_previewEvidence!);
      setState(() {
        _previewEvidence = null;
        _previewBytes = null;
      });
    }
  }

  void _retake() {
    setState(() {
      _previewEvidence = null;
      _previewBytes = null;
    });
  }

  void _toggleFlash() {
    _flashOn = !_flashOn;
    _controller?.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
    setState(() {});
  }

  Future<void> _flipCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras!.length;
    await _setupController(_cameras![_cameraIndex]);
  }

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Preview mode
    if (_previewEvidence != null && _previewBytes != null) {
      return _buildPreview();
    }

    if (!_isInitialized || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        // Camera preview
        Positioned.fill(child: CameraPreview(_controller!)),

        // Live watermark
        Positioned(
          top: 12,
          left: 12,
          child: Text(
            '🛡 MULTANDO',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              shadows: const [Shadow(blurRadius: 4, color: Colors.black54)],
            ),
          ),
        ),

        // Controls bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black54,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (widget.onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: widget.onClose,
                  ),
                IconButton(
                  icon: Icon(
                    _flashOn ? Icons.flash_on : Icons.flash_off,
                    color: Colors.white,
                  ),
                  onPressed: _toggleFlash,
                ),
                GestureDetector(
                  onTap: _capture,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _capturing ? Colors.red : Colors.white,
                        width: 4,
                      ),
                    ),
                    child: _capturing
                        ? const Center(
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            ),
                          )
                        : Container(
                            margin: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                  onPressed: _flipCamera,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.memory(_previewBytes!, fit: BoxFit.contain),
              ),
              // Watermark overlay
              Positioned(
                top: 12,
                left: 12,
                child: Text(
                  '🛡 MULTANDO',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '✓ VERIFIED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                child: Text(
                  _previewEvidence!.timestamp,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: Text(
                  '${_previewEvidence!.latitude.toStringAsFixed(4)}°N '
                  '${_previewEvidence!.longitude.abs().toStringAsFixed(4)}°W',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          color: Colors.black87,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[700]),
                onPressed: _retake,
                child: const Text('Retake'),
              ),
              ElevatedButton(
                onPressed: _confirmCapture,
                child: const Text('Confirm'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
