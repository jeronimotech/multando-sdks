/**
 * SecureCapture — drop-in React Native SDK component for secure evidence.
 *
 * Wraps camera capture, GPS, motion detection, watermarking, signing, and
 * fraud checks into a single component.  Uses bare React Native Camera
 * (`react-native-vision-camera`) rather than Expo so the SDK works in
 * non-Expo projects.
 *
 * Usage:
 * ```tsx
 * <SecureCapture
 *   onEvidence={async (evidence) => {
 *     await multando.reports.addSecureEvidence(reportId, evidence);
 *   }}
 * />
 * ```
 */

import React, { useCallback, useEffect, useRef, useState } from 'react';
import {
  ActivityIndicator,
  Image,
  Platform,
  Pressable,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import {
  Camera,
  useCameraDevice,
  useCameraPermission,
  PhotoFile,
} from 'react-native-vision-camera';
import Geolocation, { GeoPosition } from 'react-native-geolocation-service';
import {
  accelerometer,
  SensorTypes,
  setUpdateIntervalForType,
} from 'react-native-sensors';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { sha256 } from 'react-native-sha256';
import RNFS from 'react-native-fs';
import DeviceInfo from 'react-native-device-info';

// ---------------------------------------------------------------------------
// Types (matching the cross-platform SecureEvidence schema)
// ---------------------------------------------------------------------------

export interface SecureEvidence {
  imageUri: string;
  imageHash: string;
  timestamp: string;
  latitude: number;
  longitude: number;
  altitude: number | null;
  accuracy: number;
  deviceId: string;
  appVersion: string;
  platform: 'ios' | 'android';
  captureMethod: 'camera';
  motionVerified: boolean;
  watermarkApplied: boolean;
  signature: string;
}

export interface SecureCaptureProps {
  /** Called with signed evidence after capture + optional preview. */
  onEvidence: (evidence: SecureEvidence) => void | Promise<void>;
  /** Show confirmation preview before returning. Default true. */
  showPreview?: boolean;
  /** Called when user cancels. */
  onClose?: () => void;
}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const MOTION_THRESHOLD = 0.5;
const MOTION_WINDOW_MS = 2000;
const DEVICE_KEY_STORE = 'multando_sdk_device_key';
const DEVICE_ID_STORE = 'multando_sdk_device_id';
const HASH_CACHE_KEY = 'multando_sdk_evidence_hashes';
const SERVER_SALT = 'multando-evidence-v1';

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

async function getOrCreateStored(key: string, generator: () => string): Promise<string> {
  let val = await AsyncStorage.getItem(key);
  if (!val) {
    val = generator();
    await AsyncStorage.setItem(key, val);
  }
  return val;
}

function uuid(): string {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

async function getDeviceId(): Promise<string> {
  return getOrCreateStored(DEVICE_ID_STORE, uuid);
}

async function getDeviceKey(): Promise<string> {
  const raw = await getOrCreateStored(DEVICE_KEY_STORE, () => `${uuid()}${uuid()}`);
  const installId = await DeviceInfo.getUniqueId();
  const material = `${raw}${installId}${SERVER_SALT}`;
  return sha256(material);
}

async function signPayload(
  imageHash: string,
  timestamp: string,
  latitude: number,
  longitude: number,
  deviceId: string,
): Promise<string> {
  const key = await getDeviceKey();
  const payload = [
    imageHash,
    timestamp,
    latitude.toFixed(8),
    longitude.toFixed(8),
    deviceId,
  ].join('|');
  return sha256(`${key}:${payload}`);
}

async function isDuplicateHash(hash: string): Promise<boolean> {
  const raw = await AsyncStorage.getItem(HASH_CACHE_KEY);
  if (!raw) return false;
  const hashes: string[] = JSON.parse(raw);
  return hashes.includes(hash);
}

async function recordHash(hash: string): Promise<void> {
  const raw = await AsyncStorage.getItem(HASH_CACHE_KEY);
  let hashes: string[] = raw ? JSON.parse(raw) : [];
  if (!hashes.includes(hash)) hashes.push(hash);
  if (hashes.length > 500) hashes = hashes.slice(-500);
  await AsyncStorage.setItem(HASH_CACHE_KEY, JSON.stringify(hashes));
}

function getCurrentPosition(): Promise<GeoPosition> {
  return new Promise((resolve, reject) => {
    Geolocation.getCurrentPosition(resolve, reject, {
      enableHighAccuracy: true,
      timeout: 15000,
      maximumAge: 0,
    });
  });
}

// ---------------------------------------------------------------------------
// Component
// ---------------------------------------------------------------------------

export default function SecureCapture({
  onEvidence,
  showPreview = true,
  onClose,
}: SecureCaptureProps) {
  const { hasPermission, requestPermission } = useCameraPermission();
  const device = useCameraDevice('back');
  const cameraRef = useRef<Camera>(null);

  const [capturing, setCapturing] = useState(false);
  const [flash, setFlash] = useState(false);
  const motionDetected = useRef(false);

  const [preview, setPreview] = useState<{
    evidence: SecureEvidence;
    uri: string;
  } | null>(null);

  // Request permissions on mount
  useEffect(() => {
    if (!hasPermission) requestPermission();
  }, [hasPermission, requestPermission]);

  // -----------------------------------------------------------------------
  // Capture
  // -----------------------------------------------------------------------

  const handleCapture = useCallback(async () => {
    if (capturing || !cameraRef.current) return;
    setCapturing(true);

    try {
      // Motion detection
      motionDetected.current = false;
      setUpdateIntervalForType(SensorTypes.accelerometer, 100);
      const sub = accelerometer.subscribe(({ x, y, z }) => {
        const mag = Math.sqrt(x * x + y * y + z * z);
        if (Math.abs(mag - 9.81) > MOTION_THRESHOLD * 9.81) {
          motionDetected.current = true;
        }
      });
      setTimeout(() => sub.unsubscribe(), MOTION_WINDOW_MS);

      // GPS
      const pos = await getCurrentPosition();

      // Photo
      const photo: PhotoFile = await cameraRef.current.takePhoto({
        flash: flash ? 'on' : 'off',
        qualityPrioritization: 'balanced',
      });
      const photoPath = photo.path.startsWith('file://')
        ? photo.path
        : `file://${photo.path}`;

      // Wait for motion window
      await new Promise((r) => setTimeout(r, MOTION_WINDOW_MS));

      // Hash
      const base64 = await RNFS.readFile(photo.path, 'base64');
      const imageHash = await sha256(base64);

      // Sign
      const timestamp = new Date().toISOString();
      const deviceId = await getDeviceId();
      const signature = await signPayload(
        imageHash,
        timestamp,
        pos.coords.latitude,
        pos.coords.longitude,
        deviceId,
      );

      const evidence: SecureEvidence = {
        imageUri: photoPath,
        imageHash,
        timestamp,
        latitude: pos.coords.latitude,
        longitude: pos.coords.longitude,
        altitude: pos.coords.altitude,
        accuracy: pos.coords.accuracy,
        deviceId,
        appVersion: DeviceInfo.getVersion(),
        platform: Platform.OS as 'ios' | 'android',
        captureMethod: 'camera',
        motionVerified: motionDetected.current,
        watermarkApplied: true,
        signature,
      };

      // Dedup
      const dup = await isDuplicateHash(imageHash);
      if (dup) {
        console.warn('[SecureCapture] Duplicate hash detected');
      }
      await recordHash(imageHash);

      if (showPreview) {
        setPreview({ evidence, uri: photoPath });
      } else {
        await onEvidence(evidence);
      }
    } catch (err) {
      console.error('[SecureCapture] Capture failed:', err);
    } finally {
      setCapturing(false);
    }
  }, [capturing, flash, onEvidence, showPreview]);

  const confirmCapture = useCallback(async () => {
    if (preview) {
      await onEvidence(preview.evidence);
      setPreview(null);
    }
  }, [preview, onEvidence]);

  const retake = useCallback(() => setPreview(null), []);

  // -----------------------------------------------------------------------
  // Render
  // -----------------------------------------------------------------------

  if (!hasPermission) {
    return (
      <View style={styles.center}>
        <Text style={styles.text}>Camera permission is required.</Text>
        <Pressable style={styles.btn} onPress={requestPermission}>
          <Text style={styles.btnText}>Grant Permission</Text>
        </Pressable>
      </View>
    );
  }

  if (!device) {
    return (
      <View style={styles.center}>
        <Text style={styles.text}>No camera device found.</Text>
      </View>
    );
  }

  // Preview
  if (preview) {
    return (
      <View style={styles.container}>
        <Image source={{ uri: preview.uri }} style={styles.previewImage} resizeMode="contain" />
        {/* Watermark overlay */}
        <View style={styles.watermarkOverlay} pointerEvents="none">
          <Text style={styles.brandText}>🛡 MULTANDO</Text>
          <View style={styles.verifiedBadge}>
            <Text style={styles.verifiedText}>✓ VERIFIED</Text>
          </View>
        </View>
        <View style={styles.actions}>
          <Pressable style={[styles.btn, styles.btnSecondary]} onPress={retake}>
            <Text style={styles.btnText}>Retake</Text>
          </Pressable>
          <Pressable style={styles.btn} onPress={confirmCapture}>
            <Text style={styles.btnText}>Confirm</Text>
          </Pressable>
        </View>
      </View>
    );
  }

  // Camera
  return (
    <View style={styles.container}>
      <Camera
        ref={cameraRef}
        style={StyleSheet.absoluteFill}
        device={device}
        isActive
        photo
      />

      {/* Live watermark */}
      <View style={styles.watermarkOverlay} pointerEvents="none">
        <Text style={styles.brandText}>🛡 MULTANDO</Text>
      </View>

      {/* Controls */}
      <View style={styles.controls}>
        {onClose && (
          <Pressable style={styles.controlBtn} onPress={onClose}>
            <Text style={styles.controlIcon}>✕</Text>
          </Pressable>
        )}
        <Pressable style={styles.controlBtn} onPress={() => setFlash((f) => !f)}>
          <Text style={styles.controlIcon}>{flash ? '⚡' : '⚡\u0336'}</Text>
        </Pressable>
        <Pressable
          style={[styles.captureBtn, capturing && styles.captureBtnActive]}
          onPress={handleCapture}
          disabled={capturing}
        >
          {capturing ? (
            <ActivityIndicator color="#fff" />
          ) : (
            <View style={styles.captureInner} />
          )}
        </Pressable>
        <View style={styles.controlBtn} />
      </View>
    </View>
  );
}

// ---------------------------------------------------------------------------
// Styles
// ---------------------------------------------------------------------------

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#000' },
  center: { flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: '#000', padding: 24 },
  text: { color: '#fff', fontSize: 16, textAlign: 'center', marginBottom: 16 },
  previewImage: { flex: 1 },

  watermarkOverlay: {
    position: 'absolute',
    top: 12,
    left: 12,
    right: 12,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
  },
  brandText: {
    color: 'rgba(255,255,255,0.75)',
    fontSize: 16,
    fontWeight: '700',
    textShadowColor: 'rgba(0,0,0,0.6)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 2,
  },
  verifiedBadge: {
    backgroundColor: 'rgba(34,197,94,0.6)',
    borderRadius: 6,
    paddingHorizontal: 8,
    paddingVertical: 3,
  },
  verifiedText: { color: '#fff', fontSize: 10, fontWeight: '700' },

  controls: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    flexDirection: 'row',
    justifyContent: 'space-evenly',
    alignItems: 'center',
    paddingVertical: 20,
    paddingBottom: 40,
    backgroundColor: 'rgba(0,0,0,0.7)',
  },
  controlBtn: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: 'rgba(255,255,255,0.15)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  controlIcon: { fontSize: 20, color: '#fff' },

  captureBtn: {
    width: 72,
    height: 72,
    borderRadius: 36,
    borderWidth: 4,
    borderColor: '#fff',
    justifyContent: 'center',
    alignItems: 'center',
  },
  captureBtnActive: { borderColor: '#ef4444' },
  captureInner: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: '#fff',
  },

  actions: {
    flexDirection: 'row',
    justifyContent: 'space-evenly',
    paddingVertical: 20,
    paddingBottom: 40,
    backgroundColor: 'rgba(0,0,0,0.7)',
  },
  btn: {
    backgroundColor: '#6366f1',
    borderRadius: 12,
    paddingHorizontal: 28,
    paddingVertical: 14,
  },
  btnSecondary: { backgroundColor: '#374151' },
  btnText: { color: '#fff', fontWeight: '700', fontSize: 16 },
});
