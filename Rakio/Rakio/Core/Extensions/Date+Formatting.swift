//
//  Date+Formatting.swift
//  Rakio
//
//  Created by STUDENT on 11/18/25.
//

import SwiftUI


extension Date {
    func toShortDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: self)
    }
    
    func toYear() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: self)
    }
}
