import SwiftUI

/// A SwiftUI card view that displays a summary of a report.
///
/// ```swift
/// ReportCardView(report: summary) {
///     // handle tap
/// }
/// ```
public struct ReportCardView: View {

    public let report: ReportSummary
    public var onTap: (() -> Void)?

    public init(report: ReportSummary, onTap: (() -> Void)? = nil) {
        self.report = report
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 10) {
                // Row 1: short ID + status badge
                HStack {
                    Text("#\(shortId)")
                        .font(.multandoCaption)
                        .foregroundColor(MultandoTheme.textSecondary)

                    Spacer()

                    StatusBadge(status: report.status)
                }

                // Row 2: description
                Text(report.description)
                    .font(.multandoTitle)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                // Row 3: location + date
                HStack {
                    if let address = report.location.address {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                            .foregroundColor(MultandoTheme.textSecondary)
                        Text(address)
                            .font(.multandoCaption)
                            .foregroundColor(MultandoTheme.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(MultandoTheme.textSecondary)
                    Text(report.createdAt)
                        .font(.multandoCaption)
                        .foregroundColor(MultandoTheme.textSecondary)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var shortId: String {
        let id = report.id
        if id.count > 8 {
            return String(id.prefix(8)).uppercased()
        }
        return id.uppercased()
    }
}

/// Pill-shaped badge showing a report's status.
public struct StatusBadge: View {

    public let status: ReportStatus

    public init(status: ReportStatus) {
        self.status = status
    }

    public var body: some View {
        Text(MultandoTheme.statusLabel(for: status))
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(MultandoTheme.statusColor(for: status).opacity(0.15))
            .foregroundColor(MultandoTheme.statusColor(for: status))
            .clipShape(Capsule())
    }
}
