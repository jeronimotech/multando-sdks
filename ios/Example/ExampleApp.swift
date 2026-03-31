import SwiftUI
import MultandoSDK

@main
struct MultandoExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var isAuthenticated = false
    @State private var client: MultandoClient?

    var body: some View {
        NavigationStack {
            if isAuthenticated, let client {
                ReportScreen(client: client)
            } else {
                LoginScreen(
                    onLoggedIn: { authenticatedClient in
                        self.client = authenticatedClient
                        self.isAuthenticated = true
                    }
                )
            }
        }
    }
}

// MARK: - Login Screen

struct LoginScreen: View {
    let onLoggedIn: (MultandoClient) -> Void

    @State private var email = "demo@multando.io"
    @State private var password = "password123"
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Logo
            Image(systemName: "shield.checkered")
                .font(.system(size: 56))
                .foregroundColor(MultandoTheme.primary)

            Text("Multando")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(MultandoTheme.primary)

            Text("Report traffic infractions")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Form
            VStack(spacing: 14) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.horizontal, 32)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(MultandoTheme.danger)
                    .padding(.horizontal, 32)
            }

            Button(action: login) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity, minHeight: 44)
                } else {
                    Text("Sign In")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(MultandoTheme.primary)
            .padding(.horizontal, 32)
            .disabled(isLoading)

            Spacer()
            Spacer()
        }
    }

    private func login() {
        isLoading = true
        errorMessage = nil

        let config = MultandoConfig(
            baseURL: "https://api.multando.io",
            apiKey: "example-api-key"
        )
        let client = MultandoSDK.initialize(config: config)

        Task {
            do {
                try await client.auth.login(
                    email: email,
                    password: password
                )
                await MainActor.run {
                    onLoggedIn(client)
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Report Screen

struct ReportScreen: View {
    let client: MultandoClient

    @State private var createdReportId: String?

    var body: some View {
        VStack {
            if let reportId = createdReportId {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 56))
                        .foregroundColor(MultandoTheme.success)

                    Text("Report Created")
                        .font(.title2.bold())

                    Text("ID: \(reportId)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button("Create Another") {
                        createdReportId = nil
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else {
                if #available(iOS 16.0, *) {
                    ReportFormView(client: client) { detail in
                        createdReportId = detail.id
                    }
                } else {
                    Text("Requires iOS 16+")
                }
            }
        }
        .navigationTitle("Create Report")
        .navigationBarTitleDisplayMode(.inline)
    }
}
