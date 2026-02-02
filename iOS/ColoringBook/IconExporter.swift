import SwiftUI
import UIKit

/// Utility view for exporting app icon at required sizes
/// Run this in Preview, then use Xcode's preview capture or screenshot
struct IconExporter: View {
    var body: some View {
        VStack(spacing: 40) {
            Text("App Icon Export")
                .font(.title2.bold())

            Text("Screenshot this icon at 1024x1024")
                .font(.caption)
                .foregroundStyle(.secondary)

            // 1024x1024 icon for App Store
            AppIconView(size: 1024)
                .frame(width: 1024, height: 1024)
        }
        .padding()
    }
}

/// Use ImageRenderer to export icon programmatically
@MainActor
func exportAppIcon() -> UIImage? {
    let iconView = AppIconView(size: 1024)
    let renderer = ImageRenderer(content: iconView)
    renderer.scale = 1.0
    return renderer.uiImage
}

/// View that exports and saves the icon to photo library
struct IconExportButton: View {
    @State private var showingSaved = false
    @State private var showingError = false

    var body: some View {
        VStack(spacing: 20) {
            AppIconView(size: 200)

            Button {
                if let image = exportAppIcon() {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    showingSaved = true
                } else {
                    showingError = true
                }
            } label: {
                Label("Export 1024x1024 Icon", systemImage: "square.and.arrow.down")
                    .font(.headline)
                    .padding()
                    .background(.purple)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }

            Text("Icon will be saved to Photos")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .alert("Icon Saved", isPresented: $showingSaved) {
            Button("OK") {}
        } message: {
            Text("The 1024x1024 app icon has been saved to your Photos.")
        }
        .alert("Export Failed", isPresented: $showingError) {
            Button("OK") {}
        }
    }
}

#Preview("Icon Exporter") {
    IconExporter()
}

#Preview("Export Button") {
    IconExportButton()
}
