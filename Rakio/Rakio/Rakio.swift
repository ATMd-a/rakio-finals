//
//  Test3App.swift
//  Test3
//
//  Created by STUDENT on 8/27/25.
//

import SwiftUI
import Firebase

@main
struct Rakio: App {
    
    
    init(){
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

//class AppDelegate: NSObject, UIApplicationDelegate {
//  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
//
//    return true
//  }
//}


//notes: create a PDF to text file
//
//Series Player Refactor Plan – Summary
//
//Current State (Before Changes):
//
//Firestore structure:
//
//shows (collection)
//
//episodes (subcollection)
//
//Each episode document has: title, code (video URL), epNumber.
//
//Series model includes isYT to indicate if the series is YouTube or not.
//
//Episodes and watch history/favorites are platform-specific.
//
//Planned Changes:
//
//Firestore Structure Changes:
//
//shows (collection)
//
//player1 (subcollection for YouTube episodes)
//
//player2 (subcollection for Dailymotion episodes)
//
//Each subcollection stores episodes with the same schema: title, code, epNumber.
//
//App Logic Changes:
//
//Remove isYT from the Series model.
//
//Introduce a player selection toggle in the UI (YouTube / Dailymotion).
//
//Fetch episodes dynamically based on the selected player subcollection.
//
//Episode list is shared across players: episodes with the same title correspond to each other.
//
//Watch History & Favorites Changes:
//
//Watch marks are now episode-based, not platform-based.
//
//Use episode.title as the unique identifier for marking watched status.
//
//If an episode is marked as watched on YouTube, it is automatically marked on Dailymotion, and vice versa.
//
//Favorites remain series-based.
//
//UI/UX Changes:
//
//Display watched/favorited status consistently across players.
//
//Allow dynamic switching between players without losing state.
//
//Maintain existing features: episode selection, trailer, and related novel section.
//
//Benefits of Changes:
//
//Users can freely choose which platform to watch from.
//
//Watch history is unified and consistent.
//
//Reduces redundancy and simplifies backend management.
//
//Next Steps / Implementation Plan:
//
//Update Firestore subcollections: player1 and player2.
//
//Update SeriesDetailViewModel to fetch episodes from the selected player subcollection.
//
//Update SeriesDetailView to add player toggle UI.
//
//Update watch history functions to use episode.title as the key.
//
//Test switching players to ensure watch marks are consistent.
