//
//  SavedReceiptsView.swift
//  Scanner
//
//  Created on 12/5/25.
//

import SwiftUI
import SwiftData

struct SavedReceiptsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \SavedReceipt.createdAt, order: .reverse)
    private var allReceipts: [SavedReceipt]
    @Query private var userAccounts: [UserAccount]

    @State private var selectedReceiptID: UUID?
    @State private var showingDetail = false
    @State private var searchText = ""

    // User session for tracking current user
    private var userSession = UserSession.shared

    private var currentUser: UserAccount? {
        userAccounts.first(where: { $0.email == userSession.currentUserEmail })
    }

    // Filter receipts to show only current user's receipts OR receipts with no owner (shared/legacy)
    private var receipts: [SavedReceipt] {
        guard let currentEmail = userSession.currentUserEmail else {
            // No user logged in, show all receipts with no owner
            return allReceipts.filter { $0.owner == nil }
        }

        // Show receipts owned by current user OR receipts with no owner
        return allReceipts.filter { receipt in
            receipt.owner == nil || receipt.owner?.email == currentEmail
        }
    }

    var filteredReceipts: [SavedReceipt] {
        if searchText.isEmpty {
            return receipts
        }
        return receipts.filter { receipt in
            receipt.storeName?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if receipts.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No Saved Receipts")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Scan and save receipts to see them here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(filteredReceipts) { receipt in
                            ReceiptRowView(receipt: receipt)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedReceiptID = receipt.id
                                    showingDetail = true
                                }
                        }
                        .onDelete(perform: deleteReceipts)
                    }
                    .searchable(text: $searchText, prompt: "Search by store name")
                }
            }
            .navigationTitle("Saved Receipts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                if !receipts.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                }
            }
            .sheet(isPresented: $showingDetail) {
                if let receiptID = selectedReceiptID {
                    ReceiptDetailView(receiptID: receiptID)
                }
            }
        }
    }

    private func deleteReceipts(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredReceipts[index])
        }
        do {
            try modelContext.save()
        } catch {
            print("Error deleting receipt: \(error)")
        }
    }
}

// MARK: - Receipt Row View
struct ReceiptRowView: View {
    let receipt: SavedReceipt

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(receipt.storeName ?? "Unknown Store")
                        .font(.headline)

