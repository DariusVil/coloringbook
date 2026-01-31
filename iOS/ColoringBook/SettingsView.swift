import SwiftUI

/// Settings view for configuring server URL
struct SettingsView: View {
    @Bindable var viewModel: ImageGalleryViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var serverURLText: String = ""
    @State private var isCheckingConnection = false
    @State private var connectionStatus: ConnectionStatus = .unknown

    private let imageService = ImageService()

    enum ConnectionStatus {
        case unknown
        case connected
        case failed
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Server URL", text: $serverURLText)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    HStack {
                        Button("Test Connection") {
                            testConnection()
                        }
                        .disabled(isCheckingConnection || serverURLText.isEmpty)

                        Spacer()

                        if isCheckingConnection {
                            ProgressView()
                        } else {
                            connectionStatusView
                        }
                    }
                } header: {
                    Text("Server Configuration")
                } footer: {
                    Text("Enter the URL of your coloring book server (e.g., http://192.168.1.100:8000)")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quick Start")
                            .font(.headline)

                        Text("1. Start the server on your computer")
                        Text("2. Find your computer's IP address")
                        Text("3. Enter http://<ip>:8000 above")
                        Text("4. Make sure both devices are on the same WiFi")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSettings()
                    }
                    .disabled(serverURLText.isEmpty)
                }
            }
            .onAppear {
                serverURLText = viewModel.serverURL.absoluteString
            }
        }
    }

    @ViewBuilder
    private var connectionStatusView: some View {
        switch connectionStatus {
        case .unknown:
            EmptyView()
        case .connected:
            Label("Connected", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed:
            Label("Failed", systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
        }
    }

    private func testConnection() {
        guard let url = URL(string: serverURLText) else {
            connectionStatus = .failed
            return
        }

        isCheckingConnection = true
        connectionStatus = .unknown

        Task {
            let isConnected = (try? await imageService.healthCheck(baseURL: url)) ?? false
            connectionStatus = isConnected ? .connected : .failed
            isCheckingConnection = false
        }
    }

    private func saveSettings() {
        guard let url = URL(string: serverURLText) else { return }
        viewModel.serverURL = url
        dismiss()

        Task {
            await viewModel.loadImages()
        }
    }
}

#Preview {
    SettingsView(viewModel: ImageGalleryViewModel())
}
