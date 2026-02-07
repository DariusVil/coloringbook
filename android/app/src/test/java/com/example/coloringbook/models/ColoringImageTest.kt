package com.example.coloringbook.models

import com.example.coloringbook.TestData
import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class ColoringImageTest {

    private val json = Json { ignoreUnknownKeys = true }

    @Test
    fun `fullUrl constructs correct URL`() {
        val url = TestData.sampleImage.fullUrl("https://example.com")
        assertEquals("https://example.com/images/cat.png", url)
    }

    @Test
    fun `fullUrl trims trailing slash from base URL`() {
        val url = TestData.sampleImage.fullUrl("https://example.com/")
        assertEquals("https://example.com/images/cat.png", url)
    }

    @Test
    fun `thumbnailFullUrl returns thumbnail URL when available`() {
        val url = TestData.sampleImage.thumbnailFullUrl("https://example.com")
        assertEquals("https://example.com/thumbnails/cat.png", url)
    }

    @Test
    fun `thumbnailFullUrl falls back to full URL when no thumbnail`() {
        val url = TestData.sampleImageNoOptionals.thumbnailFullUrl("https://example.com")
        assertEquals("https://example.com/images/fish.png", url)
    }

    @Test
    fun `decoding from JSON with all fields`() {
        val jsonStr = """{"id":"test1","filename":"test.png","title":"Test Image","prompt":"a test prompt","url":"/images/test.png","thumbnailUrl":"/thumbnails/test.png","created":"2024-06-01"}"""
        val image = json.decodeFromString<ColoringImage>(jsonStr)
        assertEquals("test1", image.id)
        assertEquals("test.png", image.filename)
        assertEquals("Test Image", image.title)
        assertEquals("a test prompt", image.prompt)
        assertEquals("/images/test.png", image.url)
        assertEquals("/thumbnails/test.png", image.thumbnailUrl)
        assertEquals("2024-06-01", image.created)
    }

    @Test
    fun `decoding from JSON with optional fields missing`() {
        val jsonStr = """{"id":"test2","filename":"test2.png","title":"Minimal","url":"/images/test2.png"}"""
        val image = json.decodeFromString<ColoringImage>(jsonStr)
        assertEquals("test2", image.id)
        assertNull(image.prompt)
        assertNull(image.thumbnailUrl)
        assertNull(image.created)
    }

    @Test
    fun `encoding and decoding roundtrip`() {
        val encoded = json.encodeToString(ColoringImage.serializer(), TestData.sampleImage)
        val decoded = json.decodeFromString<ColoringImage>(encoded)
        assertEquals(TestData.sampleImage, decoded)
    }
}
