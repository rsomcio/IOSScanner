//
//  ContentView.swift
//  Scanner
//
//  Created by Ray Somcio on 12/2/25.
//

import SwiftUI
import UIKit

@Observable
class ReceiptScannerViewModel {
    var ocrText: String = ""
    var parsedReceipt: ParsedReceipt?
    var csvOutput: String = ""
    var isProcessing: Bool = false
    var errorMessage: String?
    var currentStep: String = ""
    var validationErrors: [String] = []
    var showValidationWarning: Bool = false

    private let visionService = VisionOCRService()
    private var parserService: ReceiptParserService?

    // Hardcoded API key
    private let apiKey = "YOUR_OPENAI_API_KEY_HERE"

    func initialize() {
        parserService = ReceiptParserService(apiKey: apiKey)
    }

    func processReceipt(image: UIImage) async {
        isProcessing = true
        errorMessage = nil
        validationErrors = []
        showValidationWarning = false
        currentStep = ""

        do {
            // Step 1: OCR
            currentStep = "Scanning receipt with Apple Vision..."
            ocrText = try await visionService.recognizeText(from: image)

            // Step 2: Parse with LLM
            currentStep = "Parsing items with AI..."
            guard let parser = parserService else {
                throw ScannerError.notInitialized
            }
            parsedReceipt = try await parser.parseReceipt(ocrText: ocrText)

            // Step 3: Validate
            currentStep = "Validating data..."
            if let receipt = parsedReceipt {
                let validation = await parser.validateReceipt(receipt)
                if !validation.isValid {
                    validationErrors = validation.errors
                    showValidationWarning = true
                }
            }

            // Step 4: Generate CSV
            currentStep = "Generating CSV..."
            let exporter = CSVExportService()
            if let receipt = parsedReceipt {
                csvOutput = exporter.exportToCSV(receipt: receipt)
            }

            currentStep = "Complete!"
        } catch {
            errorMessage = error.localizedDescription
            currentStep = "Error occurred"
        }

        isProcessing = false
    }

    func exportCSV() throws -> URL {
        let exporter = CSVExportService()
        let filename = exporter.generateFilename()
        return try exporter.saveToFile(csv: csvOutput, filename: filename)
    }

    func reset() {
        ocrText = ""
        parsedReceipt = nil
        csvOutput = ""
        errorMessage = nil
        currentStep = ""
        validationErrors = []
        showValidationWarning = false
    }
}

