import SwiftUI

struct EpisodeSelectionView: View {
    let episodes: [Episode]
    @Binding var selectedVideoURL: String?
    let watchedEpisodes: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Episodes")
                .font(.headline)
                .foregroundColor(.white)

            Text("\(episodes.count) episode\(episodes.count == 1 ? "" : "s") available")
                .font(.caption)
                .foregroundColor(.gray)

            LazyVGrid(columns: Array(repeating: GridItem(.fixed(56), spacing: 10), count: 5), spacing: 10) {
                ForEach(episodes.indices, id: \.self) { index in
                    let episode = episodes[index]
                    let isSelected = episode.code.first == selectedVideoURL
                    let episodeID = episode.code.first ?? ""
                    let isWatched = watchedEpisodes.contains(episodeID)

                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            selectedVideoURL = episode.code.first
                        }
                    }) {
                        ZStack(alignment: .topTrailing) {
                            // Episode button visuals
                            Text(index == 0 ? "Trailer" : "\(index)")
                                .font(index == 0 ? .caption : .title3)
                                .frame(width: 56, height: 40)
                                .background(backgroundColor(isSelected))
                                .foregroundColor(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color(hex: "437C90"), lineWidth: 1)
                                )
                                .cornerRadius(6)
                                .scaleEffect(isSelected ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: selectedVideoURL)

                            if isWatched {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 10, height: 10)
                                    .offset(x: 5, y: -5)
                            }
                        }
                    }
                }
            }
        }
    }

    private func backgroundColor(_ isSelected: Bool) -> Color {
        return isSelected ? Color(hex: "437C90") : Color.clear
    }
}
