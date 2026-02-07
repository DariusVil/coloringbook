package com.example.coloringbook

import com.example.coloringbook.models.ColoringImage

object TestData {
    val sampleImage = ColoringImage(
        id = "img1",
        filename = "cat.png",
        title = "Cute Cat",
        prompt = "cute cat playing with yarn",
        url = "/images/cat.png",
        thumbnailUrl = "/thumbnails/cat.png",
        created = "2024-01-01"
    )

    val sampleImage2 = ColoringImage(
        id = "img2",
        filename = "dog.png",
        title = "Happy Dog",
        prompt = "happy dog in the park",
        url = "/images/dog.png",
        thumbnailUrl = "/thumbnails/dog.png",
        created = "2024-01-02"
    )

    val sampleImageNoOptionals = ColoringImage(
        id = "img3",
        filename = "fish.png",
        title = "Fish",
        url = "/images/fish.png"
    )

    const val BASE_URL = "https://example.com"

    val sampleImages = listOf(sampleImage, sampleImage2)
}
