//
//  ItemRowView.swift
//  MyShoppingList
//
//  Created by Olivier Markowitch on 21/12/2025.
//

import SwiftUI

struct ItemRowView: View {
    @Bindable var item: Item

    var body: some View {
        HStack {
            Button(action: { withAnimation { item.isChecked.toggle() } }) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isChecked ? .green : .gray)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .strikethrough(item.isChecked)
                    .foregroundStyle(item.isChecked ? .secondary : .primary)
                if !item.category.isEmpty {
                    Text(item.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if item.quantity > 1 {
                Text("×\(item.quantity)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation { item.isChecked.toggle() }
        }
    }
}
