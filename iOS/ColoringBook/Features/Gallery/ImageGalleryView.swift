import SwiftUI

/// Main gallery view showing a grid of coloring images
struct ImageGalleryView: View {
    @State private var viewModel = ImageGalleryViewModel()
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
                    Button {
                        showingGenerate = true
                    } label: {
                        Image(systemName: "wand.and.stars")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.purple)
                            .font(.system(size: 18, weight: .medium))
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
            .sheet(isPresented: $showingGenerate) {
                GenerateImageView { newImage in
                    viewModel.insertImage(newImage)
                    navigationPath.append(newImage)
                }
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

#Preview {
    ImageGalleryView()
}

#Preview("Dark Mode") {
    ImageGalleryView()
        .preferredColorScheme(.dark)
}
