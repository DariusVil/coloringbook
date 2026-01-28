import SwiftUI
import UIKit

/// Full-screen view of a single coloring image with print capability
struct ImageDetailView: View {
    let image: ColoringImage
    let baseURL: URL

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var loadedImage: UIImage?
    @State private var isLoading = true
    @State private var showingPrintError = false

    private let printService = PrintService()

    var body: some View {
        GeometryReader { geometry in
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                if let url = image.fullURL(baseURL: baseURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        case .success(let swiftUIImage):
                            swiftUIImage
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .scaleEffect(scale)
                                .frame(
                                    width: geometry.size.width * scale,
                                    height: geometry.size.height * scale
                                )
                                .gesture(magnificationGesture)
                                .onAppear {
                                    loadUIImage(from: url)
                                }
                        case .failure:
                            VStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 48))
                                Text("Failed to load image")
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height)
                        @unknown default:
                            EmptyView()
                        }
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
                .disabled(loadedImage == nil || !printService.isPrintingAvailable)
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

    private func loadUIImage(from url: URL) {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        self.loadedImage = uiImage
                    }
                }
            } catch {
                print("Failed to load UIImage: \(error)")
            }
        }
    }

    private func printCurrentImage() {
        guard let image = loadedImage else {
            showingPrintError = true
            return
        }

        if !printService.printImage(image, title: self.image.title) {
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
                url: "/images/test.png"
            ),
            baseURL: URL(string: "http://localhost:8000")!
        )
    }
}
