import Foundation

/// Represents a coloring image from the API
struct ColoringImage: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let filename: String
    let title: String
    let url: String

    /// Full URL for loading the image from the server
    func fullURL(baseURL: URL) -> URL? {
        URL(string: url, relativeTo: baseURL)
    }
}

/// API response wrapper for images list
struct ImagesResponse: Codable, Sendable {
    let images: [ColoringImage]
}
