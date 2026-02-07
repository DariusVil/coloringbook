package com.example.coloringbook.services

import com.example.coloringbook.models.ColoringImage
import com.jakewharton.retrofit2.converter.kotlinx.serialization.asConverterFactory
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import retrofit2.Retrofit
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.Header
import retrofit2.http.POST
import retrofit2.http.Query
import java.util.concurrent.TimeUnit

private interface ColoringBookApi {
    @GET("api/images")
    suspend fun getImages(): ImagesResponse

    @POST("api/generate")
    suspend fun generateImage(
        @Body request: GenerateImageRequest,
        @Header("X-App-Token") appToken: String?
    ): GenerateImageResponse

    @GET("api/search")
    suspend fun searchImages(@Query("q") query: String): SearchResponse
}

class ImageService private constructor(
    private val api: ColoringBookApi
) : ImageServiceInterface {

    override suspend fun fetchImages(): List<ColoringImage> =
        api.getImages().images

    override suspend fun generateImage(prompt: String, appToken: String?): ColoringImage =
        api.generateImage(GenerateImageRequest(prompt), appToken).image

    override suspend fun searchImages(query: String): List<ColoringImage> =
        api.searchImages(query).images

    companion object {
        fun create(baseUrl: String): ImageService {
            val json = Json { ignoreUnknownKeys = true }
            val okHttpClient = OkHttpClient.Builder()
                .connectTimeout(60, TimeUnit.SECONDS)
                .readTimeout(60, TimeUnit.SECONDS)
                .writeTimeout(60, TimeUnit.SECONDS)
                .build()
            val retrofit = Retrofit.Builder()
                .baseUrl(baseUrl)
                .client(okHttpClient)
                .addConverterFactory(json.asConverterFactory("application/json".toMediaType()))
                .build()
            return ImageService(retrofit.create(ColoringBookApi::class.java))
        }
    }
}
