//
// AccountViewModel.swift
// Rakio
//
// Created by STUDENT on 11/12/25.
//


import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// --- HELPER STRUCTS AND FUNCTIONS (Place these outside the class) ---


// 2. Define Source Inference Helper
func inferVideoSource(code: String) -> VideoSource {
    return ThumbnailData.identifySource(code)
}


// -------------------------------------------------------------------

@MainActor
final class AccountViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var watchedHistory: [WatchedItem] = []
    @Published var currentUser: User?
    @Published var currentUsername: String?
    @Published var profileImage: UIImage?

    private let db = Firestore.firestore()
    private let firebaseManager = FirebaseManager.shared
    private let seriesService = SeriesService()
    
    // MARK: - Lifecycle
    init() {
        currentUser = Auth.auth().currentUser
        fetchCurrentUsername()
        // Use the new async method inside a Task
        Task {
            await loadWatchedHistory()
        }
        loadProfileImage()
    }

    // MARK: - User Info
    func username(fromEmail email: String) -> String {
        return email.components(separatedBy: "@").first ?? email
    }

    func fetchCurrentUsername() {
        guard let uid = currentUser?.uid else { return }

        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            if let error = error {
                print("❌ Error fetching username: \(error.localizedDescription)")
                return
            }
            if let username = snapshot?.data()?["username"] as? String {
                DispatchQueue.main.async {
                    self?.currentUsername = username
                }
            }
        }
    }

    // MARK: - Load Profile Image
    func loadProfileImage() {
        guard let uid = currentUser?.uid else {
            self.profileImage = UIImage(named: "MewerLogo_Black")
            return
        }
        
        if let image = LocalStorageManager.shared.loadProfileImage(for: uid) {
            self.profileImage = image
        } else {
            self.profileImage = UIImage(named: "MewerLogo_Black")
        }
    }

    // MARK: - Load Watched History
    func loadWatchedHistory() async {
        guard let user = Auth.auth().currentUser else {
            self.watchedHistory = []
            return
        }
        
        do {
            let userDoc = try await db.collection("users").document(user.uid).getDocument()
            
            guard let watchHistory = userDoc.data()?["watchHistory"] as? [String: [String: Any]],
                  !watchHistory.isEmpty else {
                self.watchedHistory = []
                return
            }
            
            var allWatchedItems: [WatchedItem] = []
            
            // Process each watched video
            for (videoId, watchData) in watchHistory {
                // Query to find which episode contains this video ID
                let episodeQuery = try await db.collectionGroup("episodes")
                    .whereField("code", arrayContains: videoId)
                    .limit(to: 1)
                    .getDocuments()
                
                guard let episodeDoc = episodeQuery.documents.first else { continue }
                
                // Get the series ID from the episode's parent path
                guard let seriesId = episodeDoc.reference.parent.parent?.documentID else { continue }
                
                // Fetch the series document
                let seriesDoc = try await db.collection("shows").document(seriesId).getDocument()
                guard let seriesData = seriesDoc.data() else { continue }
                
                let series = Series(
                    id: seriesId,
                    title: seriesData["title"] as? String ?? "Untitled",
                    description: seriesData["description"] as? String ?? "",
                    genre: seriesData["genre"] as? [String] ?? [],
                    isSeries: seriesData["isSeries"] as? Bool ?? true,
                    dateReleased: seriesData["dateReleased"] as? Timestamp ?? Timestamp(),
                    trailerURL: seriesData["trailerURL"] as? String ?? "",
                    imageName: seriesData["imageName"] as? String ?? "",
                    relatedNovelId: nil
                )
                
                // Decode the episode
                let epData = episodeDoc.data()
                let episode = Episode(
                    id: episodeDoc.documentID,
                    title: epData["title"] as? String ?? "Episode",
                    code: epData["code"] as? [String] ?? [],
                    epNumber: epData["epNumber"] as? Int ?? 0
                )
                
                let thumbnailData = ThumbnailData.generate(for: videoId)
                let progress = watchData["progress"] as? Double ?? 0.0
                let timestamp = (watchData["lastWatchedAt"] as? Timestamp)?.dateValue()
                
                let item = WatchedItem(
                    series: series,
                    episode: episode,
                    lastWatchedAt: timestamp,
                    watchedVideoID: videoId,
                    source: thumbnailData.source,
                    progress: progress
                )
                
                allWatchedItems.append(item)
            }
            
            self.watchedHistory = allWatchedItems.sorted {
                ($0.lastWatchedAt ?? .distantPast) > ($1.lastWatchedAt ?? .distantPast)
            }
            
            print("✅ Loaded \(self.watchedHistory.count) watched items efficiently")
            
        } catch {
            print("❌ Error loading watched history: \(error.localizedDescription)")
            self.watchedHistory = []
        }
    }
    // MARK: - Logout
    func logout() throws {
        try firebaseManager.signOut()
        currentUser = nil
        watchedHistory = []
        currentUsername = nil
        profileImage = UIImage(named: "MewerLogo_Black")
    }
}
