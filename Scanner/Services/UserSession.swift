//
//  UserSession.swift
//  Scanner
//
//  Created on 12/29/25.
//

import Foundation
import SwiftUI

/// Manages the currently active user session across the app
@Observable
final class UserSession {
    /// Shared singleton instance
    static let shared = UserSession()

    /// Currently active user's email (persisted to UserDefaults)
    var currentUserEmail: String? {
        didSet {
            if let email = currentUserEmail {
                UserDefaults.standard.set(email, forKey: "currentUserEmail")
            } else {
                UserDefaults.standard.removeObject(forKey: "currentUserEmail")
            }
        }
    }

    private init() {
        // Load saved user email on init
        self.currentUserEmail = UserDefaults.standard.string(forKey: "currentUserEmail")
    }

    /// Switch to a different user profile
    func switchToUser(email: String) {
        currentUserEmail = email
    }

    /// Clear current session (logout)
    func clearSession() {
        currentUserEmail = nil
    }
}
