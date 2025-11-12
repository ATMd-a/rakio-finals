//import Foundation
//
//
//
//final class MyListManager {
//    static let shared = MyListManager()
//    private let favoritesKey = "savedSeries"
//
//    private init() {}
//
//    /// Adds a series to saved list if not already present
//    func add(_ series: Series) {
//        var current = fetchAll()
//        if current.contains(where: { $0.id == series.id }) {
//            print("Series already saved: \(series.title)")
//            return
//        }
//        print("Saving series: \(series.title)")
//        current.append(series)
//        saveAll(current)
//    }
//
//
//    /// Removes a series from saved list
//    func remove(_ series: Series) {
//        var current = fetchAll()
//        current.removeAll(where: { $0.id == series.id })
//        saveAll(current)
//    }
//
//    /// Checks if a series is saved locally
//    func isSaved(_ series: Series) -> Bool {
//        let current = fetchAll()
//        return current.contains(where: { $0.id == series.id })
//    }
//
//    /// Fetches all saved series from UserDefaults
//    func fetchAll() -> [Series] {
//        guard
//            let data = UserDefaults.standard.data(forKey: favoritesKey),
//            let saved = try? JSONDecoder().decode([Series].self, from: data)
//        else {
//            return []
//        }
//        return saved
//    }
//
//    /// Saves the full list to UserDefaults
//    private func saveAll(_ series: [Series]) {
//        do {
//            let data = try JSONEncoder().encode(series)
//            UserDefaults.standard.set(data, forKey: favoritesKey)
//        } catch {
//            print("Failed to encode saved series: \(error)")
//        }
//    }
//}
