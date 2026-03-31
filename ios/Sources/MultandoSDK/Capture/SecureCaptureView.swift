//
//  SecureCaptureView.swift
//  MultandoSDK
//
//  SwiftUI view that provides secure evidence capture using AVFoundation,
//  CoreLocation, and CoreMotion.
//

import AVFoundation
import CoreLocation
import CoreMotion
import SwiftUI

// MARK: - SecureCaptureView

/// A self-contained SwiftUI view for secure evidence capture.
///
/// ```swift
/// SecureCaptureView { evidence in
///     try await multando.reports.addSecureEvidence(reportId, evidence)
/// }
/// ```
public struct SecureCaptureView: View {
    public let onEvidence: (SecureEvidence) -> Void
    public var onClose: (() -> Void)?

    @StateObject private var vm = SecureCaptureViewModel()

    public init(
        onEvidence: @escaping (SecureEvidence) -> Void,
        onClose: (() -> Void)? = nil
    ) {
        self.onEvidence = onEvidence
        self.onClose = onClose
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let preview = vm.previewEvidence, let image = vm.previewImage {
                previewView(evidence: preview, image: image)
            } else {
                cameraView
            }
        }
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
    }

    // MARK: Camera View

    private var cameraView: some View {
        ZStack {
            CameraPreviewRepresentable(session: vm.session)
                .ignoresSafeArea()

            // Live watermark
            VStack {
                HStack {
                    Text("🛡 MULTANDO")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white.opacity(0.75))
                        .shadow(radius: 2)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                Spacer()
            }

            // Controls
            VStack {
                Spacer()
                HStack(spacing: 40) {
                    if onClose != nil {
                        Button(action: { onClose?() }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 48, height: 48)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                        }
                    }

                    Button(action: { vm.toggleFlash() }) {
                        Image(systemName: vm.flashOn ? "bolt.fill" : "bolt.slash")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }

                    Button(action: { Task { await vm.capture() } }) {
                        ZStack {
                            Circle()
                                .stroke(vm.capturing ? Color.red : Color.white, lineWidth: 4)
                                .frame(width: 72, height: 72)
                            if vm.capturing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 56, height: 56)
                            }
                        }
                    }
                    .disabled(vm.capturing)

                    Button(action: { vm.flipCamera() }) {
                        Image(systemName: "camera.rotate")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 40)
                .padding(.horizontal, 16)
                .background(Color.black.opacity(0.7))
            }
        }
    }

    // MARK: Preview View

    private func previewView(evidence: SecureEvidence, image: UIImage) -> some View {
        VStack(spacing: 0) {
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)

                VStack {
                    HStack {
                        Text("🛡 MULTANDO")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white.opacity(0.75))
                        Spacer()
                        Text("✓ VERIFIED")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.green.opacity(0.6))
                            .cornerRadius(6)
                    }
                    .padding(12)
                    Spacer()
                    HStack {
                        Text(evidence.timestamp)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                        Spacer()
                        Text(String(
                            format: "%.4f°N %.4f°W",
                            evidence.latitude,
                            abs(evidence.longitude)
                        ))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                    }
                    .padding(12)
                }
            }

            HStack(spacing: 24) {
                Button("Retake") { vm.clearPreview() }
                    .buttonStyle(.bordered)
                    .tint(.gray)

                Button("Confirm") {
                    if let ev = vm.previewEvidence {
                        onEvidence(ev)
                        vm.clearPreview()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
            }
            .padding(.vertical, 20)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.85))
        }
    }
}

// MARK: - ViewModel

@MainActor
final class SecureCaptureViewModel: ObservableObject {
    @Published var capturing = false
    @Published var flashOn = false
    @Published var previewEvidence: SecureEvidence?
    @Published var previewImage: UIImage?

    let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var currentInput: AVCaptureDeviceInput?
    private var usingFront = false

    private let locationManager = CLLocationManager()
    private let motionManager = CMMotionManager()
    private var motionDetected = false

    private var photoContinuation: CheckedContinuation<(Data, String), Error>?

