//
//  UserAccount.swift
//  Scanner
//
//  Created on 12/29/25.
//

import Foundation
import SwiftData

/// SwiftData model for user account
@Model
final class UserAccount {
    /// Unique email address (enforced at database level)
    @Attribute(.unique) var email: String

    /// User's full name
    var fullName: String

    /// Hashed password (base64 encoded for demo - use CryptoKit for production)
    var passwordHash: String

    /// Account creation timestamp
    var createdAt: Date

    /// User's selected purposes (one-to-many relationship with cascade delete)
    @Relationship(deleteRule: .cascade, inverse: \UserPurpose.user)
    var purposes: [UserPurpose] = []

    /// Receipts owned by this user (one-to-many relationship, nullify on delete)
    @Relationship(deleteRule: .nullify, inverse: \SavedReceipt.owner)
    var receipts: [SavedReceipt] = []

    init(fullName: String, email: String, passwordHash: String) {
        self.fullName = fullName
        self.email = email
        self.passwordHash = passwordHash
        self.createdAt = Date()
    }

    /// Hash password using base64 encoding (simple demo - use CryptoKit SHA256 for production)
    static func hashPassword(_ password: String) -> String {
        password.data(using: .utf8)?.base64EncodedString() ?? ""
    }

    /// Verify password against stored hash
    func verifyPassword(_ password: String) -> Bool {
        let hashedInput = UserAccount.hashPassword(password)
        return hashedInput == passwordHash
    }
}
