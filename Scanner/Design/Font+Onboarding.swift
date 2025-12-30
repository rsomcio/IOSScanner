//
//  Font+Onboarding.swift
//  Scanner
//
//  Created on 12/29/25.
//

import SwiftUI

extension Font {
    // MARK: - Onboarding Typography

    /// Large title for main headings (32pt, bold, rounded)
    static let onboardingTitle = Font.system(size: 32, weight: .bold, design: .rounded)

    /// Section headings (24pt, semibold, rounded)
    static let onboardingHeadline = Font.system(size: 24, weight: .semibold, design: .rounded)

    /// Body text and form labels (16pt, regular, rounded)
    static let onboardingBody = Font.system(size: 16, weight: .regular, design: .rounded)

    /// Button text (18pt, semibold, rounded)
    static let onboardingButtonText = Font.system(size: 18, weight: .semibold, design: .rounded)

    /// Small captions and hints (13pt, regular, rounded)
    static let onboardingCaption = Font.system(size: 13, weight: .regular, design: .rounded)

    /// Extra small text for validation messages (11pt, medium, rounded)
    static let onboardingSmall = Font.system(size: 11, weight: .medium, design: .rounded)
}
