import SwiftUI

extension Color {
    /// Initializes a Color from a hex string (e.g., "FF00CC", "#1A2B3CFF").
    /// Supports 6-digit (RRGGBB) and 8-digit (AARRGGBB) formats.
    init(hex: String) {
        let cleanedHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        
        // Scan the hex value into the UInt64
        Scanner(string: cleanedHex).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        
        // Determine the components based on the hex string length
        switch cleanedHex.count {
        case 6: // RRGGBB (defaults alpha to FF)
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8: // AARRGGBB
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            // Fallback for invalid format (Opaque Black)
            print("⚠️ Invalid hex string: \(hex). Defaulting to opaque black.")
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
