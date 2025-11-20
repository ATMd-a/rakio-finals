import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Series Detail View
struct SeriesDetailView: View {
    @StateObject private var viewModel: SeriesDetailViewModel
    @State private var currentEpisode: Episode?
    
    @State private var isDescriptionExpanded = false
    @State private var isPlayerPlaying = true
    @State private var playerProgress: Double = 0.0
    
    @State private var isFavoritedInFirestore: Bool = false
    @State private var isUserLoggedIn: Bool = false
    @State private var watchedEpisodes: Set<String> = []

    @State private var isUsingYouTube: Bool = true

    private var allEpisodes: [Episode] {
        let trailerEpisode = Episode(
            id: "trailer",
            title: "Trailer",
            code: [viewModel.series.trailerURL],
            epNumber: 0
        )
        return [trailerEpisode] + viewModel.episodes
    }

    init(show: Series) {
        _viewModel = StateObject(wrappedValue: SeriesDetailViewModel(series: show))
        _currentEpisode = State(initialValue: nil)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 0) {
                Spacer().frame(height: 20)

                // MARK: Video Player
                if let episode = currentEpisode {
                    if isUsingYouTube {
                        if let videoID = episode.code.first {
                            YouTubePlayerView(videoID: videoID, isPlaying: $isPlayerPlaying)
                                .frame(height: 220)
                                .cornerRadius(12)
                                .onChange(of: playerProgress) { newValue in
                                    if newValue >= 0.9 {
                                        Task { await markEpisodeWatched(episode) }
                                    }
                                }
                        } else {
                            Text("No video available")
                                .frame(height: 220)
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                        }

                    } else {
                        DailymotionPlayerView(videoID: episode.code.first ?? "", isPlaying: $isPlayerPlaying)
                            .frame(height: 220)
                            .cornerRadius(12)
                            .onChange(of: playerProgress) { newValue in
                                if newValue >= 0.9 { Task { await markEpisodeWatched(episode) } }
                            }
                    }
                } else {
                    Text("No video selected.")
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                }

                // MARK: Details
                VStack(alignment: .leading, spacing: 12) {
                    Text(viewModel.series.title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                        .padding(.bottom, 2)

                    HStack {
                        if let title = currentEpisode?.title {
                            Text(title)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Button(action: toggleSave) {
                            Image(systemName: isFavoritedInFirestore ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(isUserLoggedIn ? Color.rakioPrimary : Color.gray)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(isUserLoggedIn ? Color.white.opacity(0.05) : Color.clear)
                                )
                        }
                        .disabled(!isUserLoggedIn)
                    }

                    HStack(spacing: 8) {
                        Text(formatDate(viewModel.series.dateReleased.dateValue()))
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        Rectangle()
                            .fill(Color.gray)
                            .frame(width: 1, height: 14)

                        Text(viewModel.series.genre.joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    ExpandableDescriptionView(description: viewModel.series.description, isExpanded: $isDescriptionExpanded)
                        .padding(.top, 4)
                }
                .padding(.top, 16)

                // MARK: Player Toggle
                if !allEpisodes.isEmpty {
                    Picker("Player", selection: $isUsingYouTube) {
                        Text("YouTube").tag(true)
                        Text("Dailymotion").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.vertical, 10)
                    .onChange(of: isUsingYouTube) { newSourceIsYouTube in
                        Task { await viewModel.fetchEpisodes(isYouTube: newSourceIsYouTube) }
                        if let firstEpisode = allEpisodes.first(where: { $0.epNumber == 1 }) {
                            currentEpisode = firstEpisode
                        } else {
                            currentEpisode = allEpisodes.first
                        }
                        isPlayerPlaying = true
                    }
                }

                // MARK: Episode Selection
                if viewModel.isLoadingEpisodes {
                    ProgressView("Loading episodes...")
                        .foregroundColor(.white)
                        .padding()
                } else if !allEpisodes.isEmpty {
                    EpisodeSelectionView(
                        episodes: allEpisodes,
                        selectedVideoURL: Binding(
                            get: { currentEpisode?.code.first },
                            set: { newValue in
                                if let previous = currentEpisode {
                                    Task { await markEpisodeWatched(previous) }
                                }
                                if let url = newValue {
                                    currentEpisode = allEpisodes.first(where: { $0.code.first == url })
                                    Task { await checkIfEpisodeWatched(currentEpisode?.id) }
                                }
                            }
                        ),
                        watchedEpisodes: watchedEpisodes
                    )
                    .padding(.top, 20)
                } else {
                    Text("No episodes available")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.subheadline)
                        .padding(.top, 20)
                }

                // MARK: Related Novel
                if let novelDetail = viewModel.relatedNovelDetail {
                    HStack {
                        Text("Read the Novel")
                            .font(.custom("Poppins", size: 18))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.top, 40)

                    NavigationLink(destination: NovelDetailView(novelId: novelDetail.id!)) {
                        HStack(spacing: 15) {
                            Image(uiImage: UIImage(named: novelDetail.imageName!) ?? UIImage())
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 140)
                                .cornerRadius(6)
                                .clipped()

                            VStack(alignment: .leading) {
                                Text(novelDetail.title)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                Text("Read Novel Chapters ➔")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // MARK: Comments
                EnhancedCommentsView(
                    contentId: viewModel.series.id ?? "",
                    contentType: ContentType.shows
                )
                .padding(.top, 20)

                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .background(Color.rakioBackground.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData()
            if let firstEpisode = allEpisodes.first(where: { $0.epNumber == 1 }) {
                currentEpisode = firstEpisode
            } else {
                currentEpisode = allEpisodes.first
            }
            await checkIfEpisodeWatched(currentEpisode?.id)
            checkUserStatus()
            await loadFavoritedState()
            await loadAllWatchedEpisodes()
        }
        .onAppear { checkUserStatus() }
        .onDisappear {
            isPlayerPlaying = false
            if let ep = currentEpisode { Task { await markEpisodeWatched(ep) } }
        }
    }
}

// MARK: - Firestore Watch History
extension SeriesDetailView {

    private func checkIfEpisodeWatched(_ episodeId: String?) async {
        guard let episodeId = episodeId, !episodeId.isEmpty, isUserLoggedIn else { return }
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let userRef = Firestore.firestore().collection("users").document(userId)

        do {
            let doc = try await userRef.getDocument()
            if let watchHistory = doc.data()?["watchHistory"] as? [String: Any] {
                await MainActor.run {
                    if watchHistory[episodeId] != nil {
                        watchedEpisodes.insert(episodeId)
                    } else {
                        watchedEpisodes.remove(episodeId)
                    }
                }
            }
        } catch {
            print("Error checking watch history: \(error)")
        }
    }

    @MainActor
    func markEpisodeWatched(_ episode: Episode) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let userRef = Firestore.firestore().collection("users").document(userId)
        guard let videoId = episode.code.first, !videoId.isEmpty else { return }

        do {
            let updateData: [String: Any] = [
                "watchHistory.\(videoId)": [
                    "progress": 1,
                    "lastWatchedAt": FieldValue.serverTimestamp()
                ]
            ]
            try await userRef.updateData(updateData)
            watchedEpisodes.insert(videoId)
        } catch {
            print(error.localizedDescription)
        }
    }

    private func loadAllWatchedEpisodes() async {
        guard isUserLoggedIn, let userId = Auth.auth().currentUser?.uid else {
            await MainActor.run { watchedEpisodes = [] }
            return
        }

        let userRef = Firestore.firestore().collection("users").document(userId)

        do {
            let doc = try await userRef.getDocument()
            if let watchHistory = doc.data()?["watchHistory"] as? [String: Any] {
                let watchedIds = Set(watchHistory.keys)
                await MainActor.run { watchedEpisodes = watchedIds }
            } else {
                await MainActor.run { watchedEpisodes = [] }
            }
        } catch {
            print("Error loading watch history: \(error)")
        }
    }
}

// MARK: - Favorites
extension SeriesDetailView {
    private func toggleSave() {
        guard isUserLoggedIn, let seriesId = viewModel.series.id else { return }
        Task {
            do {
                if isFavoritedInFirestore {
                    try await UserService.shared.removeSeriesFromFavorites(seriesId: seriesId)
                    await MainActor.run { isFavoritedInFirestore = false }
                } else {
                    try await UserService.shared.addSeriesToFavorites(seriesId: seriesId)
                    await MainActor.run { isFavoritedInFirestore = true }
                }
            } catch {
                print("❌ Failed to update favorites: \(error)")
            }
        }
    }

    private func loadFavoritedState() async {
        guard let seriesId = viewModel.series.id else { return }
        guard isUserLoggedIn else {
            await MainActor.run { isFavoritedInFirestore = false }
            return
        }
        let favorited = await UserService.shared.isSeriesFavorited(seriesId: seriesId)
        await MainActor.run { isFavoritedInFirestore = favorited }
    }
}

// MARK: - User Status
extension SeriesDetailView {
    private func checkUserStatus() {
        isUserLoggedIn = Auth.auth().currentUser != nil
    }
}

// MARK: - Helpers
extension SeriesDetailView {
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}
