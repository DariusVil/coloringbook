package com.example.coloringbook.services

import com.example.coloringbook.TestData
import com.example.coloringbook.models.ColoringImage

class MockImageService : ImageServiceInterface {
    var fetchImagesResult: Result<List<ColoringImage>> = Result.success(emptyList())
    var generateImageResult: Result<ColoringImage> = Result.success(TestData.sampleImage)
    var searchImagesResult: Result<List<ColoringImage>> = Result.success(emptyList())

    var fetchImagesCallCount = 0
    var generateImageCallCount = 0
    var searchImagesCallCount = 0
    var lastGeneratePrompt: String? = null
    var lastSearchQuery: String? = null

    override suspend fun fetchImages(): List<ColoringImage> {
        fetchImagesCallCount++
        return fetchImagesResult.getOrThrow()
    }

    override suspend fun generateImage(prompt: String, appToken: String?): ColoringImage {
        generateImageCallCount++
        lastGeneratePrompt = prompt
        return generateImageResult.getOrThrow()
    }

    override suspend fun searchImages(query: String): List<ColoringImage> {
        searchImagesCallCount++
        lastSearchQuery = query
        return searchImagesResult.getOrThrow()
    }
}
