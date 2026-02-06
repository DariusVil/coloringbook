import Testing
import Foundation
@testable import ColoringBook

struct ImageDetailViewModelTests {
    @Test @MainActor func loadImageInvalidURL() async {
        // Image with an empty url that won't form a valid URL
        let image = ColoringImage(
            id: "bad",
            filename: "bad.png",
            title: "Bad",
            prompt: nil,
            url: "",
            thumbnailUrl: nil,
            created: nil
        )
        let vm = ImageDetailViewModel(image: image, baseURL: URL(string: "https://example.com")!)

        await vm.loadImage()

        #expect(vm.loadError == true)
        #expect(vm.loadedImage == nil)
    }

    @Test @MainActor func loadImageNetworkFailure() async {
        // Use a URL that will fail (unreachable host)
        let image = TestData.sampleImage
        let vm = ImageDetailViewModel(image: image, baseURL: URL(string: "https://localhost:1")!)

        await vm.loadImage()

        #expect(vm.loadError == true)
        #expect(vm.loadedImage == nil)
    }
}
