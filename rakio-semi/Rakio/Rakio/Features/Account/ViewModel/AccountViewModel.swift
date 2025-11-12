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

    // MARK: - Lifecycle
    init() {
        currentUser = Auth.auth().currentUser
        fetchCurrentUsername()
        loadWatchedHistory()
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
    func loadWatchedHistory() {
        print("🔄 Loading watched history...")

        guard let user = Auth.auth().currentUser else {
            print("⚠️ No logged in user, skipping history load.")
            watchedHistory = []
            return
        }

        let userRef = db.collection("users").document(user.uid)
        userRef.getDocument { [weak self] userSnapshot, error in
            if let error = error {
                print("❌ Error fetching user doc: \(error)")
                return
            }

            guard let data = userSnapshot?.data(),
                  let watchHistory = data["watchHistory"] as? [String: [String: Any]] else {
                print("⚠️ No watchHistory found for user.")
                DispatchQueue.main.async { self?.watchedHistory = [] }
                return
            }

            // Extract video IDs and timestamps
            let watchedVideoData: [(id: String, lastWatched: Date?)] = watchHistory.compactMap { key, value in
                let ts = value["lastWatchedAt"] as? Timestamp
                return (id: key, lastWatched: ts?.dateValue())
            }

            var allWatchedItems: [WatchedItem] = []
            let showsRef = self?.db.collection("shows")
            let group = DispatchGroup()

            showsRef?.getDocuments { seriesSnapshot, error in
                guard let seriesSnapshot = seriesSnapshot else { return }

                for seriesDoc in seriesSnapshot.documents {
                    let seriesID = seriesDoc.documentID
                    let data = seriesDoc.data()

                    let series = Series(
                        id: seriesID,
                        title: data["title"] as? String ?? "Untitled Series",
                        description: data["description"] as? String ?? "",
                        genre: data["genre"] as? [String] ?? [],
                        isSeries: data["isSeries"] as? Bool ?? true,
                        isYT: data["isYT"] as? Bool ?? false,
                        dateReleased: data["dateReleased"] as? Timestamp ?? Timestamp(),
                        trailerURL: data["trailerURL"] as? String ?? "",
                        imageName: data["imageName"] as? String ?? "",
                        relatedNovelId: nil
                    )

                    group.enter()
                    showsRef?.document(seriesID).collection("episodes").getDocuments { epSnapshot, error in
                        defer { group.leave() }
                        guard let epSnapshot = epSnapshot else { return }

                        for epDoc in epSnapshot.documents {
                            let epData = epDoc.data()
                            let codes = epData["code"] as? [String] ?? []
                            let title = epData["title"] as? String ?? "Untitled Episode"
                            let epNumber = epData["epNumber"] as? Int ?? -1

                            for code in codes {
                                if let watchedEntry = watchedVideoData.first(where: { $0.id == code }) {
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
                                    allWatchedItems.append(item)
                                }
                            }
                        }
                    }
                }

                group.notify(queue: .main) {
                    self?.watchedHistory = allWatchedItems.sorted {
                        ($0.lastWatchedAt ?? .distantPast) > ($1.lastWatchedAt ?? .distantPast)
                    }
                    print("✅ Loaded \(self?.watchedHistory.count ?? 0) watched items (sorted).")
                }
            }
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
