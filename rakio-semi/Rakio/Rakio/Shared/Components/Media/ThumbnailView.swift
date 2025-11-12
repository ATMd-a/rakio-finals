import SwiftUI

struct ThumbnailView: View {
    var watchedItem: WatchedItem

    // Function to get thumbnail URL for a given video ID
    private func thumbnailURL(for videoID: String) -> URL? {
        return URL(string: "https://img.youtube.com/vi/\(videoID)/maxresdefault.jpg")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Safely get the first video ID from episode.code
            if let firstVideoID = watchedItem.episode.code.first,
               let url = thumbnailURL(for: firstVideoID) {

                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable()
                             .scaledToFill()
                             .frame(width: 223, height: 126)
                             .cornerRadius(8)
                    case .failure(_):
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 223, height: 126)
                            .cornerRadius(8)
                    case .empty:
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(width: 223, height: 126)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                // Placeholder if no video IDs are available
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 223, height: 126)
                    .cornerRadius(8)
            }

            // Series title
            Text(watchedItem.series.title)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(width: 223, alignment: .leading)

            // Episode title
            Text(watchedItem.episode.title)
                .font(.caption2)
                .foregroundColor(.gray)
                .lineLimit(1)
                .frame(width: 223, alignment: .leading)
        }
    }
}
