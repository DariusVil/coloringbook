import Foundation

/// View model for the image gallery
@Observable
@MainActor
final class ImageGalleryViewModel {
    private(set) var images: [ColoringImage] = []
    private(set) var isLoading = false
    private(set) var isSearching = false
    private(set) var errorMessage: String?

    var searchQuery = ""
    var isShowingSearchResults = false

    private let imageService: any ImageServiceProtocol

    let serverURL: URL

    nonisolated init(
        imageService: any ImageServiceProtocol = ImageService(),
        serverURL: URL = URL(string: "https://coloringbook.brerum.com")!
    ) {
        self.imageService = imageService
        self.serverURL = serverURL
    }

    func loadImages() async {
        isLoading = true
        errorMessage = nil

        do {
            images = try await imageService.fetchImages(from: serverURL)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func insertImage(_ image: ColoringImage) {
        images.insert(image, at: 0)
    }

    func searchImages() async {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            isShowingSearchResults = false
            await loadImages()
            return
        }

        isSearching = true
        errorMessage = nil

        do {
            images = try await imageService.searchImages(query: query, baseURL: serverURL)
            isShowingSearchResults = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isSearching = false
    }

    func clearSearch() async {
        searchQuery = ""
        isShowingSearchResults = false
        await loadImages()
    }
}