struct ContentView: View {
    @State private var viewModel = ReceiptScannerViewModel()
    @State private var selectedImage: String = "IMG_8168"
    @State private var showingShareSheet = false
    @State private var shareURL: URL?
    @State private var capturedImage: UIImage?
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var showingImageSourcePicker = false
    @State private var imageSourceType: ImageSourceType = .assets

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 50))
                            .foregroundStyle(.blue)
                        Text("Receipt Scanner")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("OCR + AI Parsing")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)

                    // Image selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select Receipt Image")
                            .font(.headline)

                        // Image source picker
                        Picker("Image Source", selection: $imageSourceType) {
                            Text("Test Images").tag(ImageSourceType.assets)
                            Text("Camera").tag(ImageSourceType.camera)
                            Text("Photo Library").tag(ImageSourceType.photoLibrary)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: imageSourceType) { _, newValue in
                            // Reset parsed results when switching modes
                            if viewModel.parsedReceipt != nil {
                                viewModel.reset()
                            }

                            switch newValue {
                            case .camera:
                                showingCamera = true
                            case .photoLibrary:
                                showingPhotoLibrary = true
                            case .assets:
                                capturedImage = nil
                            }
                        }

                        // Asset picker (only shown when using test images)
                        if imageSourceType == .assets {
                            Picker("Select Receipt", selection: $selectedImage) {
                                Text("Receipt 1 (IMG_8168)").tag("IMG_8168")
                                Text("Receipt 2 (IMG_8171)").tag("IMG_8171")
                            }
                            .pickerStyle(.segmented)
                        }

                        // Display image
                        if let capturedImage = capturedImage {
                            Image(uiImage: capturedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 300)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(radius: 4)
                        } else if imageSourceType == .assets, let image = UIImage(named: selectedImage) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 300)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(radius: 4)
                        } else if imageSourceType != .assets {
                            Button(action: {
                                switch imageSourceType {
                                case .camera:
                                    showingCamera = true
                                case .photoLibrary:
                                    showingPhotoLibrary = true
                                case .assets:
                                    break
                                }
                            }) {
                                VStack(spacing: 12) {
                                    Image(systemName: imageSourceType == .camera ? "camera.fill" : "photo.fill")
                                        .font(.system(size: 50))
                                        .foregroundStyle(.gray)
                                    Text(imageSourceType == .camera ? "Tap to Take Photo" : "Tap to Choose Photo")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            Task {
                                viewModel.initialize()

                                let imageToProcess: UIImage?
                                switch imageSourceType {
                                case .assets:
                                    imageToProcess = UIImage(named: selectedImage)
                                case .camera, .photoLibrary:
                                    imageToProcess = capturedImage
                                }

                                if let image = imageToProcess {
                                    await viewModel.processReceipt(image: image)
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "scanner")
                                Text("Scan & Parse Receipt")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.isProcessing ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(viewModel.isProcessing || (imageSourceType != .assets && capturedImage == nil))

                        if !viewModel.csvOutput.isEmpty {
                            Button(action: {
                                do {
                                    shareURL = try viewModel.exportCSV()
                                    showingShareSheet = true
                                } catch {
                                    viewModel.errorMessage = "Failed to export CSV: \(error.localizedDescription)"
                                }
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Export CSV")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        }

                        if viewModel.parsedReceipt != nil {
                            Button(action: {
                                viewModel.reset()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("Reset")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Status indicator
                    if viewModel.isProcessing {
                        VStack(spacing: 8) {
                            ProgressView()
                            Text(viewModel.currentStep)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }

                    // Error message
                    if let error = viewModel.errorMessage {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text("Error")
                                    .font(.headline)
                                    .foregroundColor(.red)
                            }
                            Text(error)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }

                    // Validation warnings
                    if viewModel.showValidationWarning && !viewModel.validationErrors.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                Text("Validation Warnings")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                            }
                            ForEach(viewModel.validationErrors, id: \.self) { error in
                                Text("• \(error)")
                                    .font(.caption)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }

                    // OCR Text
                    if !viewModel.ocrText.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("OCR Text")
                                .font(.headline)
                            Text(viewModel.ocrText)
                                .font(.system(.caption, design: .monospaced))
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .textSelection(.enabled)
                        }
                        .padding(.horizontal)
                    }

                    // Parsed Items
                    if let receipt = viewModel.parsedReceipt {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Parsed Receipt")
                                .font(.headline)

                            if let store = receipt.storeName {
                                HStack {
                                    Text("Store:")
                                        .fontWeight(.semibold)
                                    Text(store)
                                }
                                .font(.caption)
                            }

                            if let date = receipt.date {
                                HStack {
                                    Text("Date:")
                                        .fontWeight(.semibold)
                                    Text(date)
                                }
                                .font(.caption)
                            }

                            Divider()

                            Text("Items:")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            ForEach(receipt.items) { item in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    HStack {
                                        Text("\(item.quantity, specifier: "%.0f") × $\(item.unitPrice, specifier: "%.2f")")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("$\(item.lineTotal, specifier: "%.2f")")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    }
                                }
                                .padding(.vertical, 4)
                            }

                            Divider()

                            VStack(spacing: 4) {
                                HStack {
                                    Text("Subtotal:")
                                    Spacer()
                                    Text("$\(receipt.subtotal, specifier: "%.2f")")
                                }
                                .font(.caption)

                                HStack {
                                    Text("Tax:")
                                    Spacer()
                                    Text("$\(receipt.tax, specifier: "%.2f")")
                                }
                                .font(.caption)

                                HStack {
                                    Text("Total:")
                                        .fontWeight(.bold)
                                    Spacer()
                                    Text("$\(receipt.total, specifier: "%.2f")")
                                        .fontWeight(.bold)
                                }
                                .font(.callout)
                                .padding(.top, 4)
                            }
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }

                    // CSV Output
                    if !viewModel.csvOutput.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CSV Output")
                                .font(.headline)
                            Text(viewModel.csvOutput)
                                .font(.system(.caption2, design: .monospaced))
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                                .textSelection(.enabled)
                        }
                        .padding(.horizontal)
                    }

                }
            }
            .navigationTitle("Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingShareSheet) {
                if let url = shareURL {
                    ShareSheet(items: [url])
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraPicker(image: $capturedImage)
                    .onDisappear {
                        if capturedImage == nil {
                            imageSourceType = .assets
                        }
                    }
            }
            .sheet(isPresented: $showingPhotoLibrary) {
                PhotoLibraryPicker(image: $capturedImage)
                    .onDisappear {
                        if capturedImage == nil {
                            imageSourceType = .assets
                        }
                    }
            }
        }
        .onAppear {
            viewModel.initialize()
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ContentView()
}