                    if let date = receipt.date {
                        Text(date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text("\(receipt.items.count) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(receipt.total, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.bold)

                    Text(receipt.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Receipt Detail View
struct ReceiptDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let receiptID: UUID

    @State private var receipt: SavedReceipt?
    @State private var showingShareSheet = false
    @State private var shareURL: URL?
    @State private var isEditing = false
    @State private var editableReceipt: EditableReceipt?

    var body: some View {
        Group {
            if let receipt = receipt {
                receiptDetailContent(receipt: receipt)
            } else {
                VStack {
                    ProgressView()
                    Text("Loading...")
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            loadReceipt()
        }
    }

    private func loadReceipt() {
        // Explicitly fetch the receipt with its relationships
        let descriptor = FetchDescriptor<SavedReceipt>(
            predicate: #Predicate { $0.id == receiptID }
        )

        do {
            let results = try modelContext.fetch(descriptor)
            if let fetchedReceipt = results.first {
                // Access the items to force load the relationship
                _ = fetchedReceipt.items.count
                receipt = fetchedReceipt
            }
        } catch {
            print("Error fetching receipt: \(error)")
        }
    }

    @ViewBuilder
    private func receiptDetailContent(receipt: SavedReceipt) -> some View {
        NavigationStack {
            ScrollView {
                if isEditing, let editable = editableReceipt {
                    // Show editable form when editing
                    EditableReceiptForm(receipt: Binding(
                        get: { editable },
                        set: { editableReceipt = $0 }
                    ))
                    .padding(.vertical)
                } else {
                    // Show read-only view when not editing
                    VStack(spacing: 20) {
                        // Store info
                        VStack(spacing: 8) {
                        Image(systemName: "storefront")
                            .font(.system(size: 50))
                            .foregroundStyle(.blue)

                        Text(receipt.storeName ?? "Unknown Store")
                            .font(.title2)
                            .fontWeight(.bold)

                        if let date = receipt.date {
                            Text(date)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Text("Scanned \(receipt.createdAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)

                    // Items list
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Items")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(receipt.items) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(item.name)
                                        .font(.body)
                                        .fontWeight(.medium)

                                    Spacer()

                                    // Category badge
                                    if let category = ItemCategory(rawValue: item.category) {
                                        HStack(spacing: 4) {
                                            Image(systemName: category.icon)
                                                .font(.system(size: 9))
                                            Text(category.rawValue)
                                                .font(.system(size: 9, weight: .medium))
                                        }
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(category.color.opacity(0.2))
                                        .foregroundColor(category.color)
                                        .cornerRadius(4)
                                    }
                                }
                                HStack {
                                    Text("\(item.quantity, specifier: "%.0f") × $\(item.unitPrice, specifier: "%.2f")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("$\(item.lineTotal, specifier: "%.2f")")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }
                    }

                    // Totals
                    VStack(spacing: 8) {
                        Divider()
                            .padding(.horizontal)

                        HStack {
                            Text("Subtotal:")
                            Spacer()
                            Text("$\(receipt.subtotal, specifier: "%.2f")")
                        }
                        .font(.body)
                        .padding(.horizontal)

                        HStack {
                            Text("Tax:")
                            Spacer()
                            Text("$\(receipt.tax, specifier: "%.2f")")
                        }
                        .font(.body)
                        .padding(.horizontal)

                        HStack {
                            Text("Total:")
                                .fontWeight(.bold)
                            Spacer()
                            Text("$\(receipt.total, specifier: "%.2f")")
                                .fontWeight(.bold)
                        }
                        .font(.title3)
                        .padding(.horizontal)
                        .padding(.top, 4)
                    }
                    .padding(.vertical)

                    // OCR Text (if available)
                    if let ocrText = receipt.ocrText, !ocrText.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Original OCR Text")
                                .font(.headline)
                            Text(ocrText)
                                .font(.system(.caption, design: .monospaced))
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .textSelection(.enabled)
                        }
                        .padding(.horizontal)
                    }

                    // Export button
                    Button(action: { exportCSV(receipt: receipt) }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export as CSV")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Receipt" : "Receipt Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button("Cancel") {
                            isEditing = false
                            editableReceipt = nil
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button("Save") {
                            saveEdits()
                        }
                        .fontWeight(.semibold)
                    } else {
                        Button("Edit") {
                            toggleEditMode()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = shareURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    private func toggleEditMode() {
        guard let receipt = receipt else { return }
        editableReceipt = EditableReceipt(from: receipt)
        isEditing = true
    }

    private func saveEdits() {
        guard let receipt = receipt,
              let editable = editableReceipt else { return }

        // Update receipt properties
        receipt.storeName = editable.storeName
        receipt.date = editable.date
        receipt.tax = editable.tax
        receipt.subtotal = editable.subtotal
        receipt.total = editable.total

        // Replace all items (cascade delete handles cleanup)
        receipt.items.removeAll()
        for editableItem in editable.items {
            let newItem = SavedReceiptItem(
                name: editableItem.name,
                quantity: editableItem.quantity,
                unitPrice: editableItem.unitPrice,
                lineTotal: editableItem.lineTotal,
                discountType: editableItem.discountType.rawValue,
                discountValue: editableItem.discountValue,
                category: editableItem.category.rawValue
            )
            receipt.items.append(newItem)
        }

        // Save to database
        do {
            try modelContext.save()
            isEditing = false
            editableReceipt = nil
        } catch {
            print("Error saving edits: \(error)")
            // TODO: Show error alert
        }
    }

    private func exportCSV(receipt: SavedReceipt) {
        let exporter = CSVExportService()

        // Convert SavedReceipt to ParsedReceipt for CSV export
        let parsedReceipt = ParsedReceipt(
            storeName: receipt.storeName,
            date: receipt.date,
            items: receipt.items.map { item in
                ReceiptItem(
                    name: item.name,
                    quantity: item.quantity,
                    unitPrice: item.unitPrice,
                    lineTotal: item.lineTotal,
                    discountType: DiscountType(rawValue: item.discountType) ?? .none,
                    discountValue: item.discountValue,
                    category: ItemCategory(rawValue: item.category) ?? .other
                )
            },
            subtotal: receipt.subtotal,
            tax: receipt.tax,
            total: receipt.total
        )

        let csv = exporter.exportToCSV(receipt: parsedReceipt)

        do {
            let filename = exporter.generateFilename()
            shareURL = try exporter.saveToFile(csv: csv, filename: filename)
            showingShareSheet = true
        } catch {
            print("Error exporting CSV: \(error)")
        }
    }
}

#Preview {
    SavedReceiptsView()
        .modelContainer(for: [SavedReceipt.self, SavedReceiptItem.self])
}
