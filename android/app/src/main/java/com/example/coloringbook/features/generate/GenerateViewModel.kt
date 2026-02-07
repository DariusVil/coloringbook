package com.example.coloringbook.features.generate

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.coloringbook.models.ColoringImage
import com.example.coloringbook.services.ImageServiceInterface
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlin.coroutines.cancellation.CancellationException

data class GenerateUiState(
    val prompt: String = "",
    val isGenerating: Boolean = false,
    val errorMessage: String? = null,
    val lastGeneratedImage: ColoringImage? = null
) {
    val canGenerate: Boolean get() = prompt.isNotBlank()
}

class GenerateViewModel(
    private val imageService: ImageServiceInterface,
    private val appToken: String?
) : ViewModel() {

    private val _uiState = MutableStateFlow(GenerateUiState())
    val uiState: StateFlow<GenerateUiState> = _uiState.asStateFlow()

    private var generationJob: Job? = null

    fun updatePrompt(prompt: String) {
        _uiState.value = _uiState.value.copy(prompt = prompt)
    }

    fun generateImage() {
        generationJob = viewModelScope.launch {
            _uiState.value = _uiState.value.copy(
                isGenerating = true,
                errorMessage = null,
                lastGeneratedImage = null
            )
            try {
                val newImage = imageService.generateImage(_uiState.value.prompt, appToken)
                _uiState.value = _uiState.value.copy(
                    lastGeneratedImage = newImage,
                    isGenerating = false
                )
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    errorMessage = e.localizedMessage ?: "Generation failed",
                    isGenerating = false
                )
            }
        }
    }

    fun cancelGeneration() {
        generationJob?.cancel()
        generationJob = null
        _uiState.value = _uiState.value.copy(isGenerating = false)
    }

    companion object {
        fun factory(
            imageService: ImageServiceInterface,
            appToken: String?
        ): ViewModelProvider.Factory =
            object : ViewModelProvider.Factory {
                @Suppress("UNCHECKED_CAST")
                override fun <T : ViewModel> create(modelClass: Class<T>): T =
                    GenerateViewModel(imageService, appToken) as T
            }
    }
}
