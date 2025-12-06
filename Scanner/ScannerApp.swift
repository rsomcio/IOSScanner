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
            ContentView()
        }
        .modelContainer(for: [SavedReceipt.self, SavedReceiptItem.self])
    }
}
