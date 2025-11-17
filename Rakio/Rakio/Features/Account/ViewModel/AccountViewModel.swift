//
//  AccountViewModel.swift
//  Rakio
//
//  Created by STUDENT on 11/12/25.
//


import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

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

        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = documentsURL.appendingPathComponent("Resources/\(uid)_profile.jpg")

        if fileManager.fileExists(atPath: fileURL.path),
           let image = UIImage(contentsOfFile: fileURL.path) {
            self.profileImage = image
        } else {
            self.profileImage = UIImage(named: "MewerLogo_Black")
        }
    }

    // MARK: - Load Watched History
    func loadWatchedHistory() async {
            print("🔄 Loading watched history (async/await)...")

            guard let user = Auth.auth().currentUser else {
                print("⚠️ No logged in user, skipping history load.")
                self.watchedHistory = []
                return
            }

            do {
                let userDoc = try await db.collection("users").document(user.uid).getDocument()
                
                guard let watchHistory = userDoc.data()?["watchHistory"] as? [String: [String: Any]] else {
                    print("⚠️ No watchHistory found for user.")
                    self.watchedHistory = []
                    return
                }

                // 1. Extract and process the raw watched data
                let watchedVideoData: [(code: String, lastWatched: Date?)] = watchHistory.compactMap { key, value in
                    let ts = value["lastWatchedAt"] as? Timestamp
                    return (code: key, lastWatched: ts?.dateValue())
                }
                
                // Fetch ALL series documents first (This simplifies the nested lookup)
                let seriesSnapshot = try await db.collection("shows").getDocuments()
                var allWatchedItems: [WatchedItem] = []

                // 2. Concurrently process each series and its episodes
                // Use withTaskGroup for concurrent fetching to speed up the process
                try await withThrowingTaskGroup(of: [WatchedItem].self) { group in
                    
                    for seriesDoc in seriesSnapshot.documents {
                        let seriesID = seriesDoc.documentID
                        
                        // Decode Series using the SeriesService's fetchSeries method if available,
                        // or inline decoding for simplicity as shown below:
                        let seriesData = seriesDoc.data()
                        let series = Series(
                            id: seriesID,
                            title: seriesData["title"] as? String ?? "Untitled Series",
                            description: seriesData["description"] as? String ?? "",
                            genre: seriesData["genre"] as? [String] ?? [],
                            isSeries: seriesData["isSeries"] as? Bool ?? true,
                            dateReleased: seriesData["dateReleased"] as? Timestamp ?? Timestamp(),
                            trailerURL: seriesData["trailerURL"] as? String ?? "",
                            imageName: seriesData["imageName"] as? String ?? "",
                            relatedNovelId: nil // Or fetch the actual reference if needed
                        )

                        // Add a concurrent task for each series to fetch its episodes
                        group.addTask {
                            let epSnapshot = try await self.db.collection("shows").document(seriesID).collection("episodes").getDocuments()
                            var seriesWatchedItems: [WatchedItem] = []
                            
                            for epDoc in epSnapshot.documents {
                                let epData = epDoc.data()
                                let codes = epData["code"] as? [String] ?? []
                                let title = epData["title"] as? String ?? "Untitled Episode"
                                let epNumber = epData["epNumber"] as? Int ?? -1
                                
                                // Check if any code in this episode was watched by the user
                                for code in codes {
                                    if let watchedEntry = watchedVideoData.first(where: { $0.code == code }) {
                                        let episode = Episode(
                                            id: epDoc.documentID,
                                            title: title,
                                            code: codes,
                                            epNumber: epNumber
                                        )
                                        let item = WatchedItem(
                                            series: series,
                                            episode: episode,
                                            lastWatchedAt: watchedEntry.lastWatched
                                        )
                                        seriesWatchedItems.append(item)
                                        // Optimization: Break inner loop once a match is found for this episode
                                        break
                                    }
                                }
                            }
                            return seriesWatchedItems
                        }
                    }
                    
                    // 3. Collect all results from the concurrent tasks
                    for try await items in group {
                        allWatchedItems.append(contentsOf: items)
                    }
                }

                // 4. Final sorting and updating the UI state
                self.watchedHistory = allWatchedItems.sorted {
                    ($0.lastWatchedAt ?? .distantPast) > ($1.lastWatchedAt ?? .distantPast)
                }
                print("✅ Loaded \(self.watchedHistory.count) watched items (async/await sorted).")

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
