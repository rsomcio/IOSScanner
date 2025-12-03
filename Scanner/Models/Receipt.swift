//
//  Receipt.swift
//  Scanner
//
//  Created on 12/2/25.
//

import Foundation

// MARK: - Receipt Item Model
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

// MARK: - Parsed Receipt Model
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
