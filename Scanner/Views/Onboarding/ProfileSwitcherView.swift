//
//  ProfileSwitcherView.swift
//  Scanner
//
//  Created on 12/29/25.
//

import SwiftUI
import SwiftData

/// View for switching between user profiles with password verification
struct ProfileSwitcherView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allUsers: [UserAccount]

    /// When true, shows a cancel button (used when presented as sheet)
    var showCancelButton: Bool = true

    @State private var selectedUser: UserAccount?
    @State private var passwordInput: String = ""
    @State private var errorMessage: String?
    @State private var showingCreateProfile = false
    @State private var onboardingCoordinator = OnboardingCoordinator()
    @FocusState private var isPasswordFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.onboardingPrimary)

                        Text("Switch Profile")
                            .font(.onboardingTitle)
                            .foregroundColor(.onboardingText)

                        Text("Select a profile and enter your password")
                            .font(.onboardingBody)
                            .foregroundColor(Color.black.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)

                    // Profile List
                    VStack(spacing: 16) {
                        ForEach(allUsers, id: \.email) { user in
                            ProfileCard(
                                user: user,
                                isSelected: selectedUser?.email == user.email,
                                isCurrent: UserSession.shared.currentUserEmail == user.email,
                                onTap: {
                                    selectedUser = user
                                    errorMessage = nil
                                    // Focus password field when selecting a different user
                                    if UserSession.shared.currentUserEmail != user.email {
                                        isPasswordFocused = true
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)

                    // Password Input (shown only when selecting a different user)
                    if let selected = selectedUser,
                       UserSession.shared.currentUserEmail != selected.email {
                        VStack(spacing: 16) {
                            OnboardingTextField(
                                placeholder: "Enter password",
                                icon: "lock.fill",
                                text: $passwordInput,
                                isSecure: true,
                                textContentType: .password,
                                autocapitalization: .never,
                                errorMessage: errorMessage
                            )
                            .focused($isPasswordFocused)

                            OnboardingButton(
                                title: "Switch Profile",
                                isEnabled: !passwordInput.isEmpty,
                                isLoading: false,
                                action: switchProfile
                            )
                        }
                        .padding(.horizontal, 24)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Create New Profile Button
                    Button(action: { showingCreateProfile = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                            Text("Create New Profile")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.onboardingPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.onboardingSecondary)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    Spacer(minLength: 40)
                }
            }
            .background(Color.onboardingBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showCancelButton {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.onboardingPrimary)
                    }
                }
            }
            .sheet(isPresented: $showingCreateProfile) {
                // Show onboarding flow for creating a new profile
                NavigationStack(path: $onboardingCoordinator.path) {
                    PurposeSelectionView(coordinator: onboardingCoordinator)
                        .navigationDestination(for: OnboardingRoute.self) { route in
                            switch route {
                            case .purpose:
                                PurposeSelectionView(coordinator: onboardingCoordinator)
                            case .account:
                                AccountCreationView(coordinator: onboardingCoordinator)
                            }
                        }
                }
                .onChange(of: onboardingCoordinator.isOnboardingComplete) { _, isComplete in
                    if isComplete {
                        // Onboarding completed, dismiss sheet
                        showingCreateProfile = false

                        // Only dismiss ProfileSwitcherView if shown as a sheet
                        if showCancelButton {
                            dismiss()
                        }
                        // Otherwise, OnboardingContainerView will automatically update to show ContentView
                    }
                }
                .onDisappear {
                    // Reset coordinator when sheet is dismissed
                    onboardingCoordinator = OnboardingCoordinator()
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedUser?.email)
        .animation(.easeInOut(duration: 0.2), value: errorMessage)
    }

    // MARK: - Helper Methods

    private func switchProfile() {
        guard let selected = selectedUser else { return }

        // Verify password
        guard selected.verifyPassword(passwordInput) else {
            errorMessage = "Incorrect password"
            return
        }

        // Switch to the selected user
        UserSession.shared.switchToUser(email: selected.email)

        // Clear password
        passwordInput = ""
        errorMessage = nil

        // Only dismiss if shown as a sheet (has cancel button)
        if showCancelButton {
            dismiss()
        }
        // Otherwise, OnboardingContainerView will automatically update to show ContentView
    }
}

// MARK: - Supporting Views

struct ProfileCard: View {
    let user: UserAccount
    let isSelected: Bool
    let isCurrent: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.onboardingPrimary : Color.onboardingSecondary)
                        .frame(width: 56, height: 56)

                    Text(initials)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? .white : .onboardingPrimary)
                }

                // User Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(user.fullName)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.onboardingText)

                        if isCurrent {
                            Text("Current")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.onboardingPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.onboardingSecondary)
                                .cornerRadius(8)
                        }
                    }

                    Text(user.email)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(Color.black.opacity(0.6))
                }

                Spacer()

                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.onboardingPrimary)
                }
            }
            .padding(16)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.onboardingPrimary : Color.black.opacity(0.1),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .cornerRadius(16)
            .shadow(color: .black.opacity(isSelected ? 0.1 : 0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.0 : 0.98)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    private var initials: String {
        let components = user.fullName.split(separator: " ")
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        } else if let first = components.first {
            return String(first.prefix(1)).uppercased()
        }
        return "?"
    }
}

// MARK: - Previews

#Preview("Empty State") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: UserAccount.self, UserPurpose.self,
        configurations: config
    )

    return ProfileSwitcherView()
        .modelContainer(container)
}

#Preview("Multiple Profiles") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: UserAccount.self, UserPurpose.self,
        configurations: config
    )

    // Create sample users
    let user1 = UserAccount(
        fullName: "John Doe",
        email: "john@example.com",
        passwordHash: UserAccount.hashPassword("Password123")
    )
    let user2 = UserAccount(
        fullName: "Jane Smith",
        email: "jane@example.com",
        passwordHash: UserAccount.hashPassword("Password123")
    )
    let user3 = UserAccount(
        fullName: "Bob Wilson",
        email: "bob@example.com",
        passwordHash: UserAccount.hashPassword("Password123")
    )

    container.mainContext.insert(user1)
    container.mainContext.insert(user2)
    container.mainContext.insert(user3)

    // Set current user
    UserSession.shared.currentUserEmail = "john@example.com"

    return ProfileSwitcherView()
        .modelContainer(container)
}
