import SwiftUI
import UIKit

/// Full-screen view of a single coloring image with print capability
struct ImageDetailView: View {
    @State private var viewModel: ImageDetailViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    init(image: ColoringImage, baseURL: URL) {
        _viewModel = State(initialValue: ImageDetailViewModel(image: image, baseURL: baseURL))
    }

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
        .navigationTitle(viewModel.image.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .alert("Print Unavailable", isPresented: Binding(
            get: { viewModel.showingPrintError },
            set: { _ in viewModel.dismissPrintError() }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Printing is not available on this device.")
        }
        .task {
            await viewModel.loadImage()
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
            if let uiImage = viewModel.loadedImage {
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
            } else if viewModel.loadError {
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
            viewModel.printCurrentImage()
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
        .opacity(viewModel.loadedImage != nil && PrintService.isPrintingAvailable ? 1 : 0)
        .animation(.easeInOut(duration: 0.2), value: viewModel.loadedImage != nil)
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
