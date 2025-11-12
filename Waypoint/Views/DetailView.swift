//
//  DetailView.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/11/25.
//

import SwiftUI
import SwiftData

struct DetailView: View {
	@Binding var isInspectorVisible: Bool

	var body: some View {
		VStack(spacing: 0) {
			// Header toolbar
			HStack {
				Text("Project Name")
					.font(.title2)
					.fontWeight(.semibold)

				Spacer()

				HStack(spacing: 16) {
					// Tab-style navigation
					HStack(spacing: 4) {
						TabButton(title: "Overview", isSelected: true)
						TabButton(title: "Status", isSelected: false)
						TabButton(title: "Issues", isSelected: false)
					}
					.padding(4)
					.background(.tertiary.opacity(0.3))
					.clipShape(RoundedRectangle(cornerRadius: 8))

					// Inspector toggle button
					IconButton(
						icon: "sidebar.right",
						action: {
							withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
								isInspectorVisible.toggle()
							}
						},
						isActive: isInspectorVisible,
						tooltip: "Toggle Inspector"
					)
				}
			}
			.padding(.horizontal, 20)
			.padding(.vertical, 16)

			Divider()

			// Main content area
			VStack {
				Text("Page Content")
					.foregroundStyle(.secondary)
				Spacer()
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.padding(20)
		}
	}
}

// Tab button component
struct TabButton: View {
	let title: String
	let isSelected: Bool

	var body: some View {
		Button {
			// Tab action
		} label: {
			Text(title)
				.font(.subheadline)
				.fontWeight(isSelected ? .medium : .regular)
				.foregroundStyle(isSelected ? .primary : .secondary)
				.padding(.horizontal, 12)
				.padding(.vertical, 6)
				.background(isSelected ? Color(nsColor: .controlBackgroundColor) : Color.clear)
				.clipShape(RoundedRectangle(cornerRadius: 6))
		}
		.buttonStyle(.plain)
	}
}

#Preview {
	DetailView(isInspectorVisible: .constant(false))
		.frame(width: 800, height: 600)
}
