package com.example.coloringbook.features.generate

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.coloringbook.ColoringBookApplication
import com.example.coloringbook.models.ColoringImage
import com.example.coloringbook.ui.theme.Purple40

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GenerateScreen(
    onCancel: () -> Unit,
    onImageGenerated: (ColoringImage) -> Unit,
    modifier: Modifier = Modifier
) {
    val application = LocalContext.current.applicationContext as ColoringBookApplication
    val viewModel: GenerateViewModel = viewModel(
        factory = GenerateViewModel.factory(
            application.appContainer.imageService,
            application.appContainer.appToken
        )
    )
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    LaunchedEffect(uiState.lastGeneratedImage) {
        val generated = uiState.lastGeneratedImage
        if (generated != null && !uiState.isGenerating && uiState.errorMessage == null) {
            onImageGenerated(generated)
        }
    }

    BackHandler(enabled = uiState.isGenerating) {
        viewModel.cancelGeneration()
        onCancel()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    if (!uiState.isGenerating) {
                        Text("Generate Image")
                    }
                },
                navigationIcon = {
                    TextButton(onClick = {
                        if (uiState.isGenerating) viewModel.cancelGeneration()
                        onCancel()
                    }) {
                        Text("Cancel")
                    }
                }
            )
        },
        modifier = modifier
    ) { padding ->
        if (uiState.isGenerating) {
            GeneratingProgressContent(
                prompt = uiState.prompt,
                modifier = Modifier.padding(padding)
            )
        } else {
            Column(
                modifier = Modifier
                    .padding(padding)
                    .padding(16.dp)
            ) {
                Text(
                    "What would you like to color?",
                    style = MaterialTheme.typography.labelLarge
                )

                Spacer(modifier = Modifier.height(8.dp))

                OutlinedTextField(
                    value = uiState.prompt,
                    onValueChange = viewModel::updatePrompt,
                    placeholder = { Text("Describe the image...") },
                    modifier = Modifier.fillMaxWidth(),
                    minLines = 3,
                    maxLines = 6
                )

                Spacer(modifier = Modifier.height(4.dp))

                Text(
                    "Example: cute cat playing with yarn",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                Spacer(modifier = Modifier.height(24.dp))

                Button(
                    onClick = viewModel::generateImage,
                    enabled = uiState.canGenerate,
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(containerColor = Purple40)
                ) {
                    Text("Generate")
                }

                if (uiState.errorMessage != null) {
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        uiState.errorMessage!!,
                        color = MaterialTheme.colorScheme.error,
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            }
        }
    }
}
