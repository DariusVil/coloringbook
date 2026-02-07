package com.example.coloringbook.features.generate

import com.example.coloringbook.TestData
import com.example.coloringbook.services.MockImageService
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class GenerateViewModelTest {

    private val testDispatcher = UnconfinedTestDispatcher()

    @Before
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `generateImage success sets lastGeneratedImage`() = runTest {
        val mock = MockImageService().apply {
            generateImageResult = Result.success(TestData.sampleImage)
        }
        val vm = GenerateViewModel(mock, null)
        vm.updatePrompt("cute cat")
        vm.generateImage()

        assertEquals(TestData.sampleImage.id, vm.uiState.value.lastGeneratedImage?.id)
        assertFalse(vm.uiState.value.isGenerating)
        assertNull(vm.uiState.value.errorMessage)
        assertEquals("cute cat", mock.lastGeneratePrompt)
    }

    @Test
    fun `generateImage failure sets error message`() = runTest {
        val mock = MockImageService().apply {
            generateImageResult = Result.failure(RuntimeException("API error"))
        }
        val vm = GenerateViewModel(mock, null)
        vm.updatePrompt("cute cat")
        vm.generateImage()

        assertNull(vm.uiState.value.lastGeneratedImage)
        assertFalse(vm.uiState.value.isGenerating)
        assertNotNull(vm.uiState.value.errorMessage)
    }

    @Test
    fun `canGenerate is false for empty prompt`() {
        val vm = GenerateViewModel(MockImageService(), null)
        assertFalse(vm.uiState.value.canGenerate)
    }

    @Test
    fun `canGenerate is false for whitespace-only prompt`() {
        val vm = GenerateViewModel(MockImageService(), null)
        vm.updatePrompt("   ")
        assertFalse(vm.uiState.value.canGenerate)
    }

    @Test
    fun `canGenerate is true for valid prompt`() {
        val vm = GenerateViewModel(MockImageService(), null)
        vm.updatePrompt("cute cat")
        assertTrue(vm.uiState.value.canGenerate)
    }

    @Test
    fun `updatePrompt updates state`() {
        val vm = GenerateViewModel(MockImageService(), null)
        vm.updatePrompt("a dog")
        assertEquals("a dog", vm.uiState.value.prompt)
    }

    @Test
    fun `cancelGeneration resets isGenerating`() {
        val vm = GenerateViewModel(MockImageService(), null)
        vm.cancelGeneration()
        assertFalse(vm.uiState.value.isGenerating)
    }
}
