//
//  AccountCreationView.swift
//  Scanner
//
//  Created on 12/29/25.
//

import SwiftUI
import SwiftData

/// Step 2: Account creation screen with form validation
struct AccountCreationView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var coordinator: OnboardingCoordinator

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Title and subtitle
                VStack(alignment: .leading, spacing: 12) {
                    Text("Create your\naccount")
                        .font(.onboardingTitle)
                        .foregroundColor(.black)
                        .lineSpacing(2)

                    Text("Just a few details to get you started")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color.black.opacity(0.6))
                        .lineSpacing(2)
                }
                .padding(.top, 40)

                // Form fields
                VStack(spacing: 16) {
                    // Full name field
                    OnboardingTextField(
                        placeholder: "Full Name",
                        icon: "person.fill",
                        text: $coordinator.accountData.fullName,
                        textContentType: .name,
                        autocapitalization: .words,
                        errorMessage: coordinator.hasAttemptedSubmit ?
                            coordinator.accountData.validateFullName() : nil
                    )

                    // Email field
                    OnboardingTextField(
                        placeholder: "Email",
                        icon: "envelope.fill",
                        text: $coordinator.accountData.email,
                        keyboardType: .emailAddress,
                        textContentType: .emailAddress,
                        autocapitalization: .never,
                        errorMessage: coordinator.hasAttemptedSubmit ?
                            coordinator.accountData.validateEmail() : nil
                    )

                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        OnboardingTextField(
                            placeholder: "Password",
                            icon: "lock.fill",
                            text: $coordinator.accountData.password,
                            isSecure: true,
                            textContentType: .newPassword,
                            autocapitalization: .never,
                            errorMessage: coordinator.hasAttemptedSubmit ?
                                coordinator.accountData.validatePassword() : nil
                        )

                        // Password requirements (only show when password is incomplete)
                        if !coordinator.accountData.password.isEmpty &&
                           coordinator.accountData.validatePassword() != nil {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(coordinator.accountData.passwordRequirements) { requirement in
                                    HStack(spacing: 6) {
                                        Image(systemName: requirement.isMet ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 10))
                                            .foregroundColor(requirement.isMet ? .green : Color.black.opacity(0.3))
                                        Text(requirement.description)
                                            .font(.system(size: 11, weight: .regular))
                                            .foregroundColor(Color.black.opacity(0.5))
                                    }
                                }
                            }
                            .padding(.leading, 4)
                        }
                    }
                }

                Spacer(minLength: 20)

                // Error message from coordinator (e.g., duplicate email)
                if let errorMessage = coordinator.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14))
                        Text(errorMessage)
                            .font(.onboardingBody)
                    }
                    .foregroundColor(.onboardingPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.onboardingPrimary.opacity(0.1))
                    .cornerRadius(12)
                }

                // Create Account button
                OnboardingButton(
                    title: "Create Account",
                    isEnabled: !coordinator.isLoading,
                    isLoading: coordinator.isLoading
                ) {
                    coordinator.hasAttemptedSubmit = true
                    if coordinator.accountData.isValid {
                        Task {
                            await coordinator.completeOnboarding(modelContext: modelContext)
                        }
                    }
                }
                .padding(.bottom, 34)
            }
            .padding(.horizontal, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.onboardingBackground.ignoresSafeArea())
        .navigationBarHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                OnboardingBackButton {
                    coordinator.navigateBack()
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: UserAccount.self, UserPurpose.self,
        configurations: config
    )

    let coordinator = OnboardingCoordinator()
    coordinator.accountData.fullName = "John Doe"
    coordinator.accountData.email = "john@example.com"
    coordinator.hasAttemptedSubmit = true

    return NavigationStack {
        AccountCreationView(coordinator: coordinator)
    }
    .modelContainer(container)
}
