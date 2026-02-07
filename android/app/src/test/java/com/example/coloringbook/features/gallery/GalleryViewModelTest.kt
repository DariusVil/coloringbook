package com.example.coloringbook.features.gallery

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
class GalleryViewModelTest {

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
    fun `loadImages success populates images`() = runTest {
        val mock = MockImageService().apply {
            fetchImagesResult = Result.success(TestData.sampleImages)
        }
        val vm = GalleryViewModel(mock)

        assertEquals(2, vm.uiState.value.images.size)
        assertEquals("img1", vm.uiState.value.images[0].id)
        assertFalse(vm.uiState.value.isLoading)
        assertNull(vm.uiState.value.errorMessage)
    }

    @Test
    fun `loadImages failure sets error message`() = runTest {
        val mock = MockImageService().apply {
            fetchImagesResult = Result.failure(RuntimeException("Server error"))
        }
        val vm = GalleryViewModel(mock)

        assertTrue(vm.uiState.value.images.isEmpty())
        assertNotNull(vm.uiState.value.errorMessage)
        assertFalse(vm.uiState.value.isLoading)
    }

    @Test
    fun `insertImage prepends to list`() = runTest {
        val mock = MockImageService().apply {
            fetchImagesResult = Result.success(TestData.sampleImages)
        }
        val vm = GalleryViewModel(mock)
        val newImage = TestData.sampleImageNoOptionals
        vm.insertImage(newImage)

        assertEquals(3, vm.uiState.value.images.size)
        assertEquals("img3", vm.uiState.value.images[0].id)
    }

    @Test
    fun `searchImages success updates images and search state`() = runTest {
        val mock = MockImageService().apply {
            fetchImagesResult = Result.success(TestData.sampleImages)
            searchImagesResult = Result.success(listOf(TestData.sampleImage))
        }
        val vm = GalleryViewModel(mock)
        vm.updateSearchQuery("cat")
        vm.searchImages()

        assertEquals(1, vm.uiState.value.images.size)
        assertTrue(vm.uiState.value.isShowingSearchResults)
        assertEquals("cat", mock.lastSearchQuery)
    }

    @Test
    fun `searchImages with empty query reloads all images`() = runTest {
        val mock = MockImageService().apply {
            fetchImagesResult = Result.success(TestData.sampleImages)
        }
        val vm = GalleryViewModel(mock)
        vm.updateSearchQuery("")
        vm.searchImages()

        assertFalse(vm.uiState.value.isShowingSearchResults)
        assertEquals(2, mock.fetchImagesCallCount) // init + empty search reload
    }

    @Test
    fun `clearSearch resets query and reloads`() = runTest {
        val mock = MockImageService().apply {
            fetchImagesResult = Result.success(TestData.sampleImages)
            searchImagesResult = Result.success(listOf(TestData.sampleImage))
        }
        val vm = GalleryViewModel(mock)
        vm.updateSearchQuery("cat")
        vm.searchImages()
        vm.clearSearch()

        assertEquals("", vm.uiState.value.searchQuery)
        assertFalse(vm.uiState.value.isShowingSearchResults)
        assertEquals(2, vm.uiState.value.images.size)
    }
}
