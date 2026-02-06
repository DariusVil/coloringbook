import Foundation

/// View model for the image generation screen
@Observable
@MainActor
final class GenerateImageViewModel {
    var prompt = ""
    private(set) var isGenerating = false
    private(set) var errorMessage: String?
    private(set) var lastGeneratedImage: ColoringImage?

    private let imageService: any ImageServiceProtocol
    private let serverURL: URL
    private let appToken: String?
    private var generationTask: Task<Void, Never>?

    var canGenerate: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    nonisolated init(
        imageService: any ImageServiceProtocol = ImageService(),
        serverURL: URL = URL(string: "https://coloringbook.brerum.com")!,
        appToken: String? = "615876350d4b55b928797ffd82f4b39d204472e7e030a7a30df0a84a31550a51"
    ) {
        self.imageService = imageService
        self.serverURL = serverURL
        self.appToken = appToken
    }

    func generateImage() {
        generationTask = Task {
            isGenerating = true
            errorMessage = nil
            lastGeneratedImage = nil

            do {
                let newImage = try await imageService.generateImage(
                    prompt: prompt,
                    baseURL: serverURL,
                    apiKey: appToken
                )
                try Task.checkCancellation()
                lastGeneratedImage = newImage
            } catch is CancellationError {
                // User cancelled, no error message needed
            } catch {
                errorMessage = error.localizedDescription
            }

            isGenerating = false
        }
    }

    func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
        isGenerating = false
    }
}
