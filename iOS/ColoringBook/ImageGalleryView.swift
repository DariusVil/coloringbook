import SwiftUI

/// Main gallery view showing a grid of coloring images
struct ImageGalleryView: View {
    @State private var viewModel = ImageGalleryViewModel()
    @State private var showingSettings = false

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.images.isEmpty {
                    ProgressView("Loading images...")
                } else if let error = viewModel.errorMessage, viewModel.images.isEmpty {
                    errorView(message: error)
                } else if viewModel.images.isEmpty {
                    emptyView
                } else {
                    galleryGrid
                }
            }
            .navigationTitle("Coloring Book")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .refreshable {
                await viewModel.loadImages()
            }
            .task {
                await viewModel.loadImages()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(viewModel: viewModel)
            }
        }
    }

    private var galleryGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.images) { image in
                    NavigationLink(value: image) {
                        ImageThumbnailView(image: image, baseURL: viewModel.serverURL)
                    }
                }
            }
            .padding()
        }
        .navigationDestination(for: ColoringImage.self) { image in
            ImageDetailView(image: image, baseURL: viewModel.serverURL)
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Unable to Load Images")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await viewModel.loadImages()
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Settings") {
                showingSettings = true
            }
        }
        .padding()
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Images Available")
                .font(.headline)

            Text("Add coloring images to the server's images folder.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Refresh") {
                Task {
                    await viewModel.loadImages()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

/// Thumbnail view for a single image in the grid
struct ImageThumbnailView: View {
    let image: ColoringImage
    let baseURL: URL

    var body: some View {
        VStack {
            if let url = image.fullURL(baseURL: baseURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(height: 150)
                    case .success(let loadedImage):
                        loadedImage
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 150)
                    case .failure:
                        Image(systemName: "photo")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                            .frame(height: 150)
                    @unknown default:
                        EmptyView()
                    }
                }
            }

            Text(image.title)
                .font(.caption)
                .lineLimit(1)
                .foregroundStyle(.primary)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    ImageGalleryView()
}
