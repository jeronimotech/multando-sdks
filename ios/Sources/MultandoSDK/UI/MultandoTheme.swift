import SwiftUI

/// Brand colors and typography for the Multando design system.
public enum MultandoTheme {

    // MARK: - Brand Colors

    /// Primary brand blue (#3B5EEF).
    public static let primary = Color(red: 0x3B / 255.0, green: 0x5E / 255.0, blue: 0xEF / 255.0)

    /// Success green (#10B981).
    public static let success = Color(red: 0x10 / 255.0, green: 0xB9 / 255.0, blue: 0x81 / 255.0)

    /// Danger red (#EF4444).
    public static let danger = Color(red: 0xEF / 255.0, green: 0x44 / 255.0, blue: 0x44 / 255.0)

    /// Warning amber (#F59E0B).
    public static let warning = Color(red: 0xF5 / 255.0, green: 0x9E / 255.0, blue: 0x0B / 255.0)

    /// Neutral gray for secondary text.
    public static let textSecondary = Color(red: 0x6B / 255.0, green: 0x72 / 255.0, blue: 0x80 / 255.0)

    /// Light surface background.
    public static let surface = Color(red: 0xF9 / 255.0, green: 0xFA / 255.0, blue: 0xFB / 255.0)

    // MARK: - Status Colors

    /// Returns the appropriate color for a given report status.
    public static func statusColor(for status: ReportStatus) -> Color {
        switch status {
        case .pending:
            return warning
        case .underReview:
            return warning
        case .verified:
            return success
        case .rejected:
            return danger
        case .appealed:
            return warning
        case .resolved:
            return success
        }
    }

    /// Human-readable label for a report status.
    public static func statusLabel(for status: ReportStatus) -> String {
        switch status {
        case .pending:      return "Pending"
        case .underReview:  return "Under Review"
        case .verified:     return "Verified"
        case .rejected:     return "Rejected"
        case .appealed:     return "Appealed"
        case .resolved:     return "Resolved"
        }
    }
}

// MARK: - SwiftUI Color Extension

public extension Color {
    /// Multando primary brand blue.
    static var multandoPrimary: Color { MultandoTheme.primary }
    /// Multando success green.
    static var multandoSuccess: Color { MultandoTheme.success }
    /// Multando danger red.
    static var multandoDanger: Color { MultandoTheme.danger }
    /// Multando warning amber.
    static var multandoWarning: Color { MultandoTheme.warning }
}

// MARK: - SwiftUI Font Extension

public extension Font {
    /// Heading font used in Multando UI components.
    static var multandoHeading: Font { .system(size: 20, weight: .bold, design: .default) }
    /// Title font used in Multando cards.
    static var multandoTitle: Font { .system(size: 16, weight: .semibold, design: .default) }
    /// Body font used in Multando UI components.
    static var multandoBody: Font { .system(size: 14, weight: .regular, design: .default) }
    /// Caption font used in Multando UI components.
    static var multandoCaption: Font { .system(size: 12, weight: .medium, design: .default) }
}
