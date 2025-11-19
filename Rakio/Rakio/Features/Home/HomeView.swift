import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    let horizontalPadding: CGFloat = 16
    
    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    if let featuredSeries = viewModel.shows.first(where: { $0.title == "23.5" }) {
                        HeroSectionView(series: featuredSeries, isPlaying: $viewModel.isHeroVideoPlaying)
                            .frame(maxWidth: .infinity)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 500)
                    }

                    // All Series Section
                    allSeriesSection(shows: viewModel.shows)

                    // Solo Novels Section
                    soloNovelsSection(novels: viewModel.novels)

                    Spacer(minLength: 30)
                }
            }
            .background(Color.rakioBackground.ignoresSafeArea())
            .task {
                if viewModel.shows.isEmpty && !viewModel.isLoading {
                    await viewModel.loadHomeData()
                }
            }
            .onAppear {
                viewModel.isHeroVideoPlaying = true
            }
            .onDisappear {
                viewModel.isHeroVideoPlaying = false
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func heroSection(for series: Series, isPlaying: Binding<Bool>) -> some View {
        ZStack(alignment: .bottomLeading) {
            YouTubePlayerView(videos: [series.trailerURL], isPlaying: isPlaying)
                .frame(height: UIScreen.main.bounds.height * 0.3)
                .frame(maxWidth: .infinity)
                .clipped()

            LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.7)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

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

                Text(series.title)
                    .font(.system(size: 14, weight: .semibold))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(radius: 5)
                
                HStack(spacing: 8) {
                    Text(yearString(from: series.dateReleased.dateValue()))
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(.white)
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 1, height: 14)
                    Text(series.genre.joined(separator: ", "))
                        .font(.system(size: 12, weight: .light))
                    .foregroundColor(.white) }
                
                Text(series.description)
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.white)
                    .shadow(radius: 5)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .frame(width: 250, alignment: .leading)

                Button(action: {
                }) {
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

    private func allSeriesSection(shows: [Series]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Top Series")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, horizontalPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(shows, id: \.id) { show in
                        NavigationLink(destination: SeriesDetailView(show: show)) {
                            seriesImage(name: show.imageName, title: show.title)
                                .frame(width: 223, height: 126)
                                .cornerRadius(8)
                                .clipped()
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, horizontalPadding)
            }
        }
    }
    
    private func soloNovelsSection(novels: [Novel]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Top Novels")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, horizontalPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(novels, id: \.id) { novel in
                        NavigationLink(destination: NovelDetailView(novelId: novel.id!)) {
                            novelImage(name: novel.imageName, title: novel.title)
                        }
                    }
                }
                .padding(.horizontal, horizontalPadding)
            }
        }
    }


    // Helper functions
    private func yearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }

    private func seriesImage(name: String?, title: String) -> some View {
        ZStack(alignment: .bottomLeading) {
            if let name = name, let uiImage = UIImage(named: name) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle().fill(Color.gray)
            }
            
            LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color.black]),
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(0.5)
            
            Text(title)
                .font(.system(size: 10, weight: .light))
                .foregroundColor(.white)
                .lineLimit(2)
                .padding([.horizontal, .bottom], 8)
                .multilineTextAlignment(.leading)
        }
        .frame(width: 223, height: 126)
        .clipped()
        .cornerRadius(8)
    }
    
    private func novelImage(name: String?, title: String) -> some View {
        ZStack(alignment: .bottomLeading) {
            if let name = name, let uiImage = UIImage(named: name) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle().fill(Color.gray)
            }
            
            LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color.black]),
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(0.5)
            
            Text(title)
                .font(.system(size: 14, weight: .light))
                .foregroundColor(.white)
                .lineLimit(2)
                .padding([.horizontal, .bottom], 8)
                .multilineTextAlignment(.leading)
        }
        .frame(width: 140, height: 209)
        .clipped()
        .cornerRadius(8)
    }
}
