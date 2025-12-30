//
//  Color+Onboarding.swift
//  Scanner
//
//  Created on 12/29/25.
//

import SwiftUI

extension Color {
    // MARK: - Onboarding Color Palette

    /// Warm terracotta orange - Primary accent color
    static let onboardingTerracotta = Color(hex: "E07856")

    /// Warm beige - Background color
    static let onboardingBeige = Color(hex: "F5E6D3")

    /// Light peach - Secondary accent color
    static let onboardingPeach = Color(hex: "FFDAB9")

    /// Warm gray - Tertiary color
    static let onboardingWarmGray = Color(hex: "D4C4B0")

    /// Dark brown - Text color
    static let onboardingDarkBrown = Color(hex: "8B7355")

    // MARK: - Semantic Colors

    /// Primary color for buttons, accents, and interactive elements
    static let onboardingPrimary = onboardingTerracotta

    /// Background color for onboarding screens
    static let onboardingBackground = onboardingBeige

    /// Secondary color for tags, cards, and subtle highlights
    static let onboardingSecondary = onboardingPeach

    /// Primary text color
    static let onboardingText = onboardingDarkBrown

    // MARK: - Hex Initializer

    /// Initialize a Color from a hex string
    /// - Parameter hex: Hex color string (supports 3, 6, or 8 characters, with or without # prefix)
    ///
    /// Examples:
    /// - `Color(hex: "FFF")` → white
    /// - `Color(hex: "#E07856")` → terracotta
    /// - `Color(hex: "FF0000FF")` → red with full alpha
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b, a: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b, a) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17, 255)
        case 6: // RGB (24-bit)
            (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8: // ARGB (32-bit)
            (r, g, b, a) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF, int >> 24)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
