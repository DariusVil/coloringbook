package com.example.coloringbook.models

import kotlinx.serialization.Serializable

@Serializable
data class ColoringImage(
    val id: String,
    val filename: String,
    val title: String,
    val prompt: String? = null,
    val url: String,
    val thumbnailUrl: String? = null,
    val created: String? = null
) {
    fun fullUrl(baseUrl: String): String =
        "${baseUrl.trimEnd('/')}$url"

    fun thumbnailFullUrl(baseUrl: String): String =
        if (thumbnailUrl != null) "${baseUrl.trimEnd('/')}$thumbnailUrl"
        else fullUrl(baseUrl)
}
