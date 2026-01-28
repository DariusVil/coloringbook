import Foundation
import SwiftUI

/// View model for the image gallery
@Observable
@MainActor
final class ImageGalleryViewModel {
    private(set) var images: [ColoringImage] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let imageService = ImageService()

    var serverURL: URL {
        get {
            if let urlString = UserDefaults.standard.string(forKey: "serverURL"),
               let url = URL(string: urlString) {
                return url
            }
            return URL(string: "https://coloringbook.brerum.com")!
        }
        set {
            UserDefaults.standard.set(newValue.absoluteString, forKey: "serverURL")
        }
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

    func checkServerHealth() async -> Bool {
        do {
            return try await imageService.healthCheck(baseURL: serverURL)
        } catch {
            return false
        }
    }
}