    func start() {
        locationManager.requestWhenInUseAuthorization()
        setupCamera()
    }

    func stop() {
        session.stopRunning()
        motionManager.stopAccelerometerUpdates()
    }

    // MARK: Camera Setup

    private func setupCamera() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        let position: AVCaptureDevice.Position = usingFront ? .front : .back
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }

        if let existing = currentInput {
            session.removeInput(existing)
        }
        if session.canAddInput(input) {
            session.addInput(input)
            currentInput = input
        }

        if session.outputs.isEmpty, session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }

        session.commitConfiguration()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    func flipCamera() {
        usingFront.toggle()
        setupCamera()
    }

    func toggleFlash() {
        flashOn.toggle()
    }

    // MARK: Motion Detection

    private func startMotionDetection() {
        motionDetected = false
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let data = data else { return }
            let mag = sqrt(data.acceleration.x * data.acceleration.x +
                           data.acceleration.y * data.acceleration.y +
                           data.acceleration.z * data.acceleration.z)
            if abs(mag - 1.0) > 0.5 {
                self?.motionDetected = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.motionManager.stopAccelerometerUpdates()
        }
    }

    // MARK: Capture

    func capture() async {
        guard !capturing else { return }
        capturing = true
        defer { capturing = false }

        startMotionDetection()

        // GPS
        let location = await withCheckedContinuation { (cont: CheckedContinuation<CLLocation?, Never>) in
            let delegate = SingleLocationDelegate { loc in
                cont.resume(returning: loc)
            }
            locationManager.delegate = delegate
            locationManager.requestLocation()
            // Keep delegate alive
            objc_setAssociatedObject(locationManager, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
        }

        let lat = location?.coordinate.latitude ?? 0
        let lon = location?.coordinate.longitude ?? 0
        let alt = location?.altitude
        let acc = location?.horizontalAccuracy ?? 0

        // Photo
        let photoDelegate = PhotoCaptureDelegate()
        let settings = AVCapturePhotoSettings()
        if flashOn, let device = currentInput?.device, device.hasFlash {
            settings.flashMode = .on
        }

        let (imageData, tempPath) = try! await withCheckedThrowingContinuation {
            (cont: CheckedContinuation<(Data, String), Error>) in
            photoDelegate.continuation = cont
            photoOutput.capturePhoto(with: settings, delegate: photoDelegate)
        }

        // Wait for motion window
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        let timestamp = ISO8601DateFormatter().string(from: Date())

        let evidence = EvidenceSigner.signEvidence(
            imageData: imageData,
            imageUri: tempPath,
            timestamp: timestamp,
            latitude: lat,
            longitude: lon,
            altitude: alt,
            accuracy: acc,
            motionVerified: motionDetected
        )

        previewEvidence = evidence
        previewImage = UIImage(data: imageData)
    }

    func clearPreview() {
        previewEvidence = nil
        previewImage = nil
    }
}

// MARK: - Photo Capture Delegate

private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    var continuation: CheckedContinuation<(Data, String), Error>?

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error = error {
            continuation?.resume(throwing: error)
            return
        }
        guard let data = photo.fileDataRepresentation() else {
            continuation?.resume(throwing: NSError(domain: "MultandoSDK", code: -1,
                                                    userInfo: [NSLocalizedDescriptionKey: "No image data"]))
            return
        }
        let tempPath = NSTemporaryDirectory() + UUID().uuidString + ".jpg"
        try? data.write(to: URL(fileURLWithPath: tempPath))
        continuation?.resume(returning: (data, tempPath))
    }
}

// MARK: - Single Location Delegate

private final class SingleLocationDelegate: NSObject, CLLocationManagerDelegate {
    let handler: (CLLocation?) -> Void

    init(handler: @escaping (CLLocation?) -> Void) {
        self.handler = handler
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        handler(locations.last)
        manager.delegate = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        handler(nil)
        manager.delegate = nil
    }
}

// MARK: - Camera Preview UIViewRepresentable

struct CameraPreviewRepresentable: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            layer.frame = uiView.bounds
        }
    }
}
