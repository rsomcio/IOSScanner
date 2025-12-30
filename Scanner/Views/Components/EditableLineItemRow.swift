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
            // Item name with category badge
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Item Name")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    TextField("e.g., Apples", text: $item.name)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 14))
                }

                // Category badge
                HStack(spacing: 4) {
                    Image(systemName: item.category.icon)
                        .font(.system(size: 10))
                    Text(item.category.rawValue)
                        .font(.system(size: 10, weight: .medium))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(item.category.color.opacity(0.2))
                .foregroundColor(item.category.color)
                .cornerRadius(6)
                .padding(.top, 18)
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
            }

            // Category picker
            VStack(alignment: .leading, spacing: 4) {
                Text("Category")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                Picker("Category", selection: $item.category) {
                    ForEach(ItemCategory.allCases, id: \.self) { category in
                        HStack {
                            Image(systemName: category.icon)
                            Text(category.rawValue)
                        }
                        .tag(category)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Discount section
            VStack(alignment: .leading, spacing: 8) {
                Text("Discount")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    // Discount type picker
                    Picker("Discount Type", selection: $item.discountType) {
                        ForEach(DiscountType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: .infinity)

                    // Discount value field (only show if discount type is not none)
                    if item.discountType != .none {
                        HStack(spacing: 4) {
                            Text(item.discountType == .dollar ? "$" : "%")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            TextField("0.00", value: $item.discountValue, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 14))
                                .frame(width: 70)
                        }
                    }
                }
            }

            // Price breakdown with discount
            VStack(alignment: .leading, spacing: 4) {
                let baseAmount = item.quantity * item.unitPrice

                HStack {
                    Text("Base Amount")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("$\(baseAmount, specifier: "%.2f")")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                if item.discountType != .none {
                    HStack {
                        Text(item.discountType == .dollar ? "Discount ($\(item.discountValue, specifier: "%.2f"))" : "Discount (\(item.discountValue, specifier: "%.1f")%)")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        Spacer()
                        Text("-$\(baseAmount - item.lineTotal, specifier: "%.2f")")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                    }
                }

                Divider()

                HStack {
                    Text("Line Total")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    Text("$\(item.lineTotal, specifier: "%.2f")")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
            .padding(.top, 4)

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
