//
//  AccountData.swift
//  Scanner
//
//  Created on 12/29/25.
//

import Foundation

/// Temporary struct for account form validation (NOT a SwiftData model)
struct AccountData {
    var fullName: String = ""
    var email: String = ""
    var password: String = ""

    // MARK: - Validation Methods

    /// Validate full name
    /// - Returns: Error message if invalid, nil if valid
    func validateFullName() -> String? {
        let trimmed = fullName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            return "Full name is required"
        }
        guard trimmed.count >= 2 else {
            return "Full name must be at least 2 characters"
        }
        return nil
    }

    /// Validate email address
    /// - Returns: Error message if invalid, nil if valid
    func validateEmail() -> String? {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            return "Email is required"
        }

        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard predicate.evaluate(with: trimmed) else {
            return "Please enter a valid email address"
        }
        return nil
    }

    /// Validate password
    /// - Returns: Error message if invalid, nil if valid
    func validatePassword() -> String? {
        guard !password.isEmpty else {
            return "Password is required"
        }
        guard password.count >= 8 else {
            return "Password must be at least 8 characters"
        }
        guard password.rangeOfCharacter(from: .uppercaseLetters) != nil else {
            return "Password must contain at least 1 uppercase letter"
        }
        guard password.rangeOfCharacter(from: .decimalDigits) != nil else {
            return "Password must contain at least 1 number"
        }
        return nil
    }

    // MARK: - Computed Properties

    /// Check if all fields are valid
    var isValid: Bool {
        validateFullName() == nil &&
        validateEmail() == nil &&
        validatePassword() == nil
    }

    /// Password requirements status
    var passwordRequirements: [PasswordRequirement] {
        [
            PasswordRequirement(
                description: "At least 8 characters",
                isMet: password.count >= 8
            ),
            PasswordRequirement(
                description: "1 uppercase letter",
                isMet: password.rangeOfCharacter(from: .uppercaseLetters) != nil
            ),
            PasswordRequirement(
                description: "1 number",
                isMet: password.rangeOfCharacter(from: .decimalDigits) != nil
            )
        ]
    }
}

// MARK: - Password Requirement Helper

struct PasswordRequirement: Identifiable {
    let id = UUID()
    let description: String
    let isMet: Bool
}
