//
//  OnboardingBackButton.swift
//  Scanner
//
//  Created on 12/29/25.
//

import SwiftUI

/// Back navigation button with chevron icon
struct OnboardingBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.black)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
    }
}

#Preview {
    OnboardingBackButton {
        print("Back tapped")
    }
    .padding()
    .background(Color.onboardingBackground)
}
