package com.example.coloringbook.features.gallery

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.coloringbook.models.ColoringImage
import com.example.coloringbook.services.ImageServiceInterface
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class GalleryUiState(
    val images: List<ColoringImage> = emptyList(),
    val isLoading: Boolean = false,
    val isSearching: Boolean = false,
    val errorMessage: String? = null,
    val searchQuery: String = "",
    val isShowingSearchResults: Boolean = false
)

class GalleryViewModel(
    private val imageService: ImageServiceInterface
) : ViewModel() {

    private val _uiState = MutableStateFlow(GalleryUiState())
    val uiState: StateFlow<GalleryUiState> = _uiState.asStateFlow()

    init {
        loadImages()
    }

    fun loadImages() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null)
            try {
                val images = imageService.fetchImages()
                _uiState.value = _uiState.value.copy(images = images, isLoading = false)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    errorMessage = e.localizedMessage ?: "Failed to load images",
                    isLoading = false
                )
            }
        }
    }

    fun insertImage(image: ColoringImage) {
        _uiState.value = _uiState.value.copy(
            images = listOf(image) + _uiState.value.images
        )
    }

    fun updateSearchQuery(query: String) {
        _uiState.value = _uiState.value.copy(searchQuery = query)
        if (query.isEmpty() && _uiState.value.isShowingSearchResults) {
            clearSearch()
        }
    }

    fun searchImages() {
        val query = _uiState.value.searchQuery.trim()
        if (query.isEmpty()) {
            _uiState.value = _uiState.value.copy(isShowingSearchResults = false)
            loadImages()
            return
        }
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isSearching = true, errorMessage = null)
            try {
                val images = imageService.searchImages(query)
                _uiState.value = _uiState.value.copy(
                    images = images,
                    isSearching = false,
                    isShowingSearchResults = true
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    errorMessage = e.localizedMessage ?: "Search failed",
                    isSearching = false
                )
            }
        }
    }

    fun clearSearch() {
        _uiState.value = _uiState.value.copy(searchQuery = "", isShowingSearchResults = false)
        loadImages()
    }

    companion object {
        fun factory(imageService: ImageServiceInterface): ViewModelProvider.Factory =
            object : ViewModelProvider.Factory {
                @Suppress("UNCHECKED_CAST")
                override fun <T : ViewModel> create(modelClass: Class<T>): T =
                    GalleryViewModel(imageService) as T
            }
    }
}
