// NovelViewModel.swift

import Foundation
import SwiftUI

@MainActor
class NovelViewModel: ObservableObject {
    @Published var novels: [Novel] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    private let novelService = NovelService()
    
    func loadNovels() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            self.novels = try await novelService.fetchAllNovels()
        } catch {
            self.errorMessage = "Failed to fetch novels: \(error.localizedDescription)"
            print("❌ Error in loadNovels: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func refresh() async { 
        novels = []
        await loadNovels()
    }
}
