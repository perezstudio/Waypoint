//
//  MenuItemView.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/11/25.
//

import SwiftUI
import SwiftData

struct MenuItemView: View {
	var icon: String = "circle.fill"
	var label: String = "Menu Item"
	var count: Int? = nil
	var isSelected: Bool = false

	@State private var isHovered: Bool = false

	var body: some View {
		HStack(spacing: 8) {
			Image(systemName: icon)
				.font(.system(size: 14))
				.foregroundStyle(isSelected ? .blue : .secondary)
				.frame(width: 16)

			Text(label)
				.font(.subheadline)
				.foregroundStyle(isSelected ? .primary : .primary)

			Spacer()

			if let count = count {
				Text("\(count)")
					.font(.caption)
					.foregroundStyle(.secondary)
					.padding(.horizontal, 6)
					.padding(.vertical, 2)
					.background(.tertiary.opacity(0.5))
					.clipShape(RoundedRectangle(cornerRadius: 4))
			}
		}
		.padding(.horizontal, 8)
		.padding(.vertical, 6)
		.background(
			RoundedRectangle(cornerRadius: 6)
				.fill(isSelected ? .blue.opacity(0.1) : (isHovered ? .primary.opacity(0.05) : .clear))
		)
		.contentShape(Rectangle())
		.onHover { hovering in
			isHovered = hovering
		}
	}
}

#Preview {
	VStack(alignment: .leading, spacing: 8) {
		MenuItemView(icon: "inbox.fill", label: "Inbox", count: 12, isSelected: true)
		MenuItemView(icon: "calendar", label: "Today", count: 5)
		MenuItemView(icon: "star.fill", label: "Important", count: 3)
		MenuItemView(icon: "folder.fill", label: "Project Alpha")
	}
	.padding()
	.frame(width: 280)
}
