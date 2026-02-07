package com.example.coloringbook.di

import com.example.coloringbook.services.ImageService
import com.example.coloringbook.services.ImageServiceInterface

class AppContainer {
    val baseUrl: String = "https://coloringbook.brerum.com"
    val appToken: String = "615876350d4b55b928797ffd82f4b39d204472e7e030a7a30df0a84a31550a51"

    val imageService: ImageServiceInterface by lazy {
        ImageService.create(baseUrl)
    }
}
