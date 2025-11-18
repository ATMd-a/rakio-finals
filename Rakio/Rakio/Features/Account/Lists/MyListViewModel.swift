import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class MyListViewModel: ObservableObject {
    @Published var favorites: [Series] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    func fetchFavorites() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "You're not logged in."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let userDocRef = db.collection("users").document(userId)
            let userSnapshot = try await userDocRef.getDocument()

            guard let data = userSnapshot.data(),
                  let favoriteIds = data["favorites"] as? [String] else {
                self.favorites = []
                self.isLoading = false
                return
            }

            var fetchedSeries: [Series] = []

            for seriesId in favoriteIds {
                let seriesDoc = try await db.collection("shows").document(seriesId).getDocument()
                if seriesDoc.exists {
                    var series = try seriesDoc.data(as: Series.self)
                    series.id = seriesDoc.documentID
                    fetchedSeries.append(series)
                }
            }

            self.favorites = fetchedSeries
        } catch {
            print("❌ Error fetching favorites: \(error)")
            errorMessage = "Failed to load favorites."
        }

        isLoading = false
    }
}
