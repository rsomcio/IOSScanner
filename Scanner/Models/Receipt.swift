//
//  Receipt.swift
//  Scanner
//
//  Created on 12/2/25.
//

import Foundation
import SwiftData

// MARK: - API Response Models (Temporary, for parsing)
struct ReceiptItem: Codable, Identifiable {
    var id = UUID()
    var name: String
    var quantity: Double
    var unitPrice: Double
    var lineTotal: Double
    var discountType: DiscountType
    var discountValue: Double
    var category: ItemCategory

    enum CodingKeys: String, CodingKey {
        case name
        case quantity
        case unitPrice
        case lineTotal
        case discountType
        case discountValue
        case category
    }

    init(name: String, quantity: Double, unitPrice: Double, lineTotal: Double, discountType: DiscountType = .none, discountValue: Double = 0.0, category: ItemCategory = .other) {
        self.id = UUID()
        self.name = name
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.lineTotal = lineTotal
        self.discountType = discountType
        self.discountValue = discountValue
        self.category = category
    }

    // Custom decoder to handle missing discount and category fields (backward compatibility)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.quantity = try container.decode(Double.self, forKey: .quantity)
        self.unitPrice = try container.decode(Double.self, forKey: .unitPrice)
        self.lineTotal = try container.decode(Double.self, forKey: .lineTotal)

        // Decode discount fields with defaults if missing
        if let discountTypeString = try? container.decode(String.self, forKey: .discountType),
           let discountType = DiscountType(rawValue: discountTypeString) {
            self.discountType = discountType
        } else {
            self.discountType = .none
        }

        self.discountValue = (try? container.decode(Double.self, forKey: .discountValue)) ?? 0.0

        // Decode category field with default if missing
        if let categoryString = try? container.decode(String.self, forKey: .category),
           let category = ItemCategory(rawValue: categoryString) {
            self.category = category
        } else {
            self.category = .other
        }
    }
}

struct ParsedReceipt: Codable {
    var storeName: String?
    var date: String?
    var items: [ReceiptItem]
    var subtotal: Double
    var tax: Double
    var total: Double

    enum CodingKeys: String, CodingKey {
        case storeName
        case date
        case items
        case subtotal
        case tax
        case total
    }
}

// MARK: - SwiftData Persistent Models

@Model
final class SavedReceiptItem {
    var id: UUID
    var name: String
    var quantity: Double
    var unitPrice: Double
    var lineTotal: Double
    var discountType: String = "none"
    var discountValue: Double = 0.0
    var category: String = "Other"

    var receipt: SavedReceipt?

    init(name: String, quantity: Double, unitPrice: Double, lineTotal: Double, discountType: String = "none", discountValue: Double = 0.0, category: String = "Other") {
        self.id = UUID()
        self.name = name
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.lineTotal = lineTotal
        self.discountType = discountType
        self.discountValue = discountValue
        self.category = category
    }

    // Create from API response
    convenience init(from item: ReceiptItem) {
        self.init(
            name: item.name,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            lineTotal: item.lineTotal,
            discountType: item.discountType.rawValue,
            discountValue: item.discountValue,
            category: item.category.rawValue
        )
    }
}

@Model
final class SavedReceipt {
    @Attribute(.unique) var id: UUID
    var storeName: String?
    var date: String?
    var subtotal: Double
    var tax: Double
    var total: Double
    var createdAt: Date
    var ocrText: String?

    @Relationship(deleteRule: .cascade, inverse: \SavedReceiptItem.receipt)
    var items: [SavedReceiptItem] = []

    // Optional relationship to user - null means receipt is shared across all profiles
    var owner: UserAccount?

    init(storeName: String?, date: String?, items: [SavedReceiptItem],
         subtotal: Double, tax: Double, total: Double, ocrText: String? = nil, owner: UserAccount? = nil) {
        self.id = UUID()
        self.storeName = storeName
        self.date = date
        self.items = items
        self.subtotal = subtotal
        self.tax = tax
        self.total = total
        self.createdAt = Date()
        self.ocrText = ocrText
        self.owner = owner
    }

    // Create from API response
    convenience init(from parsedReceipt: ParsedReceipt, ocrText: String? = nil) {
        let savedItems = parsedReceipt.items.map { SavedReceiptItem(from: $0) }
        self.init(
            storeName: parsedReceipt.storeName,
            date: parsedReceipt.date,
            items: savedItems,
            subtotal: parsedReceipt.subtotal,
            tax: parsedReceipt.tax,
            total: parsedReceipt.total,
            ocrText: ocrText
        )
    }
}

// MARK: - Recognized Text Block (for OCR)
struct RecognizedTextBlock: Identifiable {
    let id = UUID()
    let text: String
    let confidence: Float
    let boundingBox: CGRect
}

// MARK: - Error Types
enum ScannerError: Error, LocalizedError {
    case notInitialized
    case invalidImage
    case ocrFailed
    case apiError
    case invalidResponse
    case missingAPIKey

    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Service not initialized. Please set API key first."
        case .invalidImage:
            return "Invalid image format"
        case .ocrFailed:
            return "Failed to recognize text from image"
        case .apiError:
            return "API request failed"
        case .invalidResponse:
            return "Invalid response from API"
        case .missingAPIKey:
            return "OpenAI API key is required"
        }
    }
}
