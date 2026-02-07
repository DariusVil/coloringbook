package com.example.coloringbook.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.toRoute
import com.example.coloringbook.features.detail.DetailScreen
import com.example.coloringbook.features.gallery.GalleryScreen
import com.example.coloringbook.features.generate.GenerateScreen
import com.example.coloringbook.models.ColoringImage
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

@Serializable
object GalleryRoute

@Serializable
data class DetailRoute(val imageJson: String)

@Serializable
object GenerateRoute

private val json = Json { ignoreUnknownKeys = true }

private fun encodeImage(image: ColoringImage): String =
    json.encodeToString(ColoringImage.serializer(), image)

private fun decodeImage(encoded: String): ColoringImage =
    json.decodeFromString(ColoringImage.serializer(), encoded)

@Composable
fun ColoringBookNavGraph() {
    val navController = rememberNavController()

    NavHost(navController = navController, startDestination = GalleryRoute) {
        composable<GalleryRoute> {
            GalleryScreen(
                onImageClick = { image ->
                    navController.navigate(DetailRoute(encodeImage(image)))
                },
                onGenerateClick = {
                    navController.navigate(GenerateRoute)
                }
            )
        }

        composable<DetailRoute> { backStackEntry ->
            val route = backStackEntry.toRoute<DetailRoute>()
            val image = decodeImage(route.imageJson)
            DetailScreen(
                image = image,
                onBack = { navController.popBackStack() }
            )
        }

        composable<GenerateRoute> {
            GenerateScreen(
                onCancel = { navController.popBackStack() },
                onImageGenerated = { image ->
                    navController.popBackStack()
                    navController.navigate(DetailRoute(encodeImage(image)))
                }
            )
        }
    }
}
