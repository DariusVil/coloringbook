import SwiftUI

/// Thumbnail view for a single image in the grid
struct ImageThumbnailView: View {
    let image: ColoringImage
    let baseURL: URL
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Image container
            ZStack {
                if let url = image.thumbnailFullURL(baseURL: baseURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(.clear)
                                .aspectRatio(3/4, contentMode: .fit)
                                .overlay {
                                    ProgressView()
                                }
                        case .success(let loadedImage):
                            loadedImage
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        case .failure:
                            Rectangle()
                                .fill(.clear)
                                .aspectRatio(3/4, contentMode: .fit)
                                .overlay {
                                    Image(systemName: "photo")
                                        .font(.system(size: 32))
                                        .foregroundStyle(.tertiary)
                                }
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(cardImageBackground)

            // Title bar
            Text(image.title)
                .font(.footnote.weight(.medium))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(cardTitleBackground)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(cardBorder, lineWidth: 1)
        }
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, y: 4)
    }

    private var cardImageBackground: Color {
        colorScheme == .dark ? Color(white: 0.95) : .white
    }

    private var cardTitleBackground: some ShapeStyle {
        colorScheme == .dark
            ? Color(white: 0.15)
            : Color(.systemGray6)
    }

    private var cardBorder: some ShapeStyle {
        colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color.black.opacity(0.04)
    }
}
