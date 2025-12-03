//
//  CSVExportService.swift
//  Scanner
//
//  Created on 12/2/25.
//

import Foundation

struct CSVExportService {

    /// Export parsed receipts to CSV format
    /// - Parameter receipts: Array of ParsedReceipt objects
    /// - Returns: CSV string
    func exportToCSV(receipts: [ParsedReceipt]) -> String {
        var csv = "Store,Date,Item Name,Quantity,Unit Price,Line Total,Receipt Subtotal,Tax,Total\n"

        for receipt in receipts {
            let store = escapeCSV(receipt.storeName ?? "Unknown")
            let date = receipt.date ?? "N/A"

            for item in receipt.items {
                let row = [
                    store,
                    date,
                    escapeCSV(item.name),
                    formatNumber(item.quantity),
                    formatCurrency(item.unitPrice),
                    formatCurrency(item.lineTotal),
                    formatCurrency(receipt.subtotal),
                    formatCurrency(receipt.tax),
                    formatCurrency(receipt.total)
                ]
                csv += row.joined(separator: ",") + "\n"
            }
        }

        return csv
    }

    /// Export a single receipt to CSV format
    /// - Parameter receipt: ParsedReceipt object
    /// - Returns: CSV string
    func exportToCSV(receipt: ParsedReceipt) -> String {
        return exportToCSV(receipts: [receipt])
    }

    /// Save CSV string to file in Documents directory
    /// - Parameters:
    ///   - csv: CSV string to save
    ///   - filename: Name of the file (with .csv extension)
    /// - Returns: URL of the saved file
    func saveToFile(csv: String, filename: String) throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)

        try csv.write(to: fileURL, atomically: true, encoding: .utf8)

        return fileURL
    }

    /// Generate a unique filename for a receipt
    /// - Returns: Filename string (e.g., "receipt_2025-12-02_143045.csv")
    func generateFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = formatter.string(from: Date())
        return "receipt_\(timestamp).csv"
    }

    // MARK: - Private Helper Methods

    /// Escape CSV values (handle quotes and commas)
    /// - Parameter value: String to escape
    /// - Returns: Escaped string
    private func escapeCSV(_ value: String) -> String {
        // If the value contains comma, quote, or newline, wrap it in quotes
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            // Escape existing quotes by doubling them
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }

    /// Format number with 2 decimal places
    /// - Parameter value: Number to format
    /// - Returns: Formatted string
    private func formatNumber(_ value: Double) -> String {
        return String(format: "%.2f", value)
    }

    /// Format currency with 2 decimal places
    /// - Parameter value: Currency value to format
    /// - Returns: Formatted string
    private func formatCurrency(_ value: Double) -> String {
        return String(format: "%.2f", value)
    }
}
