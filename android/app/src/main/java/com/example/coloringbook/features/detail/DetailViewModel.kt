package com.example.coloringbook.features.detail

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.coloringbook.models.ColoringImage
import com.example.coloringbook.services.PrintService
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.net.URL

data class DetailUiState(
    val image: ColoringImage,
    val loadedBitmap: Bitmap? = null,
    val isLoading: Boolean = true,
    val loadError: Boolean = false,
    val showPrintError: Boolean = false
)

class DetailViewModel(
    image: ColoringImage,
    private val baseUrl: String
) : ViewModel() {

    private val _uiState = MutableStateFlow(DetailUiState(image = image))
    val uiState: StateFlow<DetailUiState> = _uiState.asStateFlow()

    init {
        loadImage()
    }

    private fun loadImage() {
        viewModelScope.launch {
            try {
                val url = _uiState.value.image.fullUrl(baseUrl)
                val bitmap = withContext(Dispatchers.IO) {
                    val connection = URL(url).openConnection()
                    connection.connectTimeout = 30000
                    connection.readTimeout = 30000
                    connection.getInputStream().use { stream ->
                        BitmapFactory.decodeStream(stream)
                    }
                }
                if (bitmap != null) {
                    _uiState.value = _uiState.value.copy(
                        loadedBitmap = bitmap,
                        isLoading = false,
                        loadError = false
                    )
                } else {
                    _uiState.value = _uiState.value.copy(isLoading = false, loadError = true)
                }
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(isLoading = false, loadError = true)
            }
        }
    }

    fun printCurrentImage(context: Context) {
        val bitmap = _uiState.value.loadedBitmap ?: return
        val success = PrintService.printBitmap(context, bitmap, _uiState.value.image.title)
        if (!success) {
            _uiState.value = _uiState.value.copy(showPrintError = true)
        }
    }

    fun dismissPrintError() {
        _uiState.value = _uiState.value.copy(showPrintError = false)
    }

    companion object {
        fun factory(image: ColoringImage, baseUrl: String): ViewModelProvider.Factory =
            object : ViewModelProvider.Factory {
                @Suppress("UNCHECKED_CAST")
                override fun <T : ViewModel> create(modelClass: Class<T>): T =
                    DetailViewModel(image, baseUrl) as T
            }
    }
}
