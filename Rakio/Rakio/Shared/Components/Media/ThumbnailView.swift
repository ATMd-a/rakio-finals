import SwiftUI

struct ThumbnailView: View {
    var watchedItem: WatchedItem

    private func thumbnailURL(for videoID: String, source: VideoSource) -> URL? {
        switch source {
        case .youtube:
            return URL(string: "https://img.youtube.com/vi/\(videoID)/hqdefault.jpg")
        case .dailymotion:
            return URL(string: "https://www.dailymotion.com/thumbnail/video/\(videoID)")
        case .unknown:
            return nil
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            
            let videoID = watchedItem.watchedVideoID
            let source = watchedItem.source
            
            if let url = thumbnailURL(for: videoID, source: source) {

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
                            .frame(width: 223, height: 126)

                    @unknown default:
                        EmptyView()
                    }
                }

            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 223, height: 126)
                    .cornerRadius(8)
            }

            Text(watchedItem.series.title)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(width: 223, alignment: .leading)

            Text(watchedItem.episode.title)
                .font(.caption2)
                .foregroundColor(.gray)
                .lineLimit(1)
                .frame(width: 223, alignment: .leading)
        }
    }
}
