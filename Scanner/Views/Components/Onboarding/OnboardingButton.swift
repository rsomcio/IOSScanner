//
//  OnboardingButton.swift
//  Scanner
//
//  Created on 12/29/25.
//

import SwiftUI

/// Primary button component for onboarding flow
struct OnboardingButton: View {
    let title: String
    var isEnabled: Bool = true
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(title)
                        .font(.onboardingButtonText)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                isEnabled ? Color.onboardingText : Color.black.opacity(0.3)
            )
            .cornerRadius(16)
        }
        .disabled(!isEnabled || isLoading)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

#Preview("Enabled") {
    VStack(spacing: 20) {
        OnboardingButton(title: "Continue", isEnabled: true) {
            print("Tapped")
        }
        OnboardingButton(title: "Continue", isEnabled: false) {
            print("Tapped")
        }
        OnboardingButton(title: "Creating Account...", isEnabled: true, isLoading: true) {
            print("Tapped")
        }
    }
    .padding()
    .background(Color.onboardingBackground)
}
