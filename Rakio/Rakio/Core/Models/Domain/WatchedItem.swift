//
//  WatchedItem.swift
//  Rakio
//
//  Created by STUDENT on 10/30/25.
//

import Foundation
import FirebaseFirestore

struct WatchedItem: Identifiable {
    var id: String { watchedVideoID }
    
    let series: Series
    let episode: Episode
    let lastWatchedAt: Date?
    let watchedVideoID: String
    let source: VideoSource
    let progress: Double
}
