//
//  ScannerApp.swift
//  Scanner
//
//  Created by Ray Somcio on 12/2/25.
//

import SwiftUI
import SwiftData

@main
struct ScannerApp: App {
    var body: some Scene {
        WindowGroup {
            OnboardingContainerView()
        }
        .modelContainer(for: [
            UserAccount.self,
            UserPurpose.self,
            SavedReceipt.self,
            SavedReceiptItem.self
        ])
    }
}
