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

func inferVideoSource(code: String) -> VideoSource {
    return ThumbnailData.identifySource(code)
}

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
        print("🔄 Loading watched history...")
        
        guard let user = Auth.auth().currentUser else {
            print("⚠️ No logged in user, skipping history load.")
            self.watchedHistory = []
            return
        }
        
        do {
            let userDoc = try await db.collection("users").document(user.uid).getDocument()
            
            guard let watchHistory = userDoc.data()?["watchHistory"] as? [String: [String: Any]],
                  !watchHistory.isEmpty else {
                print("⚠️ No watchHistory found for user.")
                self.watchedHistory = []
                return
            }
            
            print("📊 Found \(watchHistory.count) watched videos")
            
            var allWatchedItems: [WatchedItem] = []
            
            // Process each watched video
            for (videoId, watchData) in watchHistory {
                // ✅ FIX: Query collectionGroup to search ALL episode subcollections
                // This will find episodes in both "episodes" and "episodes 2"
                let episodeQuery = try await db.collectionGroup("episodes")
                    .whereField("code", arrayContains: videoId)
                    .limit(to: 1)
                    .getDocuments()
                
                // If not found in "episodes", try "episodes 2"
                if episodeQuery.documents.isEmpty {
                    let episodeQuery2 = try await db.collectionGroup("episodes 2")
                        .whereField("code", arrayContains: videoId)
                        .limit(to: 1)
                        .getDocuments()
                    
                    if episodeQuery2.documents.isEmpty {
                        print("⚠️ Episode not found for video ID: \(videoId)")
                        continue
                    }
                    
                    // Process from "episodes 2"
                    if let episodeDoc = episodeQuery2.documents.first {
                        if let item = try? await createWatchedItem(
                            from: episodeDoc,
                            videoId: videoId,
                            watchData: watchData
                        ) {
                            allWatchedItems.append(item)
                        }
                    }
                } else {
                    // Process from "episodes"
                    if let episodeDoc = episodeQuery.documents.first {
                        if let item = try? await createWatchedItem(
                            from: episodeDoc,
                            videoId: videoId,
                            watchData: watchData
                        ) {
                            allWatchedItems.append(item)
                        }
                    }
                }
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
    
    // MARK: - Helper Method
    /// Creates a WatchedItem from an episode document
    private func createWatchedItem(
        from episodeDoc: DocumentSnapshot,
        videoId: String,
        watchData: [String: Any]
    ) async throws -> WatchedItem? {
        
        // Get the series ID from the episode's parent path
        guard let seriesId = episodeDoc.reference.parent.parent?.documentID else {
            print("⚠️ Could not find series ID for episode: \(episodeDoc.documentID)")
            return nil
        }
        
        // Fetch the series document
        let seriesDoc = try await db.collection("shows").document(seriesId).getDocument()
        guard let seriesData = seriesDoc.data() else {
            print("⚠️ Series document not found: \(seriesId)")
            return nil
        }
        
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
            title: epData?["title"] as? String ?? "Episode",
            code: epData?["code"] as? [String] ?? [],
            epNumber: epData?["epNumber"] as? Int ?? 0
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
        
        return item
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
