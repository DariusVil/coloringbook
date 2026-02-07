package com.example.coloringbook.services

import com.example.coloringbook.models.ColoringImage
import kotlinx.serialization.Serializable

@Serializable
data class ImagesResponse(val images: List<ColoringImage>)

@Serializable
data class SearchResponse(
    val images: List<ColoringImage>,
    val query: String,
    val total: Int
)

@Serializable
data class GenerateImageRequest(val prompt: String)

@Serializable
data class GenerateImageResponse(val image: ColoringImage)
