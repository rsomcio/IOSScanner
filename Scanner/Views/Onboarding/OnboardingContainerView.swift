//
//  OnboardingContainerView.swift
//  Scanner
//
//  Created on 12/29/25.
//

import SwiftUI
import SwiftData

/// Root container view that conditionally shows onboarding or dashboard
struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userAccounts: [UserAccount]
    @State private var coordinator = OnboardingCoordinator()

    // User session for tracking current user
    private var userSession = UserSession.shared

    /// Determine which view to show based on app state
    private enum AppState {
        case onboarding      // No users exist, show onboarding
        case profileSwitcher // Users exist but no one logged in
        case dashboard       // User is logged in
    }

    private var currentState: AppState {
        // Check if onboarding just completed
        if coordinator.isOnboardingComplete {
            return .dashboard
        }

        // If no users exist, show onboarding
        if userAccounts.isEmpty {
            return .onboarding
        }

        // Users exist, check if someone is logged in
        if let currentEmail = userSession.currentUserEmail,
           userAccounts.contains(where: { $0.email == currentEmail }) {
            return .dashboard
        }

        // Users exist but no one logged in, show profile switcher
        return .profileSwitcher
    }

    var body: some View {
        Group {
            switch currentState {
            case .dashboard:
                // Show main app dashboard
                ContentView()
                    .transition(.opacity)

            case .profileSwitcher:
                // Show profile switcher (logged off state)
                ProfileSwitcherView(showCancelButton: false)
                    .transition(.opacity)

            case .onboarding:
                // Show onboarding flow (first launch)
                NavigationStack(path: $coordinator.path) {
                    PurposeSelectionView(coordinator: coordinator)
                        .navigationDestination(for: OnboardingRoute.self) { route in
                            switch route {
                            case .purpose:
                                PurposeSelectionView(coordinator: coordinator)
                            case .account:
                                AccountCreationView(coordinator: coordinator)
                            }
                        }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentState)
    }
}

#Preview("First Launch") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: UserAccount.self, UserPurpose.self, SavedReceipt.self, SavedReceiptItem.self,
        configurations: config
    )

    return OnboardingContainerView()
        .modelContainer(container)
}

#Preview("Returning User") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: UserAccount.self, UserPurpose.self, SavedReceipt.self, SavedReceiptItem.self,
        configurations: config
    )

    // Create existing user
    let user = UserAccount(fullName: "Jane Doe", email: "jane@example.com", passwordHash: "hash")
    let purpose = UserPurpose(from: .personalBudgeting)
    purpose.user = user
    user.purposes.append(purpose)
    container.mainContext.insert(user)

    // Create sample receipt
    let receipt = SavedReceipt(
        storeName: "Whole Foods",
        date: "2025-12-29",
        items: [],
        subtotal: 45.23,
        tax: 3.62,
        total: 48.85
    )
    container.mainContext.insert(receipt)

    // Set current user in session
    UserSession.shared.switchToUser(email: "jane@example.com")

    return OnboardingContainerView()
        .modelContainer(container)
}

#Preview("Logged Off State") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: UserAccount.self, UserPurpose.self, SavedReceipt.self, SavedReceiptItem.self,
        configurations: config
    )

    // Create multiple users
    let user1 = UserAccount(
        fullName: "Jane Doe",
        email: "jane@example.com",
        passwordHash: UserAccount.hashPassword("Password123")
    )
    let user2 = UserAccount(
        fullName: "John Smith",
        email: "john@example.com",
        passwordHash: UserAccount.hashPassword("Password123")
    )
    container.mainContext.insert(user1)
    container.mainContext.insert(user2)

    // Clear session (logged off state)
    UserSession.shared.clearSession()

    return OnboardingContainerView()
        .modelContainer(container)
}
