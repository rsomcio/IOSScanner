//
//  EditableLineItemRow.swift
//  Scanner
//
//  Created by Claude Code on 12/10/25.
//

import SwiftUI

struct EditableLineItemRow: View {
    @Binding var item: EditableReceiptItem
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Item name
            VStack(alignment: .leading, spacing: 4) {
                Text("Item Name")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                TextField("e.g., Apples", text: $item.name)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 14))
            }

            // Quantity and Unit Price in a row
            HStack(spacing: 12) {
                // Quantity
                VStack(alignment: .leading, spacing: 4) {
                    Text("Qty")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    TextField("0", value: $item.quantity, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 14))
                        .frame(width: 60)
                }

                // Unit Price
                VStack(alignment: .leading, spacing: 4) {
                    Text("Unit Price")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Text("$")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        TextField("0.00", value: $item.unitPrice, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 14))
                    }
                }

                Spacer()

                // Line total (read-only, auto-calculated)
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    Text("$\(item.lineTotal, specifier: "%.2f")")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }

            // Delete button
            Button(action: onDelete) {
                HStack {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                    Text("Remove Item")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    EditableLineItemRow(
        item: .constant(EditableReceiptItem(name: "Bananas", quantity: 3, unitPrice: 1.99)),
        onDelete: {}
    )
    .padding()
}
