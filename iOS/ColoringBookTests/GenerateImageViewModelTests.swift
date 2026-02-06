import Testing
import Foundation
@testable import ColoringBook

struct GenerateImageViewModelTests {
    @Test @MainActor func generateImageSuccess() async throws {
        let mock = MockImageService()
        let expectedImage = TestData.sampleImage
        await mock.setGenerateImageResult(.success(expectedImage))
        let vm = GenerateImageViewModel(imageService: mock, serverURL: TestData.baseURL, appToken: nil)
        vm.prompt = "cute cat"

        vm.generateImage()
        // Wait for the generation task to complete
        try await Task.sleep(for: .milliseconds(100))

        #expect(vm.lastGeneratedImage?.id == expectedImage.id)
        #expect(vm.isGenerating == false)
        #expect(vm.errorMessage == nil)
    }

    @Test @MainActor func generateImageFailure() async throws {
        let mock = MockImageService()
        await mock.setGenerateImageResult(.failure(ImageServiceError.serverError(statusCode: 500)))
        let vm = GenerateImageViewModel(imageService: mock, serverURL: TestData.baseURL, appToken: nil)
        vm.prompt = "cute cat"

        vm.generateImage()
        try await Task.sleep(for: .milliseconds(100))

        #expect(vm.lastGeneratedImage == nil)
        #expect(vm.errorMessage != nil)
        #expect(vm.isGenerating == false)
    }

    @Test @MainActor func cancelGeneration() async {
        let mock = MockImageService()
        let vm = GenerateImageViewModel(imageService: mock, serverURL: TestData.baseURL, appToken: nil)
        vm.prompt = "cute cat"

        vm.generateImage()
        vm.cancelGeneration()

        #expect(vm.isGenerating == false)
    }

    @Test @MainActor func canGenerateDisabledForEmptyPrompt() {
        let vm = GenerateImageViewModel(serverURL: TestData.baseURL, appToken: nil)
        #expect(vm.canGenerate == false)
    }

    @Test @MainActor func canGenerateEnabledForNonEmptyPrompt() {
        let vm = GenerateImageViewModel(serverURL: TestData.baseURL, appToken: nil)
        vm.prompt = "cute cat"
        #expect(vm.canGenerate == true)
    }

    @Test @MainActor func canGenerateDisabledForWhitespacePrompt() {
        let vm = GenerateImageViewModel(serverURL: TestData.baseURL, appToken: nil)
        vm.prompt = "   "
        #expect(vm.canGenerate == false)
    }
}
