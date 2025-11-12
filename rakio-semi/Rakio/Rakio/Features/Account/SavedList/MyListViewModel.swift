//import SwiftUI
//import FirebaseAuth
//
//@MainActor
//class MyListViewModel: ObservableObject {
//    @Published var favoriteSeries: [Series] = []
//    @Published var isLoading = false
//    @Published var errorMessage: String? = nil
//    @Published var isUserLoggedIn = false
//
//    private let userService = UserService.shared
//
//    init() {
//        checkUserStatus()
//    }
//
//    func checkUserStatus() {
//        isUserLoggedIn = Auth.auth().currentUser != nil
//    }
//
//    func loadFavorites() async {
//        print("⏳ MyListViewModel.loadFavorites called")
//        checkUserStatus()
//        print("isUserLoggedIn =", isUserLoggedIn)
//        guard isUserLoggedIn else {
//            print("User not logged in — no favorites")
//            favoriteSeries = []
//            return
//        }
//
//        isLoading = true
//        do {
//            if let user = try await userService.fetchCurrentUser() {
//                print("User fetched, favorites IDs:", user.favorites)
//                let fetched = try await userService.fetchFavoriteSeries(for: user)
//                print("Fetched favorites: \(fetched.count) series")
//                favoriteSeries = fetched.sorted { $0.title < $1.title }
//            } else {
//                print("fetchCurrentUser returned nil")
//                errorMessage = "User not found."
//            }
//        } catch {
//            print("Error loading favorites in MyListViewModel:", error)
//            errorMessage = "Failed to load favorite series: \(error.localizedDescription)"
//        }
//        isLoading = false
//    }
//
//
//    func removeSeries(_ series: Series) async {
//        guard isUserLoggedIn, let seriesId = series.id else { return }
//        // optimistic local update:
//        self.favoriteSeries.removeAll { $0.id == seriesId }
//        do {
//            try await userService.removeSeriesFromFavorites(seriesId: seriesId)
//        } catch {
//            // rollback on error (simple approach: reload favorites)
//            await loadFavorites()
//            errorMessage = "Failed to remove favorite: \(error.localizedDescription)"
//        }
//    }
//
//}
