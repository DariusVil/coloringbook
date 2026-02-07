package com.example.coloringbook

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.example.coloringbook.navigation.ColoringBookNavGraph
import com.example.coloringbook.ui.theme.ColoringBookTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            ColoringBookTheme {
                ColoringBookNavGraph()
            }
        }
    }
}
