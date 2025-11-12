//
//  WatchedItem.swift
//  Rakio
//
//  Created by STUDENT on 10/30/25.
//

import Foundation
import FirebaseFirestore

struct WatchedItem: Identifiable {
    var id: String { episode.id ?? UUID().uuidString }
    let series: Series
    let episode: Episode
    let lastWatchedAt: Date?  // 👈 added
}
