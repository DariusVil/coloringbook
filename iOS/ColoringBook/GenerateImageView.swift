import SwiftUI

/// Modal view for generating new coloring images
struct GenerateImageView: View {
    @Bindable var viewModel: ImageGalleryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var prompt = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Describe the image...", text: $prompt, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("What would you like to color?")
                } footer: {
                    Text("Example: cute cat playing with yarn")
                }

                Section {
                    Button {
                        Task {
                            await viewModel.generateImage(prompt: prompt)
                            if viewModel.errorMessage == nil {
                                dismiss()
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isGenerating {
                                ProgressView()
                                    .padding(.trailing, 8)
                                Text("Generating...")
                            } else {
                                Text("Generate")
                            }
                            Spacer()
                        }
                    }
                    .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isGenerating)
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Generate Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(viewModel.isGenerating)
                }
            }
            .interactiveDismissDisabled(viewModel.isGenerating)
        }
    }
}

#Preview {
    GenerateImageView(viewModel: ImageGalleryViewModel())
}
