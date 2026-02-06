import Testing
import Foundation
@testable import ColoringBook

struct ImageGalleryViewModelTests {
    @Test @MainActor func loadImagesSuccess() async {
        let mock = MockImageService()
        await mock.setFetchImagesResult(.success(TestData.sampleImages))
        let vm = ImageGalleryViewModel(imageService: mock, serverURL: TestData.baseURL)

        await vm.loadImages()

        #expect(vm.images.count == 2)
        #expect(vm.images[0].id == "img1")
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == nil)
    }

    @Test @MainActor func loadImagesFailure() async {
        let mock = MockImageService()
        await mock.setFetchImagesResult(.failure(ImageServiceError.serverError(statusCode: 500)))
        let vm = ImageGalleryViewModel(imageService: mock, serverURL: TestData.baseURL)

        await vm.loadImages()

        #expect(vm.images.isEmpty)
        #expect(vm.errorMessage != nil)
        #expect(vm.isLoading == false)
    }

    @Test @MainActor func searchImagesSuccess() async {
        let mock = MockImageService()
        await mock.setSearchImagesResult(.success([TestData.sampleImage]))
        let vm = ImageGalleryViewModel(imageService: mock, serverURL: TestData.baseURL)
        vm.searchQuery = "cat"

        await vm.searchImages()

        #expect(vm.images.count == 1)
        #expect(vm.isShowingSearchResults == true)
    }

    @Test @MainActor func searchEmptyQueryClearsResults() async {
        let mock = MockImageService()
        await mock.setFetchImagesResult(.success(TestData.sampleImages))
        let vm = ImageGalleryViewModel(imageService: mock, serverURL: TestData.baseURL)
        vm.searchQuery = ""
        vm.isShowingSearchResults = true

        await vm.searchImages()

        #expect(vm.isShowingSearchResults == false)
        #expect(vm.images.count == 2)
    }

    @Test @MainActor func clearSearch() async {
        let mock = MockImageService()
        await mock.setFetchImagesResult(.success(TestData.sampleImages))
        let vm = ImageGalleryViewModel(imageService: mock, serverURL: TestData.baseURL)
        vm.searchQuery = "cat"
        vm.isShowingSearchResults = true

        await vm.clearSearch()

        #expect(vm.searchQuery == "")
        #expect(vm.isShowingSearchResults == false)
        #expect(vm.images.count == 2)
    }

    @Test @MainActor func insertImage() async {
        let mock = MockImageService()
        await mock.setFetchImagesResult(.success([TestData.sampleImage]))
        let vm = ImageGalleryViewModel(imageService: mock, serverURL: TestData.baseURL)
        await vm.loadImages()

        vm.insertImage(TestData.sampleImage2)

        #expect(vm.images.count == 2)
        #expect(vm.images[0].id == "img2")
    }
}
