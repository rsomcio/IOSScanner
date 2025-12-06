# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Receipt Scanner (Recibo) is an iOS app (iOS 18.5+, Xcode 16.4+) that combines **Apple Vision OCR** with **OpenAI GPT-4o mini** to extract and parse grocery receipt data, storing them in a **SwiftData** database with CSV export capabilities.

**Processing Pipeline:**
```
Receipt Image → Apple Vision (on-device OCR) → GPT-4o mini (cloud parsing) → SwiftData Storage → CSV Export
```

**Key Features:**
- Camera and photo library receipt capture
- On-device OCR with Apple Vision
- AI-powered receipt parsing with GPT-4o mini
- Local persistent storage with SwiftData
- Search and filter saved receipts
- Export individual or all receipts to CSV

## Build Commands

**Standard Build:**
```bash
cd /Volumes/data/code/src/github.com/rsomcio/Scanner
xcodebuild -project Scanner.xcodeproj -scheme Scanner -destination 'platform=iOS Simulator,name=iPhone 16' build
```

**Clean Build:**
```bash
xcodebuild -project Scanner.xcodeproj -scheme Scanner -destination 'platform=iOS Simulator,name=iPhone 16' clean build
```

**Run in Simulator:**
- Open `Scanner.xcodeproj` in Xcode
- Press `Cmd+R` or use Product → Run
- Select any iOS 18.5+ simulator

**Test Images:**
- Located in `Assets.xcassets/IMG_8168` and `Assets.xcassets/IMG_8171`
- These are the receipt images used for testing

## Architecture

### Service Layer (Actor-based)

All services use Swift actors for thread-safe async/await operations:

1. **VisionOCRService** (`Services/VisionOCRService.swift`)
   - On-device text recognition using Apple Vision framework
   - `recognizeText(from: UIImage)` - returns plain text
   - `recognizeTextDetailed(from: UIImage)` - returns text with confidence scores and bounding boxes
   - Configuration: `.accurate` mode, language correction enabled, auto language detection (iOS 16+)

2. **ReceiptParserService** (`Services/ReceiptParserService.swift`)
   - OpenAI GPT-4o mini API client
   - `parseReceipt(ocrText: String)` - sends OCR text to GPT-4o mini
   - `validateReceipt(ParsedReceipt)` - validates parsed data against business rules
   - **CRITICAL**: Uses OpenAI Structured Outputs with `strict: true` mode

3. **CSVExportService** (`Services/CSVExportService.swift`)
   - Converts `ParsedReceipt` to CSV format
   - `exportToCSV(receipt:)` - generates CSV string
   - `saveToFile(csv:filename:)` - saves to Documents directory
   - Handles CSV escaping (quotes, commas, newlines)

### Data Models (`Models/Receipt.swift`)

**API Response Models (Temporary, for parsing):**
- **ReceiptItem**: Single line item (name, quantity, unitPrice, lineTotal) - struct
- **ParsedReceipt**: Complete receipt (storeName?, date?, items[], subtotal, tax, total) - struct
- Both are `Codable` for JSON serialization with OpenAI API

**SwiftData Persistent Models:**
- **SavedReceipt**: `@Model` class for persisted receipts
  - Properties: id (unique UUID), storeName, date, subtotal, tax, total, createdAt, ocrText
  - Has one-to-many relationship with `SavedReceiptItem` (cascade delete)
  - Includes convenience initializer: `init(from: ParsedReceipt, ocrText: String?)`
- **SavedReceiptItem**: `@Model` class for persisted line items
  - Properties: id, name, quantity, unitPrice, lineTotal
  - Has back-reference to parent `SavedReceipt`
  - Includes convenience initializer: `init(from: ReceiptItem)`

**Other Models:**
- **RecognizedTextBlock**: OCR result with confidence and bounding box
- **ScannerError**: Custom error types

### UI Layer

**ContentView.swift**
- **ReceiptScannerViewModel**: `@Observable` class managing app state
- Uses `@Environment(\.modelContext)` for SwiftData database access
- Uses `@Query` to display count of saved receipts
- **Processing flow**:
  1. Load image from assets, camera, or photo library
  2. VisionOCRService.recognizeText() → extract text
  3. ReceiptParserService.parseReceipt() → parse items
  4. ReceiptParserService.validateReceipt() → validate data
  5. Save to SwiftData database (optional)
  6. CSVExportService.exportToCSV() → generate CSV (optional)
