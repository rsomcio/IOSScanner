//
//  PurposeSelectionView.swift
//  Scanner
//
//  Created on 12/29/25.
//

import SwiftUI

/// Step 1: Purpose selection screen with multi-select tags
struct PurposeSelectionView: View {
    @Bindable var coordinator: OnboardingCoordinator
    @FocusState private var isCustomFieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Title and subtitle
                VStack(alignment: .leading, spacing: 12) {
                    Text("What are you\nusing the app\nfor?")
                        .font(.onboardingTitle)
                        .foregroundColor(.black)
                        .lineSpacing(2)

                    Text("Select all options that describe your goals")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color.black.opacity(0.6))
                        .lineSpacing(2)
                }
                .padding(.top, 40)

                // Purpose tags in flow layout
                FlowLayout(spacing: 12) {
                    ForEach(AppPurpose.allCases, id: \.self) { purpose in
                        SelectionTag(
                            title: purpose.rawValue,
                            icon: purpose.icon,
                            isSelected: coordinator.selectedPurposes.contains(purpose)
                        ) {
                            coordinator.togglePurpose(purpose)
                        }
                    }
                }

                // Custom purpose text field (conditional on "Other" selection)
                if coordinator.selectedPurposes.contains(.other) {
                    OnboardingTextField(
                        placeholder: "Tell us more about your purpose",
                        icon: "text.bubble.fill",
                        text: $coordinator.customPurpose,
                        autocapitalization: .sentences
                    )
                    .focused($isCustomFieldFocused)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()

                // Continue button
                OnboardingButton(
                    title: "Continue",
                    isEnabled: coordinator.canProceedFromPurposeSelection()
                ) {
                    coordinator.navigateTo(.account)
                }
                .padding(.bottom, 34)
            }
            .padding(.horizontal, 24)
        }
        .background(Color.onboardingBackground.ignoresSafeArea())
        .navigationBarHidden(true)
    }
}

#Preview {
    let coordinator = OnboardingCoordinator()
    coordinator.selectedPurposes = [.personalBudgeting, .savingsGoals]

    return PurposeSelectionView(coordinator: coordinator)
}
