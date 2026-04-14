import SwiftUI

/// Info button that opens a sheet explaining Multando's responsible-reporting
/// principles. Pair it with every report-submission surface so users always
/// have one tap access to the rules of the platform.
///
/// ```swift
/// MultandoInfoButton(primaryColor: .orange)
/// ```
@available(iOS 16.0, macOS 13.0, *)
public struct MultandoInfoButton: View {
    @State private var showSheet = false
    let primaryColor: Color

    public init(primaryColor: Color = .orange) {
        self.primaryColor = primaryColor
    }

    public var body: some View {
        Button {
            showSheet = true
        } label: {
            Image(systemName: "info.circle")
                .foregroundColor(primaryColor)
        }
        .accessibilityLabel(String(localized: "info_button_tooltip", bundle: .module))
        .sheet(isPresented: $showSheet) {
            PrinciplesSheet(primaryColor: primaryColor)
        }
    }
}

/// Sheet content describing the responsible-reporting principles. Exposed at
/// module scope so callers can embed it outside a button (e.g. onboarding).
@available(iOS 16.0, macOS 13.0, *)
public struct PrinciplesSheet: View {
    @Environment(\.dismiss) private var dismiss
    let primaryColor: Color

    private static let principlesURL = URL(string: "https://multando.com/principles")!

    public init(primaryColor: Color = .orange) {
        self.primaryColor = primaryColor
    }

    private var bullets: [String] {
        (1...5).map { String(localized: "responsible_reporting_bullet_\($0)", bundle: .module) }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(String(localized: "responsible_reporting_title", bundle: .module))
                        .font(.title2.bold())
                        .padding(.bottom, 4)

                    ForEach(Array(bullets.enumerated()), id: \.offset) { _, text in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(primaryColor)
                                .padding(.top, 2)
                            Text(text)
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Link(
                        String(localized: "learn_more", bundle: .module),
                        destination: Self.principlesURL
                    )
                    .foregroundColor(primaryColor)
                    .padding(.top, 8)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#if DEBUG
@available(iOS 16.0, macOS 13.0, *)
struct MultandoInfoButton_Previews: PreviewProvider {
    static var previews: some View {
        MultandoInfoButton(primaryColor: .orange)
    }
}
#endif
