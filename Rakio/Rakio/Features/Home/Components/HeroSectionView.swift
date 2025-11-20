//
//  HeroSectionView.swift
//  Rakio
//
//  Created by STUDENT on 11/18/25.
//


import SwiftUI

struct HeroSectionView: View {
    let series: Series
    @Binding var isPlaying: Bool
    let horizontalPadding: CGFloat = 16
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            YouTubePlayerView(videoID: extractVideoID(from: series.trailerURL), isPlaying: $isPlaying)

            .frame(height: UIScreen.main.bounds.height * 0.3)
            .frame(maxWidth: .infinity)
            .clipped()




            // Gradient overlay for readability
            LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.7)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Content overlay
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text("New")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                }
                .padding(.vertical, 4)
                .cornerRadius(4)

                // Title
                Text(series.title)
                    .font(.system(size: 14, weight: .semibold))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(radius: 5)
                
                // Metadata (Year and Genre)
                HStack(spacing: 8) {
                    Text(yearString(from: series.dateReleased.dateValue()))
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(.white)
                    
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 1, height: 14)
                    
                    Text(series.genre.joined(separator: ", "))
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(.white)
                }
                
                // Description
                Text(series.description)
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.white)
                    .shadow(radius: 5)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .frame(width: 250, alignment: .leading)

                // Play Now button
                NavigationLink(destination: SeriesDetailView(show: series)) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Play Now")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(5)
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Helper Functions
    
    private func yearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }
    func extractVideoID(from urlString: String) -> String {
        if urlString.count == 11 && !urlString.contains("/") { return urlString }
        
        if let url = URL(string: urlString) {
            if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
               let videoID = queryItems.first(where: { $0.name == "v" })?.value {
                return videoID
            }
            if url.host?.contains("youtu.be") == true {
                return url.lastPathComponent
            }
            if url.path.contains("/embed/") {
                return url.lastPathComponent
            }
        }
        return urlString
    }

}
