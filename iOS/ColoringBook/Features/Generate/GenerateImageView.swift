import SwiftUI

/// Modal view for generating new coloring images
struct GenerateImageView: View {
    @State private var viewModel: GenerateImageViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var didStartGenerating = false

    var onImageGenerated: ((ColoringImage) -> Void)?

    init(
        viewModel: GenerateImageViewModel = GenerateImageViewModel(),
        onImageGenerated: ((ColoringImage) -> Void)? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onImageGenerated = onImageGenerated
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isGenerating {
                    GeneratingProgressView(prompt: viewModel.prompt)
                } else {
                    formContent
                }
            }
            .navigationTitle(viewModel.isGenerating ? "" : "Generate Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if viewModel.isGenerating {
                            viewModel.cancelGeneration()
                        }
                        dismiss()
                    }
                }
            }
            .interactiveDismissDisabled(viewModel.isGenerating)
            .onChange(of: viewModel.isGenerating) { wasGenerating, isGenerating in
                if wasGenerating && !isGenerating && didStartGenerating {
                    // Generation finished
                    if viewModel.errorMessage == nil, let newImage = viewModel.lastGeneratedImage {
                        onImageGenerated?(newImage)
                        dismiss()
                    }
                }
                if isGenerating {
                    didStartGenerating = true
                }
            }
        }
    }

    private var formContent: some View {
        Form {
            Section {
                TextField("Describe the image...", text: $viewModel.prompt, axis: .vertical)
                    .lineLimit(3...6)
            } header: {
                Text("What would you like to color?")
            } footer: {
                Text("Example: cute cat playing with yarn")
            }

            Section {
                Button {
                    viewModel.generateImage()
                } label: {
                    HStack {
                        Spacer()
                        Text("Generate")
                        Spacer()
                    }
                }
                .disabled(!viewModel.canGenerate)
            }

            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }
        }
    }
}

/// Aesthetic progress view shown during image generation
private struct GeneratingProgressView: View {
    let prompt: String
    @State private var currentTipIndex = 0
    @State private var animationPhase = 0.0

    private let tips = [
        "Our AI artist is sketching your idea...",
        "Adding clean lines for easy coloring...",
        "Making sure the shapes are kid-friendly...",
        "Almost ready for your crayons...",
        "Creating something special just for you..."
    ]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated icon
            ZStack {
                Circle()
                    .fill(.purple.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(1 + 0.1 * sin(animationPhase))

                Circle()
                    .fill(.purple.opacity(0.15))
                    .frame(width: 90, height: 90)
                    .scaleEffect(1 + 0.1 * sin(animationPhase + .pi))

                Image(systemName: "paintbrush.pointed.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.purple)
                    .rotationEffect(.degrees(sin(animationPhase) * 10))
            }

            VStack(spacing: 16) {
                Text("Creating Your Coloring Page")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("\"\(prompt)\"")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 32)
            }

            // Cycling tips
            VStack(spacing: 12) {
                Text(tips[currentTipIndex])
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .contentTransition(.numericText())
                    .animation(.easeInOut, value: currentTipIndex)

                ProgressView()
                    .scaleEffect(1.2)
            }
            .padding(.horizontal, 32)

            Spacer()

            // Patience note at the bottom
            Label("This usually takes 15-30 seconds", systemImage: "clock")
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animationPhase = .pi * 2
            }
            startTipRotation()
        }
    }

    private func startTipRotation() {
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(4))
                await MainActor.run {
                    withAnimation {
                        currentTipIndex = (currentTipIndex + 1) % tips.count
                    }
                }
            }
        }
    }
}

#Preview {
    GenerateImageView()
}
