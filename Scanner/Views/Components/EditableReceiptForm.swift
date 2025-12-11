//
//  EditableReceiptForm.swift
//  Scanner
//
//  Created by Claude Code on 12/10/25.
//

import SwiftUI

struct EditableReceiptForm: View {
    @Binding var receipt: EditableReceipt

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Receipt Details")
                .font(.system(size: 18, weight: .semibold))
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 16) {
                // Vendor autocomplete
                VendorAutocompleteField(vendorName: $receipt.storeName)

                Divider()

                // Date field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Date")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)

                    TextField("YYYY-MM-DD", text: $receipt.date)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 14))
                }

                Divider()

                // Items section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Items (\(receipt.items.count))")
                            .font(.system(size: 15, weight: .semibold))

                        Spacer()

                        Button(action: {
                            receipt.addItem()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Item")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                        }
                    }

                    ForEach($receipt.items) { $item in
                        EditableLineItemRow(
                            item: $item,
                            onDelete: {
                                if let index = receipt.items.firstIndex(where: { $0.id == item.id }) {
                                    receipt.removeItem(at: index)
                                }
                            }
                        )
                    }
                }

                Divider()

                // Totals section
                VStack(spacing: 12) {
                    // Subtotal (read-only, auto-calculated)
                    HStack {
                        Text("Subtotal")
                            .font(.system(size: 14))
                        Spacer()
                        Text("$\(receipt.subtotal, specifier: "%.2f")")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                    }

                    // Tax (editable)
                    HStack {
                        Text("Tax")
                            .font(.system(size: 14))

                        Spacer()

                        HStack(spacing: 4) {
                            Text("$")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            TextField("0.00", value: $receipt.tax, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 14))
                                .frame(width: 80)
                                .multilineTextAlignment(.trailing)
                        }
                    }

                    // Total (read-only, auto-calculated)
                    HStack {
                        Text("Total")
                            .font(.system(size: 15, weight: .bold))
                        Spacer()
                        Text("$\(receipt.total, specifier: "%.2f")")
                            .font(.system(size: 15, weight: .bold))
                    }
                }
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
}

#Preview {
    EditableReceiptForm(receipt: .constant(EditableReceipt(
        storeName: "Whole Foods",
        date: "2024-12-10",
        items: [
            EditableReceiptItem(name: "Bananas", quantity: 3, unitPrice: 1.99),
            EditableReceiptItem(name: "Apples", quantity: 5, unitPrice: 2.49)
        ],
        tax: 1.25
    )))
    .modelContainer(for: [SavedReceipt.self, SavedReceiptItem.self])
}
