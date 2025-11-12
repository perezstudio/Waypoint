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
	@Environment(ProjectStore.self) private var projectStore
	@Query private var projects: [Project]

	// Creation menu and sheets state
	@State private var showingCreationMenu = false
	@State private var showingCreateProject = false
	@State private var showingCreateIssue = false
	@State private var showingCreateLabel = false
	@State private var showingCreateTeam = false

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
						MenuItemView(
							icon: "inbox.fill",
							label: "Inbox",
							count: 12,
							isSelected: projectStore.selectedView == .system(.inbox),
							action: { projectStore.selectSystemView(.inbox) }
						)
						MenuItemView(
							icon: "calendar",
							label: "Today",
							count: 5,
							isSelected: projectStore.selectedView == .system(.today),
							action: { projectStore.selectSystemView(.today) }
						)
						MenuItemView(
							icon: "calendar.badge.clock",
							label: "Upcoming",
							count: 8,
							isSelected: projectStore.selectedView == .system(.upcoming),
							action: { projectStore.selectSystemView(.upcoming) }
						)
						MenuItemView(
							icon: "checkmark.circle.fill",
							label: "Completed",
							isSelected: projectStore.selectedView == .system(.completed),
							action: { projectStore.selectSystemView(.completed) }
						)
						MenuItemView(
							icon: "folder.fill",
							label: "Projects",
							count: projects.count,
							isSelected: projectStore.selectedView == .system(.projects),
							action: { projectStore.selectSystemView(.projects) }
						)
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
							ForEach(projects) { project in
								MenuItemView(
									icon: project.icon,
									label: project.name,
									count: project.issues.count,
									isSelected: projectStore.selectedView == .project(project.id),
									action: { projectStore.selectProject(project) }
								)
							}
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
						showingCreationMenu.toggle()
					}, tooltip: "Add")
					.popover(isPresented: $showingCreationMenu, arrowEdge: .top) {
						CreationMenuPopover { option in
							handleCreationSelection(option)
						}
					}
					.keyboardShortcut("n", modifiers: .command)
				}
				.padding(.horizontal, 16)
				.padding(.top, 12)
				.padding(.bottom, 12)
			}
		}
		.frame(maxHeight: .infinity)
		.sheet(isPresented: $showingCreateProject) {
			CreateProjectSheet()
		}
		.sheet(isPresented: $showingCreateIssue) {
			CreateIssueSheet()
		}
		.sheet(isPresented: $showingCreateLabel) {
			CreateLabelSheet()
		}
		.sheet(isPresented: $showingCreateTeam) {
			CreateTeamSheet()
		}
	}

	private func handleCreationSelection(_ option: CreationOption) {
		switch option {
		case .project:
			showingCreateProject = true
		case .issue:
			showingCreateIssue = true
		case .label:
			showingCreateLabel = true
		case .team:
			showingCreateTeam = true
		}
	}
}

#Preview {
	SidebarView(isSidebarCollapsed: .constant(false))
		.environment(ProjectStore())
		.modelContainer(for: [Project.self, Issue.self], inMemory: true)
}
