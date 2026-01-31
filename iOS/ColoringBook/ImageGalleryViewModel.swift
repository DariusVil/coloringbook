import Foundation

/// View model for the image gallery
@Observable
@MainActor
final class ImageGalleryViewModel {
    private(set) var images: [ColoringImage] = []
    private(set) var isLoading = false
    private(set) var isGenerating = false
    private(set) var isSearching = false
    private(set) var errorMessage: String?
    private(set) var lastGeneratedImage: ColoringImage?

    var searchQuery = ""
    var isShowingSearchResults = false

    private let imageService = ImageService()
    private var generationTask: Task<Void, Never>?

    let serverURL = URL(string: "https://coloringbook.brerum.com")!

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

    func generateImage(prompt: String) {
        generationTask = Task {
            isGenerating = true
            errorMessage = nil
            lastGeneratedImage = nil

            do {
                let newImage = try await imageService.generateImage(prompt: prompt, baseURL: serverURL)
                try Task.checkCancellation()
                images.insert(newImage, at: 0)  // Add to beginning (newest first)
                lastGeneratedImage = newImage
            } catch is CancellationError {
                // User cancelled, no error message needed
            } catch {
                errorMessage = error.localizedDescription
            }

            isGenerating = false
        }
    }

    func clearLastGeneratedImage() {
        lastGeneratedImage = nil
    }

    func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
        isGenerating = false
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
