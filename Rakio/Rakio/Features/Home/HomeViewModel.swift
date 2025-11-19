//
//  HomeViewModel.swift
//

import Foundation
import SwiftUI

@MainActor

class HomeViewModel: ObservableObject {
    @Published var shows: [Series] = []
    @Published var novels: [Novel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isHeroVideoPlaying = false

    private let novelService = NovelService()
    private let seriesService = SeriesService()

    func loadHomeData() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            print("Starting to load home data...")
            async let fetchedShows = seriesService.fetchSeriesOnly()
            async let fetchedNovels = novelService.fetchAllNovels()

            let showsResult = try await fetchedShows
            let novelsResult = try await fetchedNovels

            print("Series fetched count: \(showsResult.count)")
            print("Novels fetched count: \(novelsResult.count)")

            self.shows = showsResult
            self.novels = novelsResult

        } catch {
            errorMessage = "Failed to load home data: \(error.localizedDescription)"
            print("Error loading home data: \(error.localizedDescription)")
        }

        isLoading = false
    }

    func refresh() {
        shows = []
        novels = []

        Task {
            await loadHomeData()
        }
    }
}

