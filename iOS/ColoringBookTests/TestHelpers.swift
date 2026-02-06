import Foundation
@testable import ColoringBook

enum TestData {
    static let sampleImage = ColoringImage(
        id: "img1",
        filename: "cat.png",
        title: "Cute Cat",
        prompt: "cute cat playing with yarn",
        url: "/images/cat.png",
        thumbnailUrl: "/thumbnails/cat.png",
        created: "2024-01-01"
    )

    static let sampleImage2 = ColoringImage(
        id: "img2",
        filename: "dog.png",
        title: "Happy Dog",
        prompt: "happy dog in the park",
        url: "/images/dog.png",
        thumbnailUrl: "/thumbnails/dog.png",
        created: "2024-01-02"
    )

    static let sampleImageNoOptionals = ColoringImage(
        id: "img3",
        filename: "fish.png",
        title: "Fish",
        prompt: nil,
        url: "/images/fish.png",
        thumbnailUrl: nil,
        created: nil
    )

    static let baseURL = URL(string: "https://example.com")!

    static let sampleImages = [sampleImage, sampleImage2]
}
