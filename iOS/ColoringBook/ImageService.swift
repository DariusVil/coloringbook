import Foundation

/// Service for fetching coloring images from the API
actor ImageService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Fetches all available coloring images
    func fetchImages(from baseURL: URL) async throws -> [ColoringImage] {
        let url = baseURL.appendingPathComponent("api/images")
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImageServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw ImageServiceError.serverError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        let imagesResponse = try decoder.decode(ImagesResponse.self, from: data)
        return imagesResponse.images
    }

    /// Generates a new coloring image
    func generateImage(prompt: String, baseURL: URL, apiKey: String?) async throws -> ColoringImage {
        let url = baseURL.appendingPathComponent("api/generate")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey {
            request.setValue(apiKey, forHTTPHeaderField: "X-App-Token")
        }

        let body = GenerateImageRequest(prompt: prompt)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImageServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw ImageServiceError.serverError(statusCode: httpResponse.statusCode)
        }

        let generateResponse = try JSONDecoder().decode(GenerateImageResponse.self, from: data)
        return generateResponse.image
    }

    /// Searches images by prompt/title
    func searchImages(query: String, baseURL: URL) async throws -> [ColoringImage] {
        guard var components = URLComponents(url: baseURL.appendingPathComponent("api/search"), resolvingAgainstBaseURL: true) else {
            throw ImageServiceError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "q", value: query)]

        guard let url = components.url else {
            throw ImageServiceError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImageServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw ImageServiceError.serverError(statusCode: httpResponse.statusCode)
        }

        let searchResponse = try JSONDecoder().decode(SearchResponse.self, from: data)
        return searchResponse.images
    }
}

enum ImageServiceError: Error, LocalizedError {
    case invalidResponse
    case serverError(statusCode: Int)
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let statusCode):
            return "Server error: \(statusCode)"
        case .invalidURL:
            return "Invalid server URL"
        }
    }
}

struct GenerateImageRequest: Codable, Sendable {
    let prompt: String
}

struct GenerateImageResponse: Codable, Sendable {
    let image: ColoringImage
}
