//
//  SelectionTag.swift
//  Scanner
//
//  Created on 12/29/25.
//

import SwiftUI

/// Pill-shaped selection tag with icon and text
struct SelectionTag: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isPressed: Bool = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(title)
                    .font(.onboardingBody)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? Color.onboardingPrimary : Color.onboardingSecondary)
            .foregroundColor(isSelected ? .white : Color.onboardingPrimary)
            .cornerRadius(24)
        }
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

#Preview {
    FlowLayout(spacing: 12) {
        SelectionTag(
            title: "Personal budgeting",
            icon: "chart.bar.fill",
            isSelected: true
        ) {
            print("Tapped")
        }

        SelectionTag(
            title: "Family finance",
            icon: "person.3.fill",
            isSelected: false
        ) {
            print("Tapped")
        }

        SelectionTag(
            title: "Business expenses",
            icon: "briefcase.fill",
            isSelected: false
        ) {
            print("Tapped")
        }

        SelectionTag(
            title: "Savings goals",
            icon: "dollarsign.circle.fill",
            isSelected: true
        ) {
            print("Tapped")
        }
    }
    .padding()
    .background(Color.onboardingBackground)
}
