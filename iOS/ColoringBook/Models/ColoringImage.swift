import Foundation

/// Represents a coloring image from the API
struct ColoringImage: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let filename: String
    let title: String
    let prompt: String?
    let url: String
    let thumbnailUrl: String?
    let created: String?

    /// Full URL for loading the image from the server
    func fullURL(baseURL: URL) -> URL? {
        URL(string: url, relativeTo: baseURL)
    }

    /// Thumbnail URL for gallery view, falls back to full URL if no thumbnail
    func thumbnailFullURL(baseURL: URL) -> URL? {
        if let thumbnailUrl {
            return URL(string: thumbnailUrl, relativeTo: baseURL)
        }
        return fullURL(baseURL: baseURL)
    }
}

/// API response wrapper for images list
struct ImagesResponse: Codable, Sendable {
    let images: [ColoringImage]
}

/// API response wrapper for search results
struct SearchResponse: Codable, Sendable {
    let images: [ColoringImage]
    let query: String
    let total: Int
}
