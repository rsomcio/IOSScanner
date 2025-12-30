//
//  OnboardingCoordinator.swift
//  Scanner
//
//  Created on 12/29/25.
//

import SwiftUI
import SwiftData

/// Central coordinator for onboarding flow navigation and state management
@Observable
final class OnboardingCoordinator {
    // MARK: - Navigation

    /// Navigation path for multi-step flow
    var path: [OnboardingRoute] = []

    // MARK: - Step 1: Purpose Selection State

    /// Selected purposes (multi-select)
    var selectedPurposes: Set<AppPurpose> = []

    /// Custom purpose text (when "Other" is selected)
    var customPurpose: String = ""

    // MARK: - Step 2: Account Creation State

    /// Account form data with validation
    var accountData = AccountData()

    /// Track if user has attempted to submit (delays error display for better UX)
    var hasAttemptedSubmit: Bool = false

    // MARK: - Global State

    /// Loading indicator during save operation
    var isLoading: Bool = false

    /// Error message to display to user
    var errorMessage: String?

    /// Flag indicating onboarding completion (triggers transition to dashboard)
    var isOnboardingComplete: Bool = false

    // MARK: - Navigation Methods

    /// Navigate to a specific route
    func navigateTo(_ route: OnboardingRoute) {
        path.append(route)
    }

    /// Navigate back to previous screen
    func navigateBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    // MARK: - Validation Methods

    /// Check if user can proceed from purpose selection
    func canProceedFromPurposeSelection() -> Bool {
        // Must select at least one purpose
        guard !selectedPurposes.isEmpty else {
            return false
        }

        // If "Other" is selected, custom text is required
        if selectedPurposes.contains(.other) {
            return !customPurpose.trimmingCharacters(in: .whitespaces).isEmpty
        }

        return true
    }

    /// Toggle purpose selection (for multi-select)
    func togglePurpose(_ purpose: AppPurpose) {
        if selectedPurposes.contains(purpose) {
            selectedPurposes.remove(purpose)
        } else {
            selectedPurposes.insert(purpose)
        }
    }

    // MARK: - Onboarding Completion

    /// Complete onboarding by saving user account and purposes to SwiftData
    @MainActor
    func completeOnboarding(modelContext: ModelContext) async {
        guard accountData.isValid else {
            errorMessage = "Please fix all validation errors"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // Simulate API call delay (1.5 seconds)
            try await Task.sleep(nanoseconds: 1_500_000_000)

            // Hash password
            let passwordHash = UserAccount.hashPassword(accountData.password)

            // Create UserAccount
            let userAccount = UserAccount(
                fullName: accountData.fullName,
                email: accountData.email.trimmingCharacters(in: .whitespaces),
                passwordHash: passwordHash
            )

            // Create UserPurpose records for each selected purpose
            for purpose in selectedPurposes {
                let userPurpose = UserPurpose(
                    from: purpose,
                    customPurpose: purpose == .other ? customPurpose : nil
                )
                userPurpose.user = userAccount
                userAccount.purposes.append(userPurpose)
            }

            // Save to SwiftData
            modelContext.insert(userAccount)
            try modelContext.save()

            // Set current user in session
            UserSession.shared.switchToUser(email: userAccount.email)

            // Log success
            print("✅ Onboarding completed successfully")
            print("   User: \(userAccount.fullName) (\(userAccount.email))")
            print("   Purposes: \(selectedPurposes.map { $0.rawValue }.joined(separator: ", "))")

            // Mark onboarding as complete (triggers transition to dashboard)
            isOnboardingComplete = true

        } catch {
            // Handle errors (e.g., duplicate email due to unique constraint)
            isLoading = false

            if error.localizedDescription.contains("unique") {
                errorMessage = "An account with this email already exists"
            } else {
                errorMessage = "Failed to create account: \(error.localizedDescription)"
            }

            print("❌ Onboarding failed: \(error)")
        }

        isLoading = false
    }
}
