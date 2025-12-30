//
//  ProfileView.swift
//  Scanner
//
//  Created on 12/29/25.
//

import SwiftUI
import SwiftData

/// User profile view displaying account information and purposes
struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    let user: UserAccount?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Profile Header
                    VStack(spacing: 16) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(Color.onboardingSecondary)
                                .frame(width: 100, height: 100)

                            Text(initials)
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(Color.onboardingPrimary)
                        }

                        VStack(spacing: 8) {
                            Text(user?.fullName ?? "User")
                                .font(.onboardingTitle)
                                .foregroundColor(Color.onboardingText)

                            Text(user?.email ?? "")
                                .font(.onboardingBody)
                                .foregroundColor(Color.black.opacity(0.6))
                        }
                    }
                    .padding(.top, 40)

                    // Account Information
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Account Information")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.onboardingText)
                            .padding(.horizontal, 16)

                        VStack(spacing: 16) {
                            ProfileInfoRow(
                                icon: "envelope.fill",
                                title: "Email",
                                value: user?.email ?? "N/A"
                            )

                            Divider()
                                .padding(.horizontal, 16)

                            ProfileInfoRow(
                                icon: "calendar",
                                title: "Member Since",
                                value: formatDate(user?.createdAt)
                            )
                        }
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    }
                    .padding(.horizontal, 24)

                    // Your Goals
                    if let user = user, !user.purposes.isEmpty {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Your Goals")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.onboardingText)
                                .padding(.horizontal, 16)

                            FlowLayout(spacing: 12) {
                                ForEach(user.purposes, id: \.id) { userPurpose in
                                    if let purpose = userPurpose.purpose {
                                        HStack(spacing: 8) {
                                            Image(systemName: purpose.icon)
                                                .font(.system(size: 14))
                                            Text(purpose.rawValue)
                                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(Color.onboardingSecondary)
                                        .foregroundColor(Color.onboardingPrimary)
                                        .cornerRadius(20)
                                    }

                                    // Show custom purpose if it exists
                                    if userPurpose.purpose?.rawValue == "Other",
                                       let customText = userPurpose.customPurpose,
                                       !customText.isEmpty {
                                        Text("• \(customText)")
                                            .font(.system(size: 13, weight: .regular, design: .rounded))
                                            .foregroundColor(Color.black.opacity(0.6))
                                            .padding(.horizontal, 16)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        }
                        .padding(.horizontal, 24)
                    }

                    Spacer(minLength: 40)
                }
            }
            .background(Color.onboardingBackground.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.onboardingPrimary)
                }
            }
        }
    }

    // MARK: - Helper Properties

    private var initials: String {
        guard let name = user?.fullName else { return "?" }
        let components = name.split(separator: " ")
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        } else if let first = components.first {
            return String(first.prefix(1)).uppercased()
        }
        return "?"
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct ProfileInfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color.onboardingPrimary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Color.black.opacity(0.6))

                Text(value)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(Color.onboardingText)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Previews

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: UserAccount.self, UserPurpose.self,
        configurations: config
    )

    let user = UserAccount(fullName: "John Doe", email: "john@example.com", passwordHash: "hash")
    let purpose1 = UserPurpose(from: .personalBudgeting)
    let purpose2 = UserPurpose(from: .savingsGoals)
    let purpose3 = UserPurpose(from: .other, customPurpose: "Track business expenses for tax purposes")

    purpose1.user = user
    purpose2.user = user
    purpose3.user = user
    user.purposes = [purpose1, purpose2, purpose3]

    container.mainContext.insert(user)

    return ProfileView(user: user)
        .modelContainer(container)
}
