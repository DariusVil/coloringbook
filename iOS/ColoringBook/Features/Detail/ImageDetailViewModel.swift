import Foundation
import UIKit

/// View model for the image detail screen
@Observable
@MainActor
final class ImageDetailViewModel {
    private(set) var loadedImage: UIImage?
    private(set) var loadError = false
    private(set) var showingPrintError = false

    let image: ColoringImage
    let baseURL: URL

    nonisolated init(image: ColoringImage, baseURL: URL) {
        self.image = image
        self.baseURL = baseURL
    }

    func loadImage() async {
        guard let url = image.fullURL(baseURL: baseURL) else {
            loadError = true
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) {
                loadedImage = uiImage
            } else {
                loadError = true
            }
        } catch {
            loadError = true
        }
    }

    func printCurrentImage() {
        guard let uiImage = loadedImage else {
            showingPrintError = true
            return
        }

        if !PrintService.printImage(uiImage, title: image.title) {
            showingPrintError = true
        }
    }

    func dismissPrintError() {
        showingPrintError = false
    }
}
