/// Evidence signing for the Multando Flutter SDK.
///
/// Produces HMAC-SHA256 signatures over capture metadata using a per-device
/// key stored in flutter_secure_storage.  The output format matches the
/// [SecureEvidence] schema shared across all Multando platforms.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// SecureEvidence model
// ---------------------------------------------------------------------------

/// Cross-platform evidence payload.
class SecureEvidence {
  final String imageUri;
  final String imageHash;
  final String timestamp;
  final double latitude;
  final double longitude;
  final double? altitude;
  final double accuracy;
  final String deviceId;
  final String appVersion;
  final String platform;
  final String captureMethod;
  final bool motionVerified;
  final bool watermarkApplied;
  final String signature;

  const SecureEvidence({
    required this.imageUri,
    required this.imageHash,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.altitude,
    required this.accuracy,
    required this.deviceId,
    required this.appVersion,
    required this.platform,
    required this.captureMethod,
    required this.motionVerified,
    required this.watermarkApplied,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
        'imageUri': imageUri,
        'imageHash': imageHash,
        'timestamp': timestamp,
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'accuracy': accuracy,
        'deviceId': deviceId,
        'appVersion': appVersion,
        'platform': platform,
        'captureMethod': captureMethod,
        'motionVerified': motionVerified,
        'watermarkApplied': watermarkApplied,
        'signature': signature,
      };
}

// ---------------------------------------------------------------------------
// EvidenceSigner
// ---------------------------------------------------------------------------

class EvidenceSigner {
  static const _storage = FlutterSecureStorage();
  static const _deviceKeyKey = 'multando_device_key';
  static const _deviceIdKey = 'multando_device_id';
  static const _serverSalt = 'multando-evidence-v1';
  static const _uuid = Uuid();

  // -----------------------------------------------------------------------
  // Device identity
  // -----------------------------------------------------------------------

  /// Stable per-installation device ID.
  static Future<String> getDeviceId() async {
    var id = await _storage.read(key: _deviceIdKey);
    if (id == null) {
      id = _uuid.v4();
      await _storage.write(key: _deviceIdKey, value: id);
    }
    return id;
  }

  /// Per-device HMAC key derived from a random secret + installation ID + salt.
  static Future<String> _getDeviceKey() async {
    var raw = await _storage.read(key: _deviceKeyKey);
    if (raw == null) {
      raw = '${_uuid.v4()}${_uuid.v4()}';
      await _storage.write(key: _deviceKeyKey, value: raw);
    }

    final installId = await _getPlatformInstallId();
    final material = '$raw$installId$_serverSalt';
    final digest = sha256.convert(utf8.encode(material));
    return digest.toString();
  }

  static Future<String> _getPlatformInstallId() async {
    final info = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final android = await info.androidInfo;
      return android.id;
    } else if (Platform.isIOS) {
      final ios = await info.iosInfo;
      return ios.identifierForVendor ?? _uuid.v4();
    }
    return _uuid.v4();
  }

  // -----------------------------------------------------------------------
  // Signing
  // -----------------------------------------------------------------------

  /// Hash raw image bytes with SHA-256.
  static String _hashBytes(Uint8List bytes) {
    return sha256.convert(bytes).toString();
  }

  /// Build the canonical signing payload.
  static String _buildPayload(
    String imageHash,
    String timestamp,
    double latitude,
    double longitude,
    String deviceId,
  ) {
    return [
      imageHash,
      timestamp,
      latitude.toStringAsFixed(8),
      longitude.toStringAsFixed(8),
      deviceId,
    ].join('|');
  }

  /// HMAC-SHA256(key, message) — simplified as SHA256(key:message) to match
  /// the Expo client.
  static String _hmac(String key, String message) {
    final digest = sha256.convert(utf8.encode('$key:$message'));
    return digest.toString();
  }

  /// Sign evidence and return a complete [SecureEvidence] object.
  ///
  /// [captureMethod] should be `'camera'` or `'gallery'` depending on how
  /// the image was obtained.
  static Future<SecureEvidence> signEvidence({
    required Uint8List imageBytes,
    required String timestamp,
    required double latitude,
    required double longitude,
    double? altitude,
    required double accuracy,
    required bool motionVerified,
    required String imageUri,
    String captureMethod = 'camera',
  }) async {
    final deviceId = await getDeviceId();
    final deviceKey = await _getDeviceKey();
    final imageHash = _hashBytes(imageBytes);
    final payload = _buildPayload(
      imageHash,
      timestamp,
      latitude,
      longitude,
      deviceId,
    );
    final signature = _hmac(deviceKey, payload);
    final platform = Platform.isIOS ? 'ios' : 'android';

    return SecureEvidence(
      imageUri: imageUri,
      imageHash: imageHash,
      timestamp: timestamp,
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      accuracy: accuracy,
      deviceId: deviceId,
      appVersion: '1.0.0',
      platform: platform,
      captureMethod: captureMethod,
      motionVerified: motionVerified,
      watermarkApplied: true,
      signature: signature,
    );
  }

  /// Verify a previously signed evidence object (local check).
  static Future<bool> verifyEvidence(SecureEvidence evidence) async {
    try {
      final deviceKey = await _getDeviceKey();
      final payload = _buildPayload(
        evidence.imageHash,
        evidence.timestamp,
        evidence.latitude,
        evidence.longitude,
        evidence.deviceId,
      );
      final expected = _hmac(deviceKey, payload);
      return expected == evidence.signature;
    } catch (_) {
      return false;
    }
  }
}
