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
	@Query private var teams: [Team]

	// Creation menu and sheets state
	@State private var showingCreationMenu = false
	@State private var showingCreateProject = false
	@State private var showingCreateIssue = false
	@State private var showingCreateLabel = false
	@State private var showingCreateTeam = false

	// Team selection
	@State private var selectedTeam: Team?

	// Filtered projects based on selected team
	private var filteredProjects: [Project] {
		guard let selectedTeam = selectedTeam else {
			return projects
		}
		return projects.filter { $0.team?.id == selectedTeam.id }
	}

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

			// Team picker
			TeamPicker(selectedTeam: $selectedTeam, teams: teams)
				.padding(.horizontal, 16)
				.padding(.bottom, 16)

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
						HStack {
							Text("Favorite Projects")
								.font(.caption)
								.foregroundStyle(.secondary)

							if selectedTeam != nil {
								Text("(\(filteredProjects.count))")
									.font(.caption2)
									.foregroundStyle(.tertiary)
							}
						}
						.padding(.leading, 8)

						VStack(alignment: .leading, spacing: 4) {
							ForEach(filteredProjects) { project in
								MenuItemView(
									icon: project.icon,
									label: project.name,
									count: project.issues.count,
									isSelected: projectStore.selectedView == .project(project.id),
									action: { projectStore.selectProject(project) }
								)
							}

							if filteredProjects.isEmpty && selectedTeam != nil {
								Text("No projects in this team")
									.font(.caption)
									.foregroundStyle(.tertiary)
									.frame(maxWidth: .infinity, alignment: .center)
									.padding(.vertical, 12)
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

// Team Picker Component
struct TeamPicker: View {
	@Binding var selectedTeam: Team?
	let teams: [Team]

	var body: some View {
		Menu {
			Button {
				selectedTeam = nil
			} label: {
				HStack {
					Image(systemName: "square.stack.3d.up")
					Text("All Teams")
				}
			}

			Divider()

			ForEach(teams) { team in
				Button {
					selectedTeam = team
				} label: {
					HStack {
						Image(systemName: team.icon)
							.foregroundStyle(Color(hex: team.color) ?? .blue)
						Text(team.name)
					}
				}
			}
		} label: {
			HStack(spacing: 8) {
				if let team = selectedTeam {
					Image(systemName: team.icon)
						.font(.system(size: 14))
						.foregroundStyle(Color(hex: team.color) ?? .blue)

					Text(team.name)
						.font(.subheadline)
						.fontWeight(.medium)
						.foregroundStyle(.primary)
				} else {
					Image(systemName: "square.stack.3d.up")
						.font(.system(size: 14))
						.foregroundStyle(.secondary)

					Text("All Teams")
						.font(.subheadline)
						.fontWeight(.medium)
						.foregroundStyle(.primary)
				}

				Spacer()

				Image(systemName: "chevron.up.chevron.down")
					.font(.system(size: 10))
					.foregroundStyle(.secondary)
			}
			.padding(.horizontal, 12)
			.padding(.vertical, 8)
			.background(.bar)
			.clipShape(RoundedRectangle(cornerRadius: 8))
		}
		.buttonStyle(.plain)
	}
}

#Preview {
	SidebarView(isSidebarCollapsed: .constant(false))
		.environment(ProjectStore())
		.modelContainer(for: [Project.self, Issue.self, Team.self], inMemory: true)
}
