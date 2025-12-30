//
//  OnboardingState.swift
//  Scanner
//
//  Created on 12/29/25.
//

import Foundation

// MARK: - Navigation Routes

/// Routes for onboarding navigation flow
enum OnboardingRoute: Hashable {
    case purpose
    case account
}

// MARK: - App Purpose

/// User's purposes for using the app
enum AppPurpose: String, CaseIterable, Codable {
    case personalBudgeting = "Personal budgeting"
    case familyFinance = "Family finance"
    case businessExpenses = "Business expenses"
    case savingsGoals = "Savings goals"
    case other = "Other"

    /// SF Symbol icon for each purpose
    var icon: String {
        switch self {
        case .personalBudgeting:
            return "chart.bar.fill"
        case .familyFinance:
            return "person.3.fill"
        case .businessExpenses:
            return "briefcase.fill"
        case .savingsGoals:
            return "dollarsign.circle.fill"
        case .other:
            return "ellipsis.circle.fill"
        }
    }
}
