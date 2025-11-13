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
	var iconColor: Color? = nil  // Custom icon color when selected
	var action: () -> Void = {}

	@State private var isHovered: Bool = false

	var body: some View {
		Button(action: action) {
			HStack(spacing: 8) {
				Image(systemName: icon)
					.frame(width: 18, height: 18)
					.foregroundStyle(isSelected ? (iconColor ?? .blue) : .white.opacity(0.6))

				Text(label)
					.fontWeight(.medium)
					.foregroundStyle(.white)

				Spacer()

				if let count = count {
					Text("\(count)")
						.font(.caption)
						.foregroundStyle(.white.opacity(0.7))
						.padding(.horizontal, 6)
						.padding(.vertical, 2)
						.background(.white.opacity(0.15))
						.clipShape(RoundedRectangle(cornerRadius: 4))
				}
			}
			.frame(height: 26)
			.padding(.horizontal, 12)
			.padding(.vertical, 6)
			.frame(maxWidth: .infinity, alignment: .leading)
			.background {
				RoundedRectangle(cornerRadius: 8, style: .continuous)
					.fill(Color.secondary.opacity(0.15))
					.opacity(isSelected || isHovered ? 1 : 0)
			}
			.contentShape(Rectangle())
		}
		.buttonStyle(.plain)
		.onHover { hovering in
			withAnimation(.easeInOut(duration: 0.15)) {
				isHovered = hovering
			}
		}
	}
}

#Preview {
	VStack(alignment: .leading, spacing: 8) {
		MenuItemView(icon: "tray.fill", label: "Inbox", count: 12, isSelected: true)
		MenuItemView(icon: "calendar", label: "Today", count: 5)
		MenuItemView(icon: "star.fill", label: "Important", count: 3)
		MenuItemView(icon: "folder.fill", label: "Project Alpha")
	}
	.padding()
	.frame(width: 280)
}
