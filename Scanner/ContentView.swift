//
//  ContentView.swift
//  Scanner
//
//  Created by Ray Somcio on 12/2/25.
//

import SwiftUI
import SwiftData
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
    private let apiKey = ""

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
            print("DEBUG: Starting OCR...")
            ocrText = try await visionService.recognizeText(from: image)
            print("DEBUG: OCR complete. Text length: \(ocrText.count)")

            // Step 2: Parse with LLM
            currentStep = "Parsing items with AI..."
            print("DEBUG: Starting AI parsing...")
            guard let parser = parserService else {
                throw ScannerError.notInitialized
            }
            parsedReceipt = try await parser.parseReceipt(ocrText: ocrText)
            print("DEBUG: Parsing complete. Items: \(parsedReceipt?.items.count ?? 0)")

            // Step 3: Validate
            currentStep = "Validating data..."
            print("DEBUG: Starting validation...")
            if let receipt = parsedReceipt {
                let validation = parser.validateReceipt(receipt)
                print("DEBUG: Validation complete. Valid: \(validation.isValid)")
                if !validation.isValid {
                    validationErrors = validation.errors
                    showValidationWarning = true
                    print("DEBUG: Validation errors: \(validation.errors)")
                }
            }
            print("DEBUG: Validation step complete")

            // Step 4: Generate CSV
            currentStep = "Generating CSV..."
            print("DEBUG: Starting CSV generation...")
            let exporter = CSVExportService()
            if let receipt = parsedReceipt {
                csvOutput = exporter.exportToCSV(receipt: receipt)
                print("DEBUG: CSV generated. Length: \(csvOutput.count)")
            }

            currentStep = "Complete!"
            print("DEBUG: All steps complete!")
        } catch {
            print("DEBUG: Error occurred: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            currentStep = "Error occurred"
        }

        isProcessing = false
        print("DEBUG: Processing flag set to false")
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
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedReceipt.createdAt, order: .reverse)
    private var allReceipts: [SavedReceipt]
    @Query private var userAccounts: [UserAccount]

    @State private var viewModel = ReceiptScannerViewModel()
    @State private var showingShareSheet = false
    @State private var shareURL: URL?
    @State private var capturedImage: UIImage?
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var showingSavedReceipts = false
    @State private var showingSaveConfirmation = false
    @State private var showingProcessingView = false
    @State private var selectedReceiptID: UUID?
    @State private var showingReceiptDetail = false
    @State private var showingProfileMenu = false
    @State private var showingProfile = false
    @State private var showingSwitchProfile = false

    // User session for tracking current user
    private var userSession = UserSession.shared

    private var currentUser: UserAccount? {
        userAccounts.first(where: { $0.email == userSession.currentUserEmail })
    }

    // Filter receipts to show only current user's receipts OR receipts with no owner (shared/legacy)
    private var savedReceipts: [SavedReceipt] {
        guard let currentEmail = userSession.currentUserEmail else {
            // No user logged in, show all receipts with no owner
            return allReceipts.filter { $0.owner == nil }
        }

        // Show receipts owned by current user OR receipts with no owner
        return allReceipts.filter { receipt in
            receipt.owner == nil || receipt.owner?.email == currentEmail
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top Navigation Bar
                HStack {
                    Button(action: {
                        // Back action - currently no-op since this is the main screen
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.onboardingText)
                            .frame(width: 32, height: 32)
                    }

                    Text(currentUser != nil ? "Welcome back, \(currentUser?.fullName ?? "User")" : "Welcome to Recibo")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundColor(Color.onboardingText)

                    Spacer()

                    Menu {
                        Button(action: {
                            showingProfile = true
                        }) {
                            Label("View Profile", systemImage: "person.circle")
                        }

                        Button(action: {
                            showingSwitchProfile = true
                        }) {
                            Label("Switch Profile", systemImage: "arrow.left.arrow.right.circle")
                        }

                        Divider()

                        Button(role: .destructive, action: {
                            logOff()
                        }) {
                            Label("Log Off", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 20))
                            .foregroundColor(Color.onboardingText)
                            .frame(width: 32, height: 32)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.onboardingBackground)

                Divider()

                ScrollView {
                    VStack(spacing: 16) {
                        // Top spacer
                        Color.clear.frame(height: 8)

                        // Account Balance Section
                        VStack(spacing: 8) {
                            Text("Total Receipts Value")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(Color.black.opacity(0.6))

                            Text(formatCurrency(totalReceiptsValue))
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(Color.onboardingText)

                            Text("\(savedReceipts.count) receipts")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(Color.black.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .padding(.horizontal)

                        // Bar Chart Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Spending Over Time")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.onboardingText)
                                .padding(.horizontal, 16)
                                .padding(.top, 16)

                            if savedReceipts.isEmpty {
                                Text("No receipts yet")
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundColor(Color.black.opacity(0.5))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 40)
                            } else {
                                VStack(spacing: 8) {
                                    // Vertical bar chart
                                    GeometryReader { geometry in
                                        HStack(alignment: .bottom, spacing: 8) {
                                            ForEach(receiptsByDate, id: \.date) { item in
                                                VStack(spacing: 4) {
                                                    // Bar
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .fill(Color.onboardingPrimary)
                                                        .frame(width: max(12, (geometry.size.width - CGFloat(receiptsByDate.count - 1) * 8) / CGFloat(receiptsByDate.count)),
                                                               height: max(20, geometry.size.height * 0.8 * CGFloat(item.percentage)))
                                                }
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .frame(height: 120)
                                    .padding(.horizontal, 16)

                                    // Date labels
                                    HStack(alignment: .top, spacing: 8) {
                                        ForEach(receiptsByDate, id: \.date) { item in
                                            Text(item.date)
                                                .font(.system(size: 10, weight: .regular, design: .rounded))
                                                .foregroundColor(Color.black.opacity(0.6))
                                                .frame(maxWidth: .infinity)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.7)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 16)
                                }
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .padding(.horizontal)

                    // Action buttons card
                    HStack(spacing: 20) {
                        // Camera button
                        Button(action: {
                            if viewModel.parsedReceipt != nil {
                                viewModel.reset()
                            }
                            showingCamera = true
                        }) {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(Color.onboardingSecondary)
                                        .frame(width: 56, height: 56)

                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color.onboardingPrimary)
                                }

                                Text("Scan")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(Color.onboardingText)
                            }
                        }

                        // Upload button
                        Button(action: {
                            if viewModel.parsedReceipt != nil {
                                viewModel.reset()
                            }
                            showingPhotoLibrary = true
                        }) {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(Color.onboardingSecondary)
                                        .frame(width: 56, height: 56)

                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color.onboardingPrimary)
                                }

                                Text("Upload")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(Color.onboardingText)
                            }
                        }

                        Spacer()
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    .padding(.horizontal)

                    // Transactions Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Transactions")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.onboardingText)

                            Spacer()

                            Button(action: {
                                showingSavedReceipts = true
                            }) {
                                Text("see all")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(Color.onboardingPrimary)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        if savedReceipts.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color.onboardingPrimary.opacity(0.4))
                                Text("No receipts yet")
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundColor(Color.black.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(Array(savedReceipts.prefix(5).enumerated()), id: \.element.id) { index, receipt in
                                    Button(action: {
                                        selectedReceiptID = receipt.id
                                        showingReceiptDetail = true
                                    }) {
                                        HStack(spacing: 12) {
                                            // Icon
                                            ZStack {
                                                Circle()
                                                    .fill(Color.onboardingSecondary)
                                                    .frame(width: 40, height: 40)

                                                Image(systemName: "arrow.up")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(Color.onboardingPrimary)
                                            }

                                            // Receipt info
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(receipt.storeName ?? "Unknown Store")
                                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                                    .foregroundColor(Color.onboardingText)

                                                Text("Sent by you • \(formatDate(receipt.date))")
                                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                                    .foregroundColor(Color.black.opacity(0.5))
                                            }

                                            Spacer()

                                            // Amount
                                            VStack(alignment: .trailing, spacing: 2) {
                                                Text(formatCurrency(receipt.total))
                                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                                    .foregroundColor(Color.onboardingText)

                                                Text("ID: \(receipt.id.uuidString.prefix(6))")
                                                    .font(.system(size: 11, weight: .regular, design: .rounded))
                                                    .foregroundColor(Color.black.opacity(0.5))
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                    }

                                    if index < min(4, savedReceipts.count - 1) {
                                        Divider()
                                            .padding(.leading, 64)
                                    }
                                }
                            }
                            .padding(.bottom, 8)
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    .padding(.horizontal)

                        // Bottom spacer
                        Color.clear.frame(height: 16)
                    }
                }
                .background(Color.onboardingBackground)

                // Bottom Navigation Bar
                Divider()

                HStack(spacing: 0) {
                    // Home tab
                    Button(action: {}) {
                        VStack(spacing: 4) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 24))
                            Text("Home")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(Color.onboardingPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }

                    // Cards tab
                    Button(action: {}) {
                        VStack(spacing: 4) {
                            Image(systemName: "creditcard")
                                .font(.system(size: 24))
                            Text("Cards")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(Color.black.opacity(0.4))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }

                    // Analytics tab
                    Button(action: {}) {
                        VStack(spacing: 4) {
                            Image(systemName: "chart.bar")
                                .font(.system(size: 24))
                            Text("Analytics")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(Color.black.opacity(0.4))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }

                    // Settings tab
                    Button(action: {}) {
                        VStack(spacing: 4) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 24))
                            Text("Settings")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(Color.black.opacity(0.4))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
                .background(Color.white)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingShareSheet) {
                if let url = shareURL {
                    ShareSheet(items: [url])
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraPicker(image: $capturedImage)
            }
            .sheet(isPresented: $showingPhotoLibrary) {
                PhotoLibraryPicker(image: $capturedImage)
            }
            .onChange(of: capturedImage) { oldValue, newValue in
                if newValue != nil {
                    showingProcessingView = true
                }
            }
            .onChange(of: showingProcessingView) { oldValue, newValue in
                // Clear captured image when processing view is dismissed
                if !newValue {
                    capturedImage = nil
                }
            }
            .sheet(isPresented: $showingSavedReceipts) {
                SavedReceiptsView()
            }
            .sheet(isPresented: $showingReceiptDetail) {
                if let receiptID = selectedReceiptID {
                    ReceiptDetailView(receiptID: receiptID)
                }
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView(user: currentUser)
            }
            .sheet(isPresented: $showingSwitchProfile) {
                ProfileSwitcherView()
            }
            .fullScreenCover(isPresented: $showingProcessingView) {
                ReceiptProcessingView(viewModel: viewModel, capturedImage: capturedImage)
                    .onAppear {
                        Task {
                            viewModel.initialize()
                            if let image = capturedImage {
                                await viewModel.processReceipt(image: image)
                            }
                        }
                    }
            }
            .alert("Receipt Saved", isPresented: $showingSaveConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your receipt has been saved successfully")
            }
        }
        .onAppear {
            viewModel.initialize()
        }
    }

    // MARK: - Computed Properties
    private var totalReceiptsValue: Double {
        savedReceipts.reduce(0) { $0 + $1.total }
    }

    private var receiptsByStore: [(store: String, total: Double, percentage: Double)] {
        let maxTotal = savedReceipts.reduce(0.0) { max($0, $1.total) }
        guard maxTotal > 0 else { return [] }

        let grouped = Dictionary(grouping: savedReceipts) { $0.storeName ?? "Unknown" }
        return grouped.map { (store, receipts) in
            let total = receipts.reduce(0) { $0 + $1.total }
            return (store: store, total: total, percentage: total / maxTotal)
        }
        .sorted { $0.total > $1.total }
        .prefix(5)
        .map { $0 }
    }

    private var receiptsByDate: [(date: String, total: Double, percentage: Double)] {
        let maxTotal = savedReceipts.reduce(0.0) { max($0, $1.total) }
        guard maxTotal > 0 else { return [] }

        // Group receipts by date
        let grouped = Dictionary(grouping: savedReceipts) { receipt -> String in
            guard let dateString = receipt.date else { return "Unknown" }

            // Parse and format the date to just show MM/dd
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            if let date = dateFormatter.date(from: dateString) {
                dateFormatter.dateFormat = "MM/dd"
                return dateFormatter.string(from: date)
            }

            return dateString
        }

        // Calculate totals and percentages, then sort by date (oldest to newest)
        return grouped.map { (dateStr, receipts) -> (date: String, total: Double, percentage: Double, sortDate: Date?) in
            let total = receipts.reduce(0) { $0 + $1.total }

            // Parse date for sorting
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd"
            let sortDate = dateFormatter.date(from: dateStr)

            return (date: dateStr, total: total, percentage: total / maxTotal, sortDate: sortDate)
        }
        .sorted { (item1, item2) in
            // Sort by date, with nil dates at the end
            if let date1 = item1.sortDate, let date2 = item2.sortDate {
                return date1 < date2  // Oldest to newest (latest on the right)
            } else if item1.sortDate != nil {
                return true
            } else {
                return false
            }
        }
        .map { (date: $0.date, total: $0.total, percentage: $0.percentage) }
    }

    // MARK: - Actions

    private func logOff() {
        // Clear the current user session
        UserSession.shared.clearSession()
        // The app will automatically show ProfileSwitcherView on next view update
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    private func formatDate(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "Unknown date" }

        // Try to parse the date string and format it
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        if let date = dateFormatter.date(from: dateString) {
            dateFormatter.dateFormat = "MMM dd"
            return dateFormatter.string(from: date)
        }

        // If parsing fails, return the original string
        return dateString
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
