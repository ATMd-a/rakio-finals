//
//  WatchedItem.swift
//  Rakio
//
//  Created by STUDENT on 10/30/25.
//

import Foundation
import FirebaseFirestore

struct WatchedItem: Identifiable {
    // We can use the video ID as the unique identifier
    var id: String { watchedVideoID }
    
    let series: Series
    let episode: Episode
    let lastWatchedAt: Date?
    
    // 💡 NEW REQUIRED PROPERTIES
    let watchedVideoID: String // The specific YouTube/Dailymotion ID that was watched
    let source: VideoSource // The platform source of the video ID
    
    // ✅ FIX: ADD THE MISSING PROPERTY
    let progress: Double
}
