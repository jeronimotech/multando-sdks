import SwiftUI

/// A SwiftUI view that guides the user through a 3-step report creation flow.
///
/// Steps:
/// 1. Pick an infraction from the list.
/// 2. Enter details: plate number, location, and date/time.
/// 3. Review the data and submit.
///
/// ```swift
/// ReportFormView(client: multandoClient) { report in
///     print("Created report: \(report.id)")
/// }
/// ```
@available(iOS 16.0, *)
public struct ReportFormView: View {

    private let client: MultandoClient
    private let onReportCreated: (ReportDetail) -> Void

    @State private var currentStep = 0

    // Step 1
    @State private var infractions: [InfractionResponse] = []
    @State private var isLoadingInfractions = true
    @State private var loadError: String?
    @State private var selectedInfraction: InfractionResponse?

    // Step 2
    @State private var plateNumber = ""
    @State private var locationText = ""
    @State private var occurredAt = Date()

    // Step 3
    @State private var isSubmitting = false
    @State private var submitError: String?

    public init(
        client: MultandoClient,
        onReportCreated: @escaping (ReportDetail) -> Void
    ) {
        self.client = client
        self.onReportCreated = onReportCreated
    }

    public var body: some View {
        VStack(spacing: 0) {
            stepIndicator
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

            Divider()

            ScrollView {
                switch currentStep {
                case 0:
                    step1InfractionPicker
                case 1:
                    step2Details
                case 2:
                    step3Review
                default:
                    EmptyView()
                }
            }

            Divider()

            navigationButtons
                .padding(16)
        }
        .task {
            await loadInfractions()
        }
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 0) {
            stepDot(index: 0, label: "Infraction")
            stepLine(completed: currentStep > 0)
            stepDot(index: 1, label: "Details")
            stepLine(completed: currentStep > 1)
            stepDot(index: 2, label: "Submit")
        }
    }

    private func stepDot(index: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Circle()
                .fill(index <= currentStep ? MultandoTheme.primary : Color.gray.opacity(0.3))
                .frame(width: index == currentStep ? 14 : 10, height: index == currentStep ? 14 : 10)
            Text(label)
                .font(.system(size: 10, weight: index <= currentStep ? .semibold : .regular))
                .foregroundColor(index <= currentStep ? .primary : .gray)
        }
    }

    private func stepLine(completed: Bool) -> some View {
        Rectangle()
            .fill(completed ? MultandoTheme.primary : Color.gray.opacity(0.3))
            .frame(height: 2)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 4)
            .padding(.bottom, 14)
    }

    // MARK: - Step 1: Infraction Picker

    private var step1InfractionPicker: some View {
        VStack(spacing: 12) {
            if isLoadingInfractions {
                ProgressView("Loading infractions...")
                    .padding(.top, 40)
            } else if let error = loadError {
                VStack(spacing: 8) {
                    Text("Failed to load infractions")
                        .foregroundColor(MultandoTheme.danger)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        Task { await loadInfractions() }
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top, 40)
            } else {
                ForEach(infractions, id: \.id) { infraction in
                    let isSelected = selectedInfraction?.id == infraction.id
                    Button(action: { selectedInfraction = infraction }) {
                        HStack {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(isSelected ? MultandoTheme.primary : .gray)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(infraction.name)
                                    .font(.multandoTitle)
                                    .foregroundColor(.primary)
                                Text(infraction.description)
                                    .font(.multandoCaption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            Spacer()
                            severityPill(infraction.severity)
                        }
                        .padding(12)
                        .background(isSelected ? MultandoTheme.primary.opacity(0.06) : Color.clear)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isSelected ? MultandoTheme.primary : Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
    }

    private func severityPill(_ severity: InfractionSeverity) -> some View {
        let (label, color): (String, Color) = {
            switch severity {
            case .low:      return ("Low", MultandoTheme.success)
            case .medium:   return ("Medium", MultandoTheme.warning)
            case .high:     return ("High", MultandoTheme.danger)
            case .critical: return ("Critical", Color.purple)
            }
        }()

        return Text(label)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(Capsule())
    }

    // MARK: - Step 2: Details

    private var step2Details: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Vehicle Plate")
                    .font(.multandoCaption)
                    .foregroundColor(.secondary)
                TextField("e.g. ABC-1234", text: $plateNumber)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Location")
                    .font(.multandoCaption)
                    .foregroundColor(.secondary)
                TextField("Street address or description", text: $locationText)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Date & Time")
                    .font(.multandoCaption)
                    .foregroundColor(.secondary)
                DatePicker(
                    "",
                    selection: $occurredAt,
                    in: ...Date(),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
            }
        }
        .padding(16)
    }

    // MARK: - Step 3: Review

    private var step3Review: some View {
        VStack(alignment: .leading, spacing: 14) {
            reviewRow(label: "Infraction", value: selectedInfraction?.name ?? "-")
            reviewRow(label: "Severity", value: selectedInfraction?.severity.rawValue.capitalized ?? "-")
            reviewRow(label: "Plate", value: plateNumber.isEmpty ? "-" : plateNumber)
            reviewRow(label: "Location", value: locationText.isEmpty ? "-" : locationText)
            reviewRow(label: "Date", value: formattedDate)

            if let error = submitError {
                Text(error)
                    .font(.multandoCaption)
                    .foregroundColor(MultandoTheme.danger)
                    .padding(.top, 4)
            }
        }
        .padding(16)
    }

    private func reviewRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.multandoCaption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.multandoBody)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: occurredAt)
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if currentStep > 0 {
                Button("Back") {
                    withAnimation { currentStep -= 1 }
                }
                .buttonStyle(.bordered)
                .disabled(isSubmitting)
            }

            Spacer()

            if currentStep < 2 {
                Button("Next") {
                    withAnimation { handleNext() }
                }
                .buttonStyle(.borderedProminent)
                .tint(MultandoTheme.primary)
                .disabled(!canAdvance)
            } else {
                Button(isSubmitting ? "Submitting..." : "Submit Report") {
                    Task { await submitReport() }
                }
                .buttonStyle(.borderedProminent)
                .tint(MultandoTheme.primary)
                .disabled(isSubmitting)
            }
        }
    }

    private var canAdvance: Bool {
        switch currentStep {
        case 0: return selectedInfraction != nil
        case 1: return !plateNumber.trimmingCharacters(in: .whitespaces).isEmpty
                    && !locationText.trimmingCharacters(in: .whitespaces).isEmpty
        default: return true
        }
    }

    // MARK: - Actions

    private func handleNext() {
        guard canAdvance else { return }
        currentStep += 1
    }

    private func loadInfractions() async {
        isLoadingInfractions = true
        loadError = nil
        do {
            infractions = try await client.infractions.list()
            isLoadingInfractions = false
        } catch {
            loadError = error.localizedDescription
            isLoadingInfractions = false
        }
    }

    private func submitReport() async {
        isSubmitting = true
        submitError = nil

        let isoFormatter = ISO8601DateFormatter()
        let report = ReportCreate(
            infractionId: selectedInfraction!.id,
            vehicleTypeId: "",
            licensePlate: plateNumber.trimmingCharacters(in: .whitespaces),
            description: "Report via SDK",
            location: LocationData(
                latitude: 0,
                longitude: 0,
                address: locationText.trimmingCharacters(in: .whitespaces)
            ),
            occurredAt: isoFormatter.string(from: occurredAt),
            source: .sdk
        )

        do {
            let detail = try await client.reports.create(report)
            await MainActor.run {
                onReportCreated(detail)
            }
        } catch {
            await MainActor.run {
                submitError = error.localizedDescription
                isSubmitting = false
            }
        }
    }
}
