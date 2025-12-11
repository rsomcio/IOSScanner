//
//  EditableReceipt.swift
//  Scanner
//
//  Created by Claude Code on 12/10/25.
//

import Foundation

// MARK: - Editable Receipt Item

struct EditableReceiptItem: Identifiable, Equatable {
    let id: UUID
    var name: String
    var quantity: Double
    var unitPrice: Double

    // Auto-calculated line total
    var lineTotal: Double {
        quantity * unitPrice
    }

    // Default initializer
    init(id: UUID = UUID(), name: String = "", quantity: Double = 1.0, unitPrice: Double = 0.0) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unitPrice = unitPrice
    }

    // Initialize from ParsedReceipt item
    init(from item: ReceiptItem) {
        self.id = item.id
        self.name = item.name
        self.quantity = item.quantity
        self.unitPrice = item.unitPrice
    }

    // Initialize from SavedReceipt item
    init(from item: SavedReceiptItem) {
        self.id = item.id
        self.name = item.name
        self.quantity = item.quantity
        self.unitPrice = item.unitPrice
    }

    // Convert to ReceiptItem
    func toReceiptItem() -> ReceiptItem {
        ReceiptItem(
            name: name,
            quantity: quantity,
            unitPrice: unitPrice,
            lineTotal: lineTotal
        )
    }
}

// MARK: - Editable Receipt

struct EditableReceipt: Equatable {
    var storeName: String
    var date: String
    var items: [EditableReceiptItem]
    var tax: Double

    // Auto-calculated subtotal
    var subtotal: Double {
        items.reduce(0) { $0 + $1.lineTotal }
    }

    // Auto-calculated total
    var total: Double {
        subtotal + tax
    }

    // Default initializer
    init(storeName: String = "", date: String = "", items: [EditableReceiptItem] = [], tax: Double = 0.0) {
        self.storeName = storeName
        self.date = date
        self.items = items
        self.tax = tax
    }

    // Initialize from ParsedReceipt
    init(from receipt: ParsedReceipt) {
        self.storeName = receipt.storeName ?? ""
        self.date = receipt.date ?? ""
        self.items = receipt.items.map { EditableReceiptItem(from: $0) }
        self.tax = receipt.tax
    }

    // Initialize from SavedReceipt
    init(from receipt: SavedReceipt) {
        self.storeName = receipt.storeName ?? ""
        self.date = receipt.date ?? ""
        self.items = receipt.items.map { EditableReceiptItem(from: $0) }
        self.tax = receipt.tax
    }

    // Convert to ParsedReceipt
    func toParsedReceipt() -> ParsedReceipt {
        ParsedReceipt(
            storeName: storeName.isEmpty ? nil : storeName,
            date: date.isEmpty ? nil : date,
            items: items.map { $0.toReceiptItem() },
            subtotal: subtotal,
            tax: tax,
            total: total
        )
    }

    // Add a new blank item
    mutating func addItem() {
        items.append(EditableReceiptItem())
    }

    // Remove item at index
    mutating func removeItem(at index: Int) {
        guard index >= 0 && index < items.count else { return }
        items.remove(at: index)
    }
}
