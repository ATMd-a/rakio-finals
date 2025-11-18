//
//  Colors.swift
//  Rakio
//
//  Created by STUDENT on 11/18/25.
//

import SwiftUI

extension Color {
    // MARK: - Brand Colors
    
    /// Primary brand color - Teal/Blue (#437C90)
    static let rakioPrimary = Color(hex: "437C90")
    
    /// Background color - Dark Brown (#14110F)
    static let rakioBackground = Color(hex: "14110F")
    
    /// Secondary/Accent color - Light Beige (#EEEDD3)
    static let rakioSecondary = Color(hex: "EEEDD3")
    
    /// Alternative background - Very Dark (#0F0F0F)
    static let rakioDarkBackground = Color(hex: "0F0F0F")
    
    /// Alternative background - Slightly lighter (#1C1917)
    static let rakioLightBackground = Color(hex: "1C1917")
    
    // MARK: - Semantic Colors
    
    /// Text color for primary content
    static let rakioTextPrimary = Color.white
    
    /// Text color for secondary content
    static let rakioTextSecondary = Color.white.opacity(0.7)
    
    /// Text color for tertiary content
    static let rakioTextTertiary = Color.gray
    
    /// Success color
    static let rakioSuccess = Color.green
    
    /// Error color
    static let rakioError = Color.red
    
    /// Warning color
    static let rakioWarning = Color.yellow
}
