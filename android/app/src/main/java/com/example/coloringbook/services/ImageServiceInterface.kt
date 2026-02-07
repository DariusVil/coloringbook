package com.example.coloringbook.services

import com.example.coloringbook.models.ColoringImage

interface ImageServiceInterface {
    suspend fun fetchImages(): List<ColoringImage>
    suspend fun generateImage(prompt: String, appToken: String?): ColoringImage
    suspend fun searchImages(query: String): List<ColoringImage>
}
