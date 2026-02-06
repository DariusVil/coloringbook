import Testing
import Foundation
@testable import ColoringBook

struct ColoringImageTests {
    @Test func fullURL() {
        let image = TestData.sampleImage
        let url = image.fullURL(baseURL: TestData.baseURL)
        #expect(url?.absoluteString == "https://example.com/images/cat.png")
    }

    @Test func thumbnailFullURL() {
        let image = TestData.sampleImage
        let url = image.thumbnailFullURL(baseURL: TestData.baseURL)
        #expect(url?.absoluteString == "https://example.com/thumbnails/cat.png")
    }

    @Test func thumbnailFallsBackToFullURL() {
        let image = TestData.sampleImageNoOptionals
        let url = image.thumbnailFullURL(baseURL: TestData.baseURL)
        #expect(url?.absoluteString == "https://example.com/images/fish.png")
    }

    @Test func decodingFromJSON() throws {
        let json = """
        {
            "id": "test1",
            "filename": "test.png",
            "title": "Test Image",
            "prompt": "a test prompt",
            "url": "/images/test.png",
            "thumbnailUrl": "/thumbnails/test.png",
            "created": "2024-06-01"
        }
        """.data(using: .utf8)!

        let image = try JSONDecoder().decode(ColoringImage.self, from: json)
        #expect(image.id == "test1")
        #expect(image.filename == "test.png")
        #expect(image.title == "Test Image")
        #expect(image.prompt == "a test prompt")
        #expect(image.url == "/images/test.png")
        #expect(image.thumbnailUrl == "/thumbnails/test.png")
        #expect(image.created == "2024-06-01")
    }

    @Test func decodingWithOptionalFields() throws {
        let json = """
        {
            "id": "test2",
            "filename": "test2.png",
            "title": "Minimal",
            "url": "/images/test2.png"
        }
        """.data(using: .utf8)!

        let image = try JSONDecoder().decode(ColoringImage.self, from: json)
        #expect(image.id == "test2")
        #expect(image.prompt == nil)
        #expect(image.thumbnailUrl == nil)
        #expect(image.created == nil)
    }
}
