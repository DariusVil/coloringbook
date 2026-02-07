package com.example.coloringbook.features.generate

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Brush
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.example.coloringbook.ui.theme.Purple40
import kotlinx.coroutines.delay
import kotlin.math.sin

private val tips = listOf(
    "Our AI artist is sketching your idea...",
    "Adding clean lines for easy coloring...",
    "Making sure the shapes are kid-friendly...",
    "Almost ready for your crayons...",
    "Creating something special just for you..."
)

@Composable
fun GeneratingProgressContent(
    prompt: String,
    modifier: Modifier = Modifier
) {
    var currentTipIndex by remember { mutableIntStateOf(0) }
    var animationTick by remember { mutableIntStateOf(0) }

    LaunchedEffect(Unit) {
        while (true) {
            delay(4000)
            currentTipIndex = (currentTipIndex + 1) % tips.size
        }
    }

    LaunchedEffect(Unit) {
        while (true) {
            delay(50)
            animationTick++
        }
    }

    val phase = animationTick * 0.05f
    val outerScale = 1f + 0.1f * sin(phase).toFloat()
    val innerScale = 1f + 0.1f * sin(phase + Math.PI).toFloat()
    val rotation = sin(phase).toFloat() * 10f

    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
        modifier = modifier
            .fillMaxSize()
            .padding(32.dp)
    ) {
        Spacer(modifier = Modifier.weight(1f))

        // Pulsing circles with rotating brush icon
        Box(contentAlignment = Alignment.Center) {
            Box(
                modifier = Modifier
                    .size(120.dp)
                    .scale(outerScale)
                    .background(Purple40.copy(alpha = 0.1f), CircleShape)
            )
            Box(
                modifier = Modifier
                    .size(90.dp)
                    .scale(innerScale)
                    .background(Purple40.copy(alpha = 0.15f), CircleShape)
            )
            Icon(
                Icons.Default.Brush,
                contentDescription = null,
                modifier = Modifier
                    .size(40.dp)
                    .graphicsLayer { rotationZ = rotation },
                tint = Purple40
            )
        }

        Spacer(modifier = Modifier.height(32.dp))

        Text(
            "Creating Your Coloring Page",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.SemiBold,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            "\"$prompt\"",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
            maxLines = 2,
            fontStyle = FontStyle.Italic
        )

        Spacer(modifier = Modifier.height(32.dp))

        AnimatedContent(
            targetState = currentTipIndex,
            transitionSpec = { fadeIn() togetherWith fadeOut() },
            label = "tip"
        ) { index ->
            Text(
                tips[index],
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
        }

        Spacer(modifier = Modifier.height(12.dp))

        CircularProgressIndicator(
            modifier = Modifier.size(24.dp),
            color = Purple40,
            strokeWidth = 2.dp
        )

        Spacer(modifier = Modifier.weight(1f))

        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(
                Icons.Default.Schedule,
                contentDescription = null,
                modifier = Modifier.size(16.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
            )
            Spacer(modifier = Modifier.width(6.dp))
            Text(
                "This usually takes 15-30 seconds",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
            )
        }

        Spacer(modifier = Modifier.height(32.dp))
    }
}
