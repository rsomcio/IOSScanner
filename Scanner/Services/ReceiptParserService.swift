//
//  ReceiptParserService.swift
//  Scanner
//
//  Created on 12/2/25.
//

import Foundation

actor ReceiptParserService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    /// Parse OCR text using OpenAI GPT-4o mini with structured output
    /// - Parameter ocrText: The OCR text extracted from receipt
    /// - Returns: ParsedReceipt with structured data
    func parseReceipt(ocrText: String) async throws -> ParsedReceipt {
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // JSON Schema for structured output
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "storeName": [
                    "anyOf": [
                        ["type": "string"],
                        ["type": "null"]
                    ],
                    "description": "Name of the store or vendor"
                ],
                "date": [
                    "anyOf": [
                        ["type": "string"],
                        ["type": "null"]
                    ],
                    "description": "Receipt date in YYYY-MM-DD format"
                ],
                "items": [
                    "type": "array",
                    "description": "List of purchased items",
                    "items": [
                        "type": "object",
                        "properties": [
                            "name": [
                                "type": "string",
                                "description": "Item name or description"
                            ],
                            "quantity": [
                                "type": "number",
                                "description": "Quantity purchased (default 1 if not specified)"
                            ],
                            "unitPrice": [
                                "type": "number",
                                "description": "Price per unit"
                            ],
                            "lineTotal": [
                                "type": "number",
                                "description": "Total for this line (quantity × unitPrice)"
                            ]
                        ],
                        "required": ["name", "quantity", "unitPrice", "lineTotal"],
                        "additionalProperties": false
                    ]
                ],
                "subtotal": [
                    "type": "number",
                    "description": "Subtotal before tax"
                ],
                "tax": [
                    "type": "number",
                    "description": "Tax amount"
                ],
                "total": [
                    "type": "number",
                    "description": "Total amount paid"
                ]
            ],
            "required": ["storeName", "date", "items", "subtotal", "tax", "total"],
            "additionalProperties": false
        ]

        let systemPrompt = """
        You are a specialized receipt parser. Extract grocery items and totals from OCR text.

        EXTRACTION RULES:
        1. Extract each line item with name, quantity, unit price, and line total
        2. If quantity is not explicitly stated, use 1
        3. Look for quantity patterns like: "2x", "2 @", "QTY 2"
        4. Calculate unitPrice from lineTotal and quantity if not explicitly shown
        5. Ignore non-item lines like subtotal, tax, total (extract those separately)
        6. Extract store name if present (usually at top of receipt)
        7. Extract date in YYYY-MM-DD format if present

        IMPORTANT:
        - Return ONLY valid JSON matching the provided schema
        - All prices must be positive numbers with proper decimal format
        - If a field cannot be determined, use null for strings or 0 for required numbers
        """

        let userPrompt = "Parse this receipt and extract all items:\n\n\(ocrText)"

        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "temperature": 0.1,
            "max_tokens": 2000,
            "response_format": [
                "type": "json_schema",
                "json_schema": [
                    "name": "receipt_parser",
                    "strict": true,
                    "schema": schema
                ] as [String: Any]
            ] as [String: Any]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // Debug: Print request info
        print("=== API Request ===")
        print("URL: \(request.url?.absoluteString ?? "unknown")")
        print("Method: \(request.httpMethod ?? "unknown")")
        print("API Key (first 20 chars): \(String(apiKey.prefix(20)))...")
        if let bodyString = String(data: request.httpBody ?? Data(), encoding: .utf8) {
            print("Request body (first 500 chars): \(String(bodyString.prefix(500)))")
        }

        // Make API request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ScannerError.apiError
        }

        // Check for API errors
        if !(200...299).contains(httpResponse.statusCode) {
            var errorMessage = "API Error (Status: \(httpResponse.statusCode))"
            if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorResponse["error"] as? [String: Any],
               let message = error["message"] as? String {
                errorMessage = message
                print("API Error: \(message)")
            } else if let responseString = String(data: data, encoding: .utf8) {
                print("API Response: \(responseString)")
            }
            throw NSError(domain: "ReceiptParserService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        // Parse response
        let apiResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        guard let content = apiResponse.choices.first?.message.content,
              let contentData = content.data(using: .utf8) else {
            throw ScannerError.invalidResponse
        }

        // Decode the structured receipt data
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            return try decoder.decode(ParsedReceipt.self, from: contentData)
        } catch {
            print("Decoding error: \(error)")
            print("Content: \(content)")
            throw ScannerError.invalidResponse
        }
    }

    /// Validate parsed receipt data
    /// - Parameter receipt: ParsedReceipt to validate
    /// - Returns: Tuple of (isValid, errors)
    func validateReceipt(_ receipt: ParsedReceipt) -> (isValid: Bool, errors: [String]) {
        var errors: [String] = []

        // Check if items exist
        if receipt.items.isEmpty {
            errors.append("No items found in receipt")
        }

        // Validate item totals
        for (index, item) in receipt.items.enumerated() {
            if item.quantity <= 0 {
                errors.append("Item \(index + 1): Invalid quantity (\(item.quantity))")
            }

            if item.lineTotal < 0 {
                errors.append("Item \(index + 1): Invalid line total (\(item.lineTotal))")
            }

            // Check if unitPrice × quantity ≈ lineTotal
            if item.unitPrice > 0 {
                let expectedTotal = item.quantity * item.unitPrice
                let difference = abs(expectedTotal - item.lineTotal)
                if difference > 0.02 {
                    errors.append("Item \(index + 1): Price mismatch (expected: \(expectedTotal), got: \(item.lineTotal))")
                }
            }
        }

        // Validate totals
        let calculatedSubtotal = receipt.items.reduce(0.0) { $0 + $1.lineTotal }
        if abs(calculatedSubtotal - receipt.subtotal) > 0.10 {
            errors.append("Subtotal mismatch (calculated: \(calculatedSubtotal), stated: \(receipt.subtotal))")
        }

        let expectedTotal = receipt.subtotal + receipt.tax
        if abs(expectedTotal - receipt.total) > 0.02 {
            errors.append("Total mismatch (expected: \(expectedTotal), stated: \(receipt.total))")
        }

        return (errors.isEmpty, errors)
    }
}

// MARK: - API Response Models
struct OpenAIResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: Message
    }

    struct Message: Codable {
        let content: String?
    }
}
