import Foundation

/// Protocol for image service operations, enabling dependency injection and testing
protocol ImageServiceProtocol: Sendable {
    func fetchImages(from baseURL: URL) async throws -> [ColoringImage]
    func generateImage(prompt: String, baseURL: URL, apiKey: String?) async throws -> ColoringImage
    func searchImages(query: String, baseURL: URL) async throws -> [ColoringImage]
}
