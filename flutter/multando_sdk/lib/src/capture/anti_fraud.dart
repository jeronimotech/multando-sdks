/// Client-side anti-fraud checks for the Multando Flutter SDK.
///
/// Mirrors the checks performed on the React Native mobile app and the
/// backend.  Results are advisory on the client; the server makes the
/// authoritative pass/fail decision.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'evidence_signer.dart';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

class FraudCheckResult {
  final bool passed;
  final Map<String, bool> checks;
  final List<String> failedReasons;

  const FraudCheckResult({
    required this.passed,
    required this.checks,
    required this.failedReasons,
  });
}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const _freshnessWindowMs = 5 * 60 * 1000; // 5 minutes
const _hashCacheKey = 'multando_evidence_hashes';
const _maxCachedHashes = 500;

// ---------------------------------------------------------------------------
// Anti-fraud service
// ---------------------------------------------------------------------------

class AntiFraud {
  // -----------------------------------------------------------------------
  // Hash dedup cache
  // -----------------------------------------------------------------------

  static Future<bool> isDuplicateHash(String hash) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_hashCacheKey);
    if (raw == null) return false;
    final List<dynamic> hashes = jsonDecode(raw);
    return hashes.contains(hash);
  }

  static Future<void> recordHash(String hash) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_hashCacheKey);
    List<String> hashes = raw != null
        ? (jsonDecode(raw) as List<dynamic>).cast<String>()
        : <String>[];
    if (!hashes.contains(hash)) {
      hashes.add(hash);
    }
    if (hashes.length > _maxCachedHashes) {
      hashes = hashes.sublist(hashes.length - _maxCachedHashes);
    }
    await prefs.setString(_hashCacheKey, jsonEncode(hashes));
  }

  // -----------------------------------------------------------------------
  // Checks
  // -----------------------------------------------------------------------

  static Future<FraudCheckResult> runChecks(
    SecureEvidence evidence, {
    int? gpsFetchedAtMs,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final evidenceTime = DateTime.parse(evidence.timestamp).millisecondsSinceEpoch;
    final failed = <String>[];

    // 1. Capture method (camera or gallery are both acceptable)
    final captureMethodValid =
        evidence.captureMethod == 'camera' || evidence.captureMethod == 'gallery';
    if (!captureMethodValid) failed.add('Invalid capture method');

    // 2. Timestamp freshness
    final timestampFresh = (now - evidenceTime).abs() <= _freshnessWindowMs;
    if (!timestampFresh) failed.add('Timestamp stale (>5 min)');

    // 3. GPS freshness
    final gpsFresh = gpsFetchedAtMs != null
        ? (now - gpsFetchedAtMs).abs() <= 30000
        : true;
    if (!gpsFresh) failed.add('GPS fix stale (>30 s)');

    // 4. Motion
    final motionDetected = evidence.motionVerified;
    if (!motionDetected) failed.add('No motion detected');

    // 5. Duplicate hash
    final isDup = await isDuplicateHash(evidence.imageHash);
    final notDuplicate = !isDup;
    if (!notDuplicate) failed.add('Duplicate image hash');

    // 6. EXIF consistency
    final exifConsistent = evidence.latitude >= -90 &&
        evidence.latitude <= 90 &&
        evidence.longitude >= -180 &&
        evidence.longitude <= 180 &&
        evidence.accuracy > 0 &&
        evidence.accuracy < 500;
    if (!exifConsistent) failed.add('EXIF / GPS metadata inconsistent');

    final checks = {
      'captureMethodValid': captureMethodValid,
      'timestampFresh': timestampFresh,
      'gpsFresh': gpsFresh,
      'motionDetected': motionDetected,
      'notDuplicate': notDuplicate,
      'exifConsistent': exifConsistent,
    };

    return FraudCheckResult(
      passed: checks.values.every((v) => v),
      checks: checks,
      failedReasons: failed,
    );
  }
}
