//
//  VendorAutocompleteField.swift
//  Scanner
//
//  Created by Claude Code on 12/10/25.
//

import SwiftUI
import SwiftData

struct VendorAutocompleteField: View {
    @Binding var vendorName: String
    @Environment(\.modelContext) private var modelContext

    @State private var suggestions: [String] = []
    @State private var showingSuggestions = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // TextField with label
            VStack(alignment: .leading, spacing: 4) {
                Text("Store Name")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)

                TextField("Enter store name", text: $vendorName)
                    .textFieldStyle(.roundedBorder)
                    .focused($isFocused)
                    .onChange(of: vendorName) { _, newValue in
                        updateSuggestions(for: newValue)
                    }
            }

            // Suggestions dropdown
            if showingSuggestions && !suggestions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button(action: {
                            vendorName = suggestion
                            showingSuggestions = false
                            isFocused = false
                        }) {
                            HStack {
                                Text(suggestion)
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "arrow.turn.down.left")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                        }

                        if suggestion != suggestions.last {
                            Divider()
                        }
                    }
                }
                .background(Color(UIColor.systemBackground))
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.1), radius: 4)
                .padding(.top, 4)
            }
        }
        .onChange(of: isFocused) { _, focused in
            if !focused {
                showingSuggestions = false
            }
        }
    }

    private func updateSuggestions(for query: String) {
        guard !query.isEmpty else {
            suggestions = []
            showingSuggestions = false
            return
        }

        // Query SwiftData for unique vendor names
        let descriptor = FetchDescriptor<SavedReceipt>()

        do {
            let receipts = try modelContext.fetch(descriptor)
            let allVendors = Set(receipts.compactMap { $0.storeName })

            suggestions = allVendors
                .filter { $0.localizedCaseInsensitiveContains(query) }
                .sorted()
                .prefix(5)
                .map { $0 }

            showingSuggestions = !suggestions.isEmpty
        } catch {
            suggestions = []
            showingSuggestions = false
        }
    }
}

#Preview {
    VendorAutocompleteField(vendorName: .constant(""))
        .modelContainer(for: [SavedReceipt.self, SavedReceiptItem.self])
        .padding()
}