- **API Key**: Hardcoded in ViewModel (line 26 of ContentView.swift)
- **Navigation**: Custom header with "Welcome to Recibo" title and notification bell

**SavedReceiptsView.swift**
- Displays list of all saved receipts from SwiftData
- Search functionality by store name
- Swipe-to-delete receipts
- Tap receipt to view detail view
- Detail view shows full receipt with export option

**CameraPicker.swift / PhotoLibraryPicker.swift**
- UIViewControllerRepresentable wrappers for native image capture

## Critical Implementation Details

### OpenAI Structured Outputs Schema

**IMPORTANT**: When using OpenAI's Structured Outputs with `strict: true`, ALL properties must be in the `required` array. Optional fields use `anyOf` pattern:

```swift
"storeName": [
    "anyOf": [
        ["type": "string"],
        ["type": "null"]
    ]
]
// Then include in required: ["storeName", "date", "items", "subtotal", "tax", "total"]
```

**Common Error**: `Invalid schema for response_format 'receipt_parser'` means a property is missing from `required` array.

### API Request Configuration

```swift
Model: "gpt-4o-mini"
Temperature: 0.1 (deterministic parsing)
Max Tokens: 2000
Response Format: JSON Schema with strict: true
```

### Validation Tolerances

- Price calculation: ±$0.02
- Subtotal calculation: ±$0.10
- Total calculation: ±$0.02

These tolerances account for OCR errors and rounding.

## Debugging

**Enable Debug Logging:**
The app already has debug logging in `ReceiptParserService.swift` (lines 125-131):
- Prints API URL, request method, API key prefix
- Prints first 500 chars of request body
- Prints detailed error messages from OpenAI

**View Console Output:**
- Run app in Xcode (Cmd+R)
- Open Debug Console (Cmd+Shift+Y)
- Look for lines starting with `=== API Request ===`

**Common Issues:**

1. **Schema validation errors**: Check all properties are in `required` array with correct types
2. **API rate limits**: GPT-4o mini has rate limits based on tier
3. **OCR failures**: Ensure images are clear, high-contrast receipts
4. **Parsing inaccuracies**: Adjust system prompt or temperature (currently 0.1)

## Key Constraints

- **iOS Version**: Minimum iOS 18.5
- **Xcode Version**: 16.4 or later
- **Swift Version**: 5.0
- **API Key Location**: Hardcoded in `ContentView.swift:26` (not production-safe)
- **OCR Language**: English only (configurable in VisionOCRService)
- **Cost**: ~$0.0003 per receipt (GPT-4o mini pricing)

## Making Changes

### Adding New Receipt Fields

1. Update `ParsedReceipt` struct in `Models/Receipt.swift` (API response model)
2. Update `SavedReceipt` @Model class in `Models/Receipt.swift` (SwiftData model)
3. Update JSON schema in `ReceiptParserService.swift` (lines 29-88)
   - Add new field to `properties` dictionary
   - Add new field to `required` array (even if optional, use `anyOf` pattern)
4. Update CSV headers in `CSVExportService.swift`
5. Update UI in `ContentView.swift` and `SavedReceiptsView.swift` to display new field
6. Update convenience initializer `SavedReceipt.init(from: ParsedReceipt)` if needed

### Changing LLM Provider

To switch from OpenAI to another provider (Claude, Gemini):

1. Create new service file (e.g., `ClaudeParserService.swift`)
2. Implement same interface: `parseReceipt(ocrText:)` and `validateReceipt()`
3. Replace `ReceiptParserService` initialization in `ContentView.swift:29`
4. Update API key storage/retrieval

### Modifying OCR Behavior

All OCR settings are in `VisionOCRService.swift:41-52`:
- `recognitionLevel`: `.accurate` or `.fast`
- `usesLanguageCorrection`: true/false
- `recognitionLanguages`: array of language codes
- `automaticallyDetectsLanguage`: iOS 16+ feature

## Security Notes

