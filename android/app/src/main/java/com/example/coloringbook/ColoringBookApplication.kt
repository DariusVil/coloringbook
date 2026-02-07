package com.example.coloringbook

import android.app.Application
import com.example.coloringbook.di.AppContainer

class ColoringBookApplication : Application() {
    val appContainer = AppContainer()
}
