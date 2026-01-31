import SwiftUI
import UIKit

/// Full-screen view of a single coloring image with print capability
struct ImageDetailView: View {
    let image: ColoringImage
    let baseURL: URL

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var loadedImage: UIImage?
    @State private var loadError = false
    @State private var showingPrintError = false

    var body: some View {
        GeometryReader { geometry in
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                Group {
                    if let uiImage = loadedImage {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .frame(
                                width: geometry.size.width * scale,
                                height: geometry.size.height * scale
                            )
                            .gesture(magnificationGesture)
                    } else if loadError {
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48))
                            Text("Failed to load image")
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    } else {
                        ProgressView()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                }
            }
        }
        .navigationTitle(image.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    printCurrentImage()
                } label: {
                    Image(systemName: "printer")
                }
                .disabled(loadedImage == nil || !PrintService.isPrintingAvailable)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    resetZoom()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
            }
        }
        .alert("Print Unavailable", isPresented: $showingPrintError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Printing is not available on this device.")
        }
        .task {
            await loadImage()
        }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value
                scale = min(max(scale * delta, 1.0), 5.0)
            }
            .onEnded { _ in
                lastScale = 1.0
            }
    }

    private func resetZoom() {
        withAnimation {
            scale = 1.0
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
