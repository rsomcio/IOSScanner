//
//  EditableReceipt.swift
//  Scanner
//
//  Created by Claude Code on 12/10/25.
//

import Foundation

// MARK: - Discount Type

enum DiscountType: String, Codable, CaseIterable {
    case none = "none"
    case dollar = "dollar"
    case percentage = "percentage"

    var displayName: String {
        switch self {
        case .none: return "No Discount"
        case .dollar: return "$ Amount"
        case .percentage: return "% Percentage"
        }
    }
}

// MARK: - Editable Receipt Item

struct EditableReceiptItem: Identifiable, Equatable {
    let id: UUID
    var name: String
    var quantity: Double
    var unitPrice: Double
    var discountType: DiscountType
    var discountValue: Double
    var category: ItemCategory

    // Auto-calculated line total with discount applied
    var lineTotal: Double {
        let baseAmount = quantity * unitPrice

        switch discountType {
        case .none:
            return baseAmount
        case .dollar:
            return max(0, baseAmount - discountValue)
        case .percentage:
            let discountAmount = baseAmount * (discountValue / 100.0)
            return max(0, baseAmount - discountAmount)
        }
    }

    // Default initializer
    init(id: UUID = UUID(), name: String = "", quantity: Double = 1.0, unitPrice: Double = 0.0, discountType: DiscountType = .none, discountValue: Double = 0.0, category: ItemCategory = .other) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.discountType = discountType
        self.discountValue = discountValue
        self.category = category
    }

    // Initialize from ParsedReceipt item
    init(from item: ReceiptItem) {
        self.id = item.id
        self.name = item.name
        self.quantity = item.quantity
        self.unitPrice = item.unitPrice
        self.discountType = item.discountType
        self.discountValue = item.discountValue
        self.category = item.category
    }

    // Initialize from SavedReceipt item
    init(from item: SavedReceiptItem) {
        self.id = item.id
        self.name = item.name
        self.quantity = item.quantity
        self.unitPrice = item.unitPrice
        self.discountType = DiscountType(rawValue: item.discountType) ?? .none
        self.discountValue = item.discountValue
        self.category = ItemCategory(rawValue: item.category) ?? .other
    }

    // Convert to ReceiptItem
    func toReceiptItem() -> ReceiptItem {
        ReceiptItem(
            name: name,
            quantity: quantity,
            unitPrice: unitPrice,
            lineTotal: lineTotal,
            discountType: discountType,
            discountValue: discountValue,
            category: category
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
