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

    /// Performs a health check on the server
    func healthCheck(baseURL: URL) async throws -> Bool {
        let url = baseURL.appendingPathComponent("api/health")
        let (_, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            return false
        }

        return httpResponse.statusCode == 200
    }

    /// Generates a new coloring image using DALL-E 3
    func generateImage(prompt: String, baseURL: URL) async throws -> ColoringImage {
        let url = baseURL.appendingPathComponent("api/generate")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

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
