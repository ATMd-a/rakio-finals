import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Series Detail View
struct SeriesDetailView: View {
    @StateObject private var viewModel: SeriesDetailViewModel
    @State private var currentVideoCodes: [String] = []

    @State private var isDescriptionExpanded = false
    @State private var isPlayerPlaying = true

    @State private var isFavoritedInFirestore: Bool = false
    @State private var isUserLoggedIn: Bool = false
    @State private var watchedEpisodes: Set<String> = []

    @State private var playerProgress: Double = 0.0
    
    // ✅ New state for player toggle
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
        _currentVideoCodes = State(initialValue: [show.trailerURL])
    }

    private var currentEpisode: Episode? {
        allEpisodes.first(where: { $0.code.first == currentVideoCodes.first })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 0) {
                Spacer().frame(height: 20)

                // MARK: Video Player
                if isUsingYouTube {
                    YouTubePlayerView(videos: currentVideoCodes, isPlaying: $isPlayerPlaying)
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(12)
                        .onChange(of: isPlayerPlaying) { newValue in
                            if !newValue { markCurrentEpisodeWatched() }
                        }
                } else {
                    if let first = currentVideoCodes.first {
                        DailymotionPlayerView(videoID: first, isPlaying: $isPlayerPlaying)
                            .frame(height: 220)
                            .frame(maxWidth: .infinity)
                            .cornerRadius(12)
                            .onChange(of: isPlayerPlaying) { newValue in
                                if !newValue { markCurrentEpisodeWatched() }
                            }
                    }
 else {
                        Text("No video selected.")
                            .frame(height: 220)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                    }
                }

                // MARK: Details (title, description, etc.)
                VStack(alignment: .leading, spacing: 12) {
                    Text(viewModel.series.title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                        .padding(.bottom, 2)

                    HStack {
                        if let episodeTitle = currentEpisode?.title {
                            Text(episodeTitle)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }

                        Spacer()

                        Button(action: toggleSave) {
                            Image(systemName: isFavoritedInFirestore ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(isUserLoggedIn ? Color(hex: "437C90") : Color.gray)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(isUserLoggedIn ? Color.white.opacity(0.05) : Color.clear)
                                )
                        }
                        .disabled(!isUserLoggedIn)
                        .buttonStyle(PlainButtonStyle())
                        .help(isUserLoggedIn ? "Save to My List" : "Sign in to save this series")
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
                }

                // MARK: Episode Selection
                if viewModel.isLoadingEpisodes {
                    HStack {
                        Spacer()
                        ProgressView("Loading episodes...")
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding()
                } else if !allEpisodes.isEmpty {
                    EpisodeSelectionView(
                        episodes: allEpisodes,
                        selectedVideoURL: Binding(
                            get: { currentVideoCodes.first },
                            set: { newValue in
                                guard let selectedVideo = newValue else { return }
                                if let episode = allEpisodes.first(where: { $0.code.first == selectedVideo }) {
                                    if let _ = currentEpisode?.code.first { markCurrentEpisodeWatched() }
                                    currentVideoCodes = episode.code
                                    Task { await checkIfEpisodeWatched(episodeId: selectedVideo) }
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

                // MARK: Related Novel Section
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
                CommentsView()
                    .padding(.top, 20)

                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .background(Color(hex: "14110F").ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData()
            
            if let firstEpisode = allEpisodes.first(where: { $0.epNumber == 1 }) {
                currentVideoCodes = firstEpisode.code
                await checkIfEpisodeWatched(episodeId: firstEpisode.code.first ?? "")
            } else {
                currentVideoCodes = [viewModel.series.trailerURL]
                await checkIfEpisodeWatched(episodeId: viewModel.series.trailerURL)
            }
            
            checkUserStatus()
            await loadFavoritedState()
            await loadAllWatchedEpisodes()
        }
        .onAppear {
            checkUserStatus()
            isPlayerPlaying = true
        }
        .onDisappear {
            isPlayerPlaying = false
            markCurrentEpisodeWatched()
        }
    }
}

// MARK: - User Status
extension SeriesDetailView {
    private func checkUserStatus() {
        isUserLoggedIn = Auth.auth().currentUser != nil
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
                try? await Task.sleep(nanoseconds: 300_000_000)
                await loadFavoritedState()
            } catch {
                print("❌ Failed to update favorites: \(error)")
            }
        }
    }

    private func loadFavoritedState() async {
        guard let seriesId = viewModel.series.id else { return }
        guard let _ = Auth.auth().currentUser else {
            await MainActor.run { self.isFavoritedInFirestore = false }
            return
        }

        let favorited = await UserService.shared.isSeriesFavorited(seriesId: seriesId)
        await MainActor.run { self.isFavoritedInFirestore = favorited }
        print("⭐️ Favorite state loaded for \(seriesId): \(favorited)")
    }
}

// MARK: - Watch History
extension SeriesDetailView {
    private func checkIfEpisodeWatched(episodeId: String) async {
        guard isUserLoggedIn, !episodeId.isEmpty else { return }
        let userId = Auth.auth().currentUser!.uid
        let userRef = Firestore.firestore().collection("users").document(userId)

        do {
            let doc = try await userRef.getDocument()
            if let watchHistory = doc.data()?["watchHistory"] as? [String: Any] {
                if watchHistory[episodeId] != nil {
                    await MainActor.run { watchedEpisodes.insert(episodeId) }
                } else {
                    await MainActor.run { watchedEpisodes.remove(episodeId) }
                }
            }
        } catch {
            print("Error checking watch history: \(error)")
        }
    }
    
    private func markCurrentEpisodeWatched() {
        guard isUserLoggedIn, let episodeId = currentEpisode?.code.first else { return }
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let userRef = Firestore.firestore().collection("users").document(userId)
        let data: [String: Any] = [
            "watchHistory": [
                episodeId: [
                    "lastWatchedAt": Timestamp(date: Date()),
                    "progress": 1
                ]
            ]
        ]
        
        userRef.setData(data, merge: true) { error in
            if let error = error {
                print("Failed to mark episode watched: \(error.localizedDescription)")
            } else {
                print("Successfully marked episode \(episodeId) as watched.")
                Task { await MainActor.run { watchedEpisodes.insert(episodeId) } }
            }
        }
    }

    private func loadAllWatchedEpisodes() async {
        guard isUserLoggedIn else {
            await MainActor.run { watchedEpisodes = [] }
            return
        }

        guard let userId = Auth.auth().currentUser?.uid else { return }
        let userRef = Firestore.firestore().collection("users").document(userId)

        do {
            let doc = try await userRef.getDocument()
            if let watchHistory = doc.data()?["watchHistory"] as? [String: [String: Any]] {
                let watchedIds = Set(watchHistory.keys)
                await MainActor.run { self.watchedEpisodes = watchedIds }
                print("Loaded \(watchedIds.count) watched episodes from database.")
            } else {
                await MainActor.run { self.watchedEpisodes = [] }
            }
        } catch {
            print("Error loading ALL watch history: \(error)")
        }
    }
}

// MARK: - Helpers
extension SeriesDetailView {
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - ExpandableDescriptionView
struct ExpandableDescriptionView: View {
    let description: String
    @Binding var isExpanded: Bool
    
    private let lineLimit = 2
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(description)
                .foregroundColor(.white)
                .lineLimit(isExpanded ? nil : lineLimit)
                .font(.body)
            
            if shouldShowSeeMoreButton {
                Button(action: { isExpanded.toggle() }) {
                    Text(isExpanded ? "Show Less" : "See More")
                        .foregroundColor(Color.blue)
                        .font(.subheadline)
                        .bold()
                }
            }
        }
    }
    
    private var shouldShowSeeMoreButton: Bool {
        description.count > 100
    }
}

// MARK: - Comments View
struct CommentsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Comments")
                .font(.headline)
                .foregroundColor(.white)

            HStack {
                Text("Please login first to comment")
                    .foregroundColor(.white)
                    .font(.footnote)

                Spacer()

                Button(action: { }) {
                    Image(systemName: "face.smiling")
                        .foregroundColor(.white)
                }

                Button(action: { }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                }
            }
            .padding(12)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white, lineWidth: 1)
            )
        }
    }
}
