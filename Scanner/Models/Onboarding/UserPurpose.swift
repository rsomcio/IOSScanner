//
//  UserPurpose.swift
//  Scanner
//
//  Created on 12/29/25.
//

import Foundation
import SwiftData

/// SwiftData model for user's app usage purpose
@Model
final class UserPurpose {
    /// Unique identifier
    var id: UUID

    /// Purpose name (stored as AppPurpose.rawValue)
    var purposeName: String

    /// Custom description (only for "Other" purpose)
    var customPurpose: String?

    /// Creation timestamp
    var createdAt: Date

    /// Back-reference to parent UserAccount
    var user: UserAccount?

    init(purposeName: String, customPurpose: String? = nil) {
        self.id = UUID()
        self.purposeName = purposeName
        self.customPurpose = customPurpose
        self.createdAt = Date()
    }

    /// Convenience initializer from AppPurpose enum
    convenience init(from purpose: AppPurpose, customPurpose: String? = nil) {
        self.init(
            purposeName: purpose.rawValue,
            customPurpose: customPurpose
        )
    }

    /// Get AppPurpose enum from stored string
    var purpose: AppPurpose? {
        AppPurpose(rawValue: purposeName)
    }
}
