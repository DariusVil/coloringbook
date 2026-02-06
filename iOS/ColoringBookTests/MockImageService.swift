import Foundation
@testable import ColoringBook

actor MockImageService: ImageServiceProtocol {
    var fetchImagesResult: Result<[ColoringImage], Error> = .success([])
    var generateImageResult: Result<ColoringImage, Error> = .success(
        ColoringImage(id: "gen1", filename: "gen.png", title: "Generated", prompt: "test", url: "/images/gen.png", thumbnailUrl: nil, created: nil)
    )
    var searchImagesResult: Result<[ColoringImage], Error> = .success([])

    var fetchImagesCallCount = 0
    var generateImageCallCount = 0
    var searchImagesCallCount = 0
    var lastGeneratePrompt: String?
    var lastSearchQuery: String?

    func setFetchImagesResult(_ result: Result<[ColoringImage], Error>) {
        fetchImagesResult = result
    }

    func setGenerateImageResult(_ result: Result<ColoringImage, Error>) {
        generateImageResult = result
    }

    func setSearchImagesResult(_ result: Result<[ColoringImage], Error>) {
        searchImagesResult = result
    }

    func fetchImages(from baseURL: URL) async throws -> [ColoringImage] {
        fetchImagesCallCount += 1
        return try fetchImagesResult.get()
    }

    func generateImage(prompt: String, baseURL: URL, apiKey: String?) async throws -> ColoringImage {
        generateImageCallCount += 1
        lastGeneratePrompt = prompt
        return try generateImageResult.get()
    }

    func searchImages(query: String, baseURL: URL) async throws -> [ColoringImage] {
        searchImagesCallCount += 1
        lastSearchQuery = query
        return try searchImagesResult.get()
    }
}
