//
//  SidebarView.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/11/25.
//

import SwiftUI
import SwiftData

struct SidebarView: View {
	@Binding var isSidebarCollapsed: Bool
	@State private var isScrolling: Bool = false

	var body: some View {
		VStack(alignment: .leading, spacing: 0) {
			// Sidebar toggle button - pushed to the right
			HStack {
				Spacer()

				IconButton(icon: "sidebar.left", action: {
					isSidebarCollapsed.toggle()
				}, tooltip: "Toggle Sidebar")
			}
			.padding(.horizontal, 16)
			.padding(.top, 12)
			.padding(.bottom, 20)

			// Scrollable menu content
			ScrollView {
				VStack(alignment: .leading, spacing: 20) {
					// Top navigation section
					VStack(alignment: .leading, spacing: 4) {
						MenuItemView(icon: "inbox.fill", label: "Inbox", count: 12, isSelected: true)
						MenuItemView(icon: "calendar", label: "Today", count: 5)
						MenuItemView(icon: "calendar.badge.clock", label: "Upcoming", count: 8)
						MenuItemView(icon: "checkmark.circle.fill", label: "Completed")
					}

					Divider()
						.padding(.vertical, 4)

					// Favorite Projects section
					VStack(alignment: .leading, spacing: 8) {
						Text("Favorite Projects")
							.font(.caption)
							.foregroundStyle(.secondary)
							.padding(.leading, 8)

						VStack(alignment: .leading, spacing: 4) {
							MenuItemView(icon: "folder.fill", label: "Website Redesign", count: 23)
							MenuItemView(icon: "folder.fill", label: "Mobile App", count: 15)
							MenuItemView(icon: "folder.fill", label: "Marketing Campaign", count: 8)
							MenuItemView(icon: "folder.fill", label: "Client Portal", count: 12)
							MenuItemView(icon: "folder.fill", label: "Documentation", count: 5)
							MenuItemView(icon: "folder.fill", label: "Team Onboarding", count: 3)
						}
					}

					Divider()
						.padding(.vertical, 4)

					// Favorite Labels section
					VStack(alignment: .leading, spacing: 8) {
						Text("Favorite Labels")
							.font(.caption)
							.foregroundStyle(.secondary)
							.padding(.leading, 8)

						VStack(alignment: .leading, spacing: 4) {
							MenuItemView(icon: "tag.fill", label: "Urgent", count: 4)
							MenuItemView(icon: "tag.fill", label: "Bug Fix", count: 7)
							MenuItemView(icon: "tag.fill", label: "Feature", count: 12)
							MenuItemView(icon: "tag.fill", label: "Review", count: 6)
							MenuItemView(icon: "tag.fill", label: "Design", count: 9)
							MenuItemView(icon: "tag.fill", label: "Research", count: 3)
						}
					}
				}
				.padding(.horizontal, 16)
			}
			.scrollIndicators(isScrolling ? .visible : .hidden)
			.onScrollGeometryChange(for: Bool.self) { geometry in
				geometry.contentSize.height > geometry.containerSize.height
			} action: { _, newValue in
				isScrolling = newValue
			}

			// Bottom actions
			VStack(spacing: 0) {
				Divider()

				HStack(spacing: 8) {
					IconButton(icon: "gear", action: {
						// Settings action
					}, tooltip: "Settings")

					Spacer()

					IconButton(icon: "plus", action: {
						// Add action
					}, tooltip: "Add")
				}
				.padding(.horizontal, 16)
				.padding(.top, 12)
				.padding(.bottom, 12)
			}
		}
		.frame(maxHeight: .infinity)
	}
}

#Preview {
	SidebarView(isSidebarCollapsed: .constant(false))
}
