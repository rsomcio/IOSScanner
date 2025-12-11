//
//  ReceiptProcessingView.swift
//  Scanner
//
//  Created by Claude Code on 12/10/25.
//

import SwiftUI
import SwiftData

struct ReceiptProcessingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var viewModel: ReceiptScannerViewModel
    let capturedImage: UIImage?

    @State private var showingShareSheet = false
    @State private var shareURL: URL?
    @State private var showingSaveConfirmation = false
    @State private var selectedTab: ProcessingTab = .receipt

    enum ProcessingTab {
        case receipt, ocr, csv
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                }

                Text("Receipt Details")
                    .font(.system(size: 17, weight: .regular))

                Spacer()

                Button(action: {
                    // Menu action
                }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(UIColor.systemBackground))

            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    // Receipt Image
                    if let capturedImage = capturedImage {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Receipt Image")
                                .font(.system(size: 16, weight: .semibold))

                            Image(uiImage: capturedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 250)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .black.opacity(0.1), radius: 8)
                        }
                        .padding(16)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }

                    // Processing Status
                    if viewModel.isProcessing {
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)

                            Text(viewModel.currentStep)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }

                    // Error Message
                    if let error = viewModel.errorMessage {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text("Error")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.red)
                            }

                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }

                    // Validation Warnings
                    if viewModel.showValidationWarning && !viewModel.validationErrors.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                Text("Validation Warnings")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.orange)
                            }

                            ForEach(viewModel.validationErrors, id: \.self) { error in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                    Text(error)
                                        .font(.system(size: 13))
                                }
                                .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }

                    // Tab Selector
                    if !viewModel.isProcessing && viewModel.parsedReceipt != nil {
                        HStack(spacing: 0) {
                            TabButton(title: "Receipt", isSelected: selectedTab == .receipt) {
                                selectedTab = .receipt
                            }

                            TabButton(title: "OCR Text", isSelected: selectedTab == .ocr) {
                                selectedTab = .ocr
                            }

                            TabButton(title: "CSV", isSelected: selectedTab == .csv) {
                                selectedTab = .csv
                            }
                        }
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }

                    // Content based on selected tab
                    if !viewModel.isProcessing {
                        switch selectedTab {
                        case .receipt:
                            if viewModel.parsedReceipt != nil {
                                ParsedReceiptView(receipt: Binding(
                                    get: { viewModel.parsedReceipt ?? ParsedReceipt(storeName: nil, date: nil, items: [], subtotal: 0, tax: 0, total: 0) },
                                    set: { viewModel.parsedReceipt = $0 }
                                ))
                            }
                        case .ocr:
                            if !viewModel.ocrText.isEmpty {
                                OCRTextView(ocrText: viewModel.ocrText)
                            }
                        case .csv:
                            if !viewModel.csvOutput.isEmpty {
                                CSVOutputView(csvOutput: viewModel.csvOutput)
                            }
                        }
                    }

                    // Action Buttons
                    if !viewModel.isProcessing && viewModel.parsedReceipt != nil {
                        VStack(spacing: 12) {
                            Button(action: saveReceipt) {
                                HStack {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("Save Receipt")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }

                            if !viewModel.csvOutput.isEmpty {
                                Button(action: exportCSV) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.up")
                                        Text("Export CSV")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                            }

                            Button(action: {
                                viewModel.reset()
                                dismiss()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("Reset & Close")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
                .padding(.top, 16)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingShareSheet) {
            if let url = shareURL {
                ShareSheet(items: [url])
            }
        }
        .alert("Receipt Saved", isPresented: $showingSaveConfirmation) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Your receipt has been saved successfully")
        }
    }

    // MARK: - Helper Functions
    private func saveReceipt() {
        guard let receipt = viewModel.parsedReceipt else { return }

        let savedReceipt = SavedReceipt(from: receipt, ocrText: viewModel.ocrText)
        modelContext.insert(savedReceipt)

        do {
            try modelContext.save()
            showingSaveConfirmation = true
        } catch {
            viewModel.errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }

    private func exportCSV() {
        do {
            let exporter = CSVExportService()
            let filename = exporter.generateFilename()
            shareURL = try exporter.saveToFile(csv: viewModel.csvOutput, filename: filename)
            showingShareSheet = true
        } catch {
            viewModel.errorMessage = "Failed to export CSV: \(error.localizedDescription)"
        }
    }
}

// MARK: - Tab Button Component
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color.blue : Color.clear)
                .cornerRadius(8)
        }
    }
}

// MARK: - Parsed Receipt View
struct ParsedReceiptView: View {
    @Binding var receipt: ParsedReceipt
    @State private var editableReceipt: EditableReceipt

    init(receipt: Binding<ParsedReceipt>) {
        self._receipt = receipt
        self._editableReceipt = State(initialValue: EditableReceipt(from: receipt.wrappedValue))
    }

    var body: some View {
        EditableReceiptForm(receipt: $editableReceipt)
            .onChange(of: editableReceipt) { _, newValue in
                receipt = newValue.toParsedReceipt()
            }
    }
}

// MARK: - OCR Text View
struct OCRTextView: View {
    let ocrText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("OCR Extracted Text")
                .font(.system(size: 18, weight: .semibold))
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                Text(ocrText)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
}

// MARK: - CSV Output View
struct CSVOutputView: View {
    let csvOutput: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CSV Export Preview")
                .font(.system(size: 18, weight: .semibold))
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                Text(csvOutput)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
}

// MARK: - Helper Components
struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.primary)
        }
    }
}

struct TotalRow: View {
    let label: String
    let value: Double
    let isBold: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: isBold ? 15 : 14, weight: isBold ? .bold : .regular))
            Spacer()
            Text("$\(value, specifier: "%.2f")")
                .font(.system(size: isBold ? 15 : 14, weight: isBold ? .bold : .regular))
        }
        .foregroundColor(.primary)
    }
}

#Preview {
    ReceiptProcessingView(
        viewModel: ReceiptScannerViewModel(),
        capturedImage: nil
    )
}
