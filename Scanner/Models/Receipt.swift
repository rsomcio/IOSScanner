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
    let id = UUID()
    let name: String
    let quantity: Double
    let unitPrice: Double
    let lineTotal: Double

    enum CodingKeys: String, CodingKey {
        case name
        case quantity
        case unitPrice
        case lineTotal
    }
}

struct ParsedReceipt: Codable {
    let storeName: String?
    let date: String?
    let items: [ReceiptItem]
    let subtotal: Double
    let tax: Double
    let total: Double

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

    var receipt: SavedReceipt?

    init(name: String, quantity: Double, unitPrice: Double, lineTotal: Double) {
        self.id = UUID()
        self.name = name
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.lineTotal = lineTotal
    }

    // Create from API response
    convenience init(from item: ReceiptItem) {
        self.init(
            name: item.name,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            lineTotal: item.lineTotal
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

    init(storeName: String?, date: String?, items: [SavedReceiptItem],
         subtotal: Double, tax: Double, total: Double, ocrText: String? = nil) {
        self.id = UUID()
        self.storeName = storeName
        self.date = date
        self.items = items
        self.subtotal = subtotal
        self.tax = tax
        self.total = total
        self.createdAt = Date()
        self.ocrText = ocrText
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
