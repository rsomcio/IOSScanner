//
//  OnboardingTextField.swift
//  Scanner
//
//  Created on 12/29/25.
//

import SwiftUI

/// Rounded text field with icon, focus state, error display, and password toggle
struct OnboardingTextField: View {
    let placeholder: String
    let icon: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .sentences
    var errorMessage: String? = nil

    @State private var isPasswordVisible: Bool = false
    @FocusState private var isFocused: Bool

    private var hasError: Bool {
        errorMessage != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isFocused ? .onboardingPrimary : Color.black.opacity(0.4))
                    .frame(width: 20)

                // Text field
                if isSecure && !isPasswordVisible {
                    SecureField(placeholder, text: $text)
                        .font(.onboardingBody)
                        .foregroundColor(Color.onboardingText)
                        .textContentType(textContentType)
                        .textInputAutocapitalization(autocapitalization)
                        .focused($isFocused)
                } else {
                    TextField(placeholder, text: $text)
                        .font(.onboardingBody)
                        .foregroundColor(Color.onboardingText)
                        .keyboardType(keyboardType)
                        .textContentType(textContentType)
                        .textInputAutocapitalization(autocapitalization)
                        .focused($isFocused)
                }

                // Password toggle button (only for secure fields)
                if isSecure {
                    Button(action: { isPasswordVisible.toggle() }) {
                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.black.opacity(0.4))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        hasError ? Color.onboardingPrimary :
                            (isFocused ? Color.onboardingPrimary.opacity(0.3) : Color.black.opacity(0.1)),
                        lineWidth: hasError ? 2 : 1
                    )
            )
            .cornerRadius(12)

            // Error message
            if let errorMessage = errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                    Text(errorMessage)
                        .font(.onboardingSmall)
                }
                .foregroundColor(.onboardingPrimary)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: hasError)
    }
}

#Preview {
    VStack(spacing: 20) {
        OnboardingTextField(
            placeholder: "John Doe",
            icon: "person.fill",
            text: .constant(""),
            autocapitalization: .words
        )

        OnboardingTextField(
            placeholder: "john@example.com",
            icon: "envelope.fill",
            text: .constant("john@example.com"),
            keyboardType: .emailAddress,
            textContentType: .emailAddress,
            autocapitalization: .never
        )

        OnboardingTextField(
            placeholder: "Password",
            icon: "lock.fill",
            text: .constant("Password123"),
            isSecure: true,
            textContentType: .password,
            autocapitalization: .never
        )

        OnboardingTextField(
            placeholder: "Email",
            icon: "envelope.fill",
            text: .constant("invalid"),
            errorMessage: "Please enter a valid email address"
        )
    }
    .padding()
    .background(Color.onboardingBackground)
}
