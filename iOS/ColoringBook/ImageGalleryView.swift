import SwiftUI

/// Main gallery view showing a grid of coloring images
struct ImageGalleryView: View {
    @State private var viewModel = ImageGalleryViewModel()
    @State private var showingSettings = false
    @State private var showingGenerate = false
    @State private var navigationPath = NavigationPath()
    @Environment(\.colorScheme) private var colorScheme

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)
    ]

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Background gradient
                backgroundGradient
                    .ignoresSafeArea()

                Group {
                    if (viewModel.isLoading || viewModel.isSearching) && viewModel.images.isEmpty {
                        loadingView
                    } else if let error = viewModel.errorMessage, viewModel.images.isEmpty {
                        errorView(message: error)
                    } else if viewModel.images.isEmpty {
                        emptyView
                    } else {
                        galleryGrid
                    }
                }
            }
            .navigationTitle("Coloring Book")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            showingGenerate = true
                        } label: {
                            Image(systemName: "wand.and.stars")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.purple)
                                .font(.system(size: 18, weight: .medium))
                        }

                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.loadImages()
            }
            .task {
                await viewModel.loadImages()
            }
            .searchable(text: $viewModel.searchQuery, prompt: "Search coloring pages")
            .onSubmit(of: .search) {
                Task {
                    await viewModel.searchImages()
                }
            }
            .onChange(of: viewModel.searchQuery) { oldValue, newValue in
                if newValue.isEmpty && viewModel.isShowingSearchResults {
                    Task {
                        await viewModel.clearSearch()
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingGenerate, onDismiss: {
                if let newImage = viewModel.lastGeneratedImage {
                    viewModel.clearLastGeneratedImage()
                    navigationPath.append(newImage)
                }
            }) {
                GenerateImageView(viewModel: viewModel)
            }
        }
    }

    private var backgroundGradient: some View {
        Group {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [
                        Color(white: 0.08),
                        Color(white: 0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                Color(.systemGroupedBackground)
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text(viewModel.isSearching ? "Searching..." : "Loading images...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var galleryGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(viewModel.images) { image in
                    NavigationLink(value: image) {
                        ImageThumbnailView(image: image, baseURL: viewModel.serverURL)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .navigationDestination(for: ColoringImage.self) { image in
            ImageDetailView(image: image, baseURL: viewModel.serverURL)
        }
    }

    private func errorView(message: String) -> some View {
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
                Text("Unable to Load Images")
                    .font(.title3.weight(.semibold))

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button {
                    Task {
                        await viewModel.loadImages()
                    }
                } label: {
                    Text("Try Again")
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)

                Button("Settings") {
                    showingSettings = true
                }
                .font(.body.weight(.medium))
                .foregroundStyle(.purple)
            }
            .frame(maxWidth: 200)
        }
        .padding(32)
    }

    private var emptyView: some View {
        VStack(spacing: 20) {
            if viewModel.isShowingSearchResults {
                ZStack {
                    Circle()
                        .fill(.secondary.opacity(0.1))
                        .frame(width: 80, height: 80)

                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 8) {
                    Text("No Results Found")
                        .font(.title3.weight(.semibold))

                    Text("Try a different search term.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Button {
                    Task {
                        await viewModel.clearSearch()
                    }
                } label: {
                    Text("Clear Search")
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .frame(maxWidth: 200)
            } else {
                ZStack {
                    Circle()
                        .fill(.purple.opacity(0.1))
                        .frame(width: 80, height: 80)

                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.purple)
                }

                VStack(spacing: 8) {
                    Text("No Coloring Pages Yet")
                        .font(.title3.weight(.semibold))

                    Text("Create your first coloring page with AI!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button {
                    showingGenerate = true
                } label: {
                    Label("Create", systemImage: "wand.and.stars")
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .frame(maxWidth: 200)
            }
        }
        .padding(32)
    }
}

/// Thumbnail view for a single image in the grid
struct ImageThumbnailView: View {
    let image: ColoringImage
    let baseURL: URL
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Image container
            ZStack {
                if let url = image.thumbnailFullURL(baseURL: baseURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(.clear)
                                .aspectRatio(3/4, contentMode: .fit)
                                .overlay {
                                    ProgressView()
                                }
                        case .success(let loadedImage):
                            loadedImage
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        case .failure:
                            Rectangle()
                                .fill(.clear)
                                .aspectRatio(3/4, contentMode: .fit)
                                .overlay {
                                    Image(systemName: "photo")
                                        .font(.system(size: 32))
                                        .foregroundStyle(.tertiary)
                                }
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(cardImageBackground)

            // Title bar
            Text(image.title)
                .font(.footnote.weight(.medium))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(cardTitleBackground)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(cardBorder, lineWidth: 1)
        }
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, y: 4)
    }

    private var cardImageBackground: Color {
        colorScheme == .dark ? Color(white: 0.95) : .white
    }

    private var cardTitleBackground: some ShapeStyle {
        colorScheme == .dark
            ? Color(white: 0.15)
            : Color(.systemGray6)
    }

    private var cardBorder: some ShapeStyle {
        colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color.black.opacity(0.04)
    }
}

#Preview {
    ImageGalleryView()
}

#Preview("Dark Mode") {
    ImageGalleryView()
        .preferredColorScheme(.dark)
}