- **API Key**: Currently hardcoded in source code (line 26 of `ContentView.swift`)
- **For Production**: Move API key to:
  - Backend proxy service, OR
  - Environment variables/Xcode build configurations, OR
  - Keychain (KeychainManager.swift exists but is unused)
- **Privacy**: Receipt images never leave device (only OCR text sent to OpenAI)
- **Data Retention**: Consider enabling OpenAI zero-retention policy for production

## File Organization

```
Scanner/
├── Models/Receipt.swift           # Data models (API structs + SwiftData @Model classes)
├── Services/
│   ├── VisionOCRService.swift     # Apple Vision OCR (actor)
│   ├── ReceiptParserService.swift # OpenAI API client (actor)
│   ├── CSVExportService.swift     # CSV generation (struct)
│   ├── CameraService.swift        # Camera/photo library capture
│   └── KeychainManager.swift      # Unused - API key is hardcoded
├── ContentView.swift              # Main UI + ViewModel (@Observable)
├── SavedReceiptsView.swift        # Saved receipts list and detail views
├── ScannerApp.swift               # App entry point + SwiftData container
└── Assets.xcassets/
    ├── IMG_8168.imageset/         # Test receipt 1
    ├── IMG_8171.imageset/         # Test receipt 2
    └── reciboIcon.imageset/       # App icon
```

## Testing Receipt Images

To add new test receipts:

1. Add image to `Assets.xcassets` in Xcode
2. Get asset name (e.g., "IMG_8172")
3. Add to picker in `ContentView.swift` around line 130:
   ```swift
   Text("Receipt 3 (IMG_8172)").tag("IMG_8172")
   ```
4. Image will be available via `UIImage(named: selectedImage)`

## Performance Characteristics

- **OCR Time**: 1-2 seconds (on-device)
- **API Time**: 1-3 seconds (network dependent)
- **Database Save**: <100ms (SwiftData)
- **Total**: 2-5 seconds end-to-end (scan to save)
- **Memory**: ~50-100MB during OCR processing
- **Accuracy**: 95%+ on clear printed receipts
- **Storage**: ~2KB per receipt, so 10,000 receipts ≈ 20MB

## SwiftData Database

### Setup

The app uses SwiftData for local persistent storage. The model container is configured in `ScannerApp.swift`:

```swift
.modelContainer(for: [SavedReceipt.self, SavedReceiptItem.self])
```

### Querying Receipts

**In ContentView:**
```swift
@Environment(\.modelContext) private var modelContext
@Query(sort: \SavedReceipt.createdAt, order: .reverse)
private var savedReceipts: [SavedReceipt]
```

**Search by store name:**
```swift
@Query(filter: #Predicate<SavedReceipt> { receipt in
    receipt.storeName?.localizedCaseInsensitiveContains(searchText) ?? false
})
var filteredReceipts: [SavedReceipt]
```

### Saving Receipts

```swift
let savedReceipt = SavedReceipt(from: parsedReceipt, ocrText: viewModel.ocrText)
modelContext.insert(savedReceipt)
try modelContext.save()
```

### Deleting Receipts

```swift
modelContext.delete(receipt)  // Cascade deletes all items
try modelContext.save()
```

### Schema Changes

SwiftData handles lightweight migrations automatically for additive changes (new properties). For complex schema changes:

1. Create new `VersionedSchema` in `Models/Receipt.swift`
2. Define `SchemaMigrationPlan` with migration steps
3. Update model container in `ScannerApp.swift`

### Troubleshooting Database Issues

**Reset database (delete all data):**
```swift
// In Xcode: Product → Clean Build Folder
// Then delete app from simulator/device to clear database
```

**Inspect database location:**
```swift
print(FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask))
// Database: default.store in Application Support/
```

## Xcode Preview Issues

If Xcode previews fail with "CouldNotLoadInputObjectFile" errors:

1. **Clean DerivedData:**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/Scanner-*
   ```

2. **Clean Build Folder:** In Xcode: `Product` → `Clean Build Folder` (Cmd+Shift+K)

3. **Rebuild:**
   ```bash
   xcodebuild -project Scanner.xcodeproj -scheme Scanner -destination 'platform=iOS Simulator,name=iPhone 16' clean build
   ```

4. **Restart Xcode** and resume preview (Cmd+Option+P)
