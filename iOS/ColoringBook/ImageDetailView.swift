import SwiftUI
import UIKit

/// Full-screen view of a single coloring image with print capability
struct ImageDetailView: View {
    let image: ColoringImage
    let baseURL: URL

    @Environment(\.colorScheme) private var colorScheme
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var loadedImage: UIImage?
    @State private var loadError = false
    @State private var showingPrintError = false

    var body: some View {
        ZStack {
            // Background
            backgroundView
                .ignoresSafeArea()

            // Image content
            GeometryReader { geometry in
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    imageContent(in: geometry)
                        .frame(
                            minWidth: geometry.size.width,
                            minHeight: geometry.size.height
                        )
                }
            }

            // Floating print button
            VStack {
                Spacer()
                printButton
                    .padding(.bottom, 32)
            }
        }
        .navigationTitle(image.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .alert("Print Unavailable", isPresented: $showingPrintError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Printing is not available on this device.")
        }
        .task {
            await loadImage()
        }
    }

    private var backgroundView: some View {
        Group {
            if colorScheme == .dark {
                Color(white: 0.06)
            } else {
                Color(.systemGray6)
            }
        }
    }

    @ViewBuilder
    private func imageContent(in geometry: GeometryProxy) -> some View {
        Group {
            if let uiImage = loadedImage {
                // Image card
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(20)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.5 : 0.15), radius: 20, y: 10)
                    .padding(20)
                    .scaleEffect(scale)
                    .frame(
                        width: geometry.size.width * scale,
                        height: geometry.size.height * scale,
                        alignment: .center
                    )
                    .gesture(magnificationGesture)
                    .onTapGesture(count: 2) {
                        withAnimation(.spring(response: 0.3)) {
                            scale = scale > 1.0 ? 1.0 : 2.0
                        }
                    }
            } else if loadError {
                errorContent
                    .frame(width: geometry.size.width, height: geometry.size.height)
            } else {
                loadingContent
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading image...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var errorContent: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(.red.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.red)
            }

            VStack(spacing: 8) {
                Text("Failed to Load")
                    .font(.title3.weight(.semibold))

                Text("The image could not be loaded.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var printButton: some View {
        Button {
            printCurrentImage()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "printer.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text("Print")
                    .font(.body.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .background {
                Capsule()
                    .fill(.purple)
                    .shadow(color: .purple.opacity(0.4), radius: 12, y: 6)
            }
        }
        .opacity(loadedImage != nil && PrintService.isPrintingAvailable ? 1 : 0)
        .animation(.easeInOut(duration: 0.2), value: loadedImage != nil)
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value
                scale = min(max(scale * delta, 0.5), 5.0)
            }
            .onEnded { _ in
                lastScale = 1.0
                // Snap back if too small
                if scale < 1.0 {
                    withAnimation(.spring(response: 0.3)) {
                        scale = 1.0
                    }
                }
            }
    }

    private func loadImage() async {
        guard let url = image.fullURL(baseURL: baseURL) else {
            loadError = true
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) {
                loadedImage = uiImage
            } else {
                loadError = true
            }
        } catch {
            loadError = true
        }
    }

    private func printCurrentImage() {
        guard let uiImage = loadedImage else {
            showingPrintError = true
            return
        }

        if !PrintService.printImage(uiImage, title: image.title) {
            showingPrintError = true
        }
    }
}

#Preview {
    NavigationStack {
        ImageDetailView(
            image: ColoringImage(
                id: "test",
                filename: "test.png",
                title: "Test Image",
                prompt: "test image",
                url: "/images/test.png",
                thumbnailUrl: "/thumbnails/test.png",
                created: nil
            ),
            baseURL: URL(string: "http://localhost:8000")!
        )
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        ImageDetailView(
            image: ColoringImage(
                id: "test",
                filename: "test.png",
                title: "Test Image",
                prompt: "test image",
                url: "/images/test.png",
                thumbnailUrl: "/thumbnails/test.png",
                created: nil
            ),
            baseURL: URL(string: "http://localhost:8000")!
        )
    }
    .preferredColorScheme(.dark)
}
