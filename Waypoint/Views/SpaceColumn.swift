//
//  SpaceColumn.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/12/25.
//

import SwiftUI
import SwiftData

struct SpaceColumn: View {
	let space: Space?  // nil means "All" view
	@Environment(ProjectStore.self) private var projectStore
	@Environment(\.modelContext) private var modelContext
	@Query private var projects: [Project]
	@Query private var tags: [Tag]
	@Query private var spaces: [Space]
	@Query private var allIssues: [Issue]

	@State private var isHoveringTab = false
	@State private var isHoveringClose = false
	@State private var showEditSpace = false
	@State private var showBookmarks = true
	@State private var showDeleteConfirmation = false

	// Filtered projects for this space
	private var spaceProjects: [Project] {
		guard let space = space else { return projects.filter { $0.favorite } }
		return projects.filter { $0.space?.id == space.id && $0.favorite }
	}

	// Filtered tags for this space
	private var spaceTags: [Tag] {
		guard let space = space else { return tags }
		return tags.filter { $0.space?.id == space.id }
	}

	// Badge count computations
	private var inboxIssues: [Issue] {
		allIssues.filter { $0.project == nil }
	}

	private var todayIssues: [Issue] {
		let calendar = Calendar.current
		let today = calendar.startOfDay(for: Date())
		return allIssues.filter { issue in
			guard let dueDate = issue.dueDate else { return false }
			let dueDateStart = calendar.startOfDay(for: dueDate)
			return dueDateStart <= today
		}
	}

	private var upcomingIssues: [Issue] {
		let calendar = Calendar.current
		let today = calendar.startOfDay(for: Date())
		let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
		return allIssues.filter { issue in
			guard let dueDate = issue.dueDate else { return false }
			let dueDateStart = calendar.startOfDay(for: dueDate)
			return dueDateStart >= tomorrow
		}
	}

	private var completedIssues: [Issue] {
		allIssues.filter { $0.status == .done }
	}

	var body: some View {
		ScrollView(.vertical, showsIndicators: true) {
			VStack(alignment: .leading, spacing: 20) {
				// Global Views Section (at top of every space)
				VStack(alignment: .leading, spacing: 4) {
					MenuItemView(
						icon: "tray.fill",
						label: "Inbox",
						count: inboxIssues.count > 0 ? inboxIssues.count : nil,
						isSelected: projectStore.selectedView == .system(.inbox),
						iconColor: SystemView.inbox.color,
						action: { projectStore.selectSystemView(.inbox) }
					)
					MenuItemView(
						icon: SystemView.today.icon,
						label: "Today",
						count: todayIssues.count > 0 ? todayIssues.count : nil,
						isSelected: projectStore.selectedView == .system(.today),
						iconColor: SystemView.today.color,
						action: { projectStore.selectSystemView(.today) }
					)
					MenuItemView(
						icon: "calendar.badge.clock",
						label: "Upcoming",
						count: upcomingIssues.count > 0 ? upcomingIssues.count : nil,
						isSelected: projectStore.selectedView == .system(.upcoming),
						iconColor: SystemView.upcoming.color,
						action: { projectStore.selectSystemView(.upcoming) }
					)
					MenuItemView(
						icon: "checkmark.circle.fill",
						label: "Completed",
						count: completedIssues.count > 0 ? completedIssues.count : nil,
						isSelected: projectStore.selectedView == .system(.completed),
						iconColor: SystemView.completed.color,
						action: { projectStore.selectSystemView(.completed) }
					)
				}

				// Space Header (only show for specific spaces, not "All")
				if let space = space {
					HStack(spacing: 8) {
						Image(systemName: isHoveringTab ? "chevron.right" : space.icon)
							.frame(width: 18, height: 18)
							.alignmentGuide(.firstTextBaseline) { d in d[.bottom] }
							.rotationEffect(.degrees(isHoveringTab && showBookmarks ? 90 : 0))
							.contentTransition(.symbolEffect(.replace))
							.animation(.easeInOut(duration: 0.15), value: isHoveringTab)
							.animation(.easeInOut(duration: 0.15), value: showBookmarks)
							.foregroundStyle(AppColor.color(from: space.color))
						Text(space.name)
							.fontWeight(.medium)
							.foregroundStyle(.white)
						Spacer()
						Menu {
							Button {
								showEditSpace = true
							} label: {
								SwiftUI.Label("Edit Space", systemImage: "pencil")
							}

							// Only show delete option if more than 1 space exists
							if spaces.count > 1 {
								Divider()
								Button(role: .destructive) {
									showDeleteConfirmation = true
								} label: {
									SwiftUI.Label("Delete Space", systemImage: "trash")
								}
							}
						} label: {
							Image(systemName: "ellipsis.circle")
								.imageScale(.medium)
								.foregroundStyle(.white.opacity(0.6))
								.padding(6)
								.frame(width: 26, height: 26)
								.background {
									RoundedRectangle(cornerRadius: 8, style: .continuous)
										.fill(isHoveringClose ? Color.white.opacity(0.15) : .clear)
								}
								.contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
						}
						.menuStyle(.borderlessButton)
						.menuIndicator(.hidden)
						.onHover { inside in
							withAnimation(.easeInOut(duration: 0.15)) {
								isHoveringClose = inside
							}
						}
						.opacity(isHoveringTab ? 1 : 0)
						.allowsHitTesting(isHoveringTab)
						.accessibilityHidden(!isHoveringTab)
						.help("Space Options")
					}
					.frame(height: 26)
					.padding(.horizontal, 12)
					.padding(.vertical, 6)
					.frame(maxWidth: .infinity, alignment: .leading)
					.background {
						RoundedRectangle(cornerRadius: 8, style: .continuous)
							.fill(Color.secondary.opacity(0.15))
							.opacity(isHoveringTab ? 1 : 0)
					}
					.contentShape(Rectangle())
					.onTapGesture {
						withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
							showBookmarks.toggle()
						}
					}
					.onHover { inside in
						withAnimation(.easeInOut(duration: 0.15)) {
							isHoveringTab = inside
							if !inside { isHoveringClose = false }
						}
					}
					.padding(.bottom, 8)
				} else {
					// "All Spaces" header for the first column
					HStack(spacing: 8) {
						Image(systemName: isHoveringTab ? "chevron.right" : "square.stack.3d.up")
							.frame(width: 18, height: 18)
							.alignmentGuide(.firstTextBaseline) { d in d[.bottom] }
							.rotationEffect(.degrees(isHoveringTab && showBookmarks ? 90 : 0))
							.contentTransition(.symbolEffect(.replace))
							.animation(.easeInOut(duration: 0.15), value: isHoveringTab)
							.animation(.easeInOut(duration: 0.15), value: showBookmarks)
							.foregroundStyle(.white.opacity(0.6))
						Text("All Spaces")
							.fontWeight(.medium)
							.foregroundStyle(.white)
						Spacer()
					}
					.frame(height: 26)
					.padding(.horizontal, 12)
					.padding(.vertical, 6)
					.frame(maxWidth: .infinity, alignment: .leading)
					.background {
						RoundedRectangle(cornerRadius: 8, style: .continuous)
							.fill(Color.secondary.opacity(0.15))
							.opacity(isHoveringTab ? 1 : 0)
					}
					.contentShape(Rectangle())
					.onTapGesture {
						withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
							showBookmarks.toggle()
						}
					}
					.onHover { inside in
						withAnimation(.easeInOut(duration: 0.15)) {
							isHoveringTab = inside
						}
					}
					.padding(.bottom, 8)
				}

				// All Projects and All Issues grouped section
				if showBookmarks {
					VStack(alignment: .leading, spacing: 4) {
						MenuItemView(
							icon: "folder.fill",
							label: "All Projects",
							count: spaceProjects.count,
							isSelected: projectStore.selectedView == .system(.projects),
							action: { projectStore.selectSystemView(.projects) }
						)

						MenuItemView(
							icon: "list.bullet.rectangle",
							label: "All Issues",
							count: spaceProjects.reduce(0) { $0 + $1.issues.count },
							isSelected: projectStore.selectedView == .system(.allIssues),
							iconColor: SystemView.allIssues.color,
							action: { projectStore.selectSystemView(.allIssues) }
						)
					}
				}

				// Favorite Projects Section (collapsible)
				if showBookmarks {
					VStack(alignment: .leading, spacing: 8) {
						HStack {
							Text("Favorite Projects")
								.font(.caption)
								.foregroundStyle(.white.opacity(0.6))

							if space != nil {
								Text("(\(spaceProjects.count))")
									.font(.caption2)
									.foregroundStyle(.white.opacity(0.5))
							}
						}
						.padding(.leading, 8)

						VStack(alignment: .leading, spacing: 4) {
							ForEach(spaceProjects) { project in
								MenuItemView(
									icon: project.icon,
									label: project.name,
									count: project.issues.count,
									isSelected: projectStore.selectedView == .project(project.id),
									iconColor: AppColor.color(from: project.color),
									action: { projectStore.selectProject(project) }
								)
							}

							if spaceProjects.isEmpty && space != nil {
								Text("No projects in this space")
									.font(.caption)
									.foregroundStyle(.white.opacity(0.5))
									.frame(maxWidth: .infinity, alignment: .center)
									.padding(.vertical, 12)
							}
						}
					}

					// Favorite Tags Section
					VStack(alignment: .leading, spacing: 8) {
						HStack {
							Text("Favorite Tags")
								.font(.caption)
								.foregroundStyle(.white.opacity(0.6))

							if space != nil {
								Text("(\(spaceTags.count))")
									.font(.caption2)
									.foregroundStyle(.white.opacity(0.5))
							}
						}
						.padding(.leading, 8)

						VStack(alignment: .leading, spacing: 4) {
							ForEach(spaceTags) { tag in
								MenuItemView(
									icon: tag.icon ?? "tag.fill",
									label: tag.name,
									count: tag.issues.count
								)
							}

							if spaceTags.isEmpty && space != nil {
								Text("No tags in this space")
									.font(.caption)
									.foregroundStyle(.white.opacity(0.5))
									.frame(maxWidth: .infinity, alignment: .center)
									.padding(.vertical, 12)
							}
						}
					}
				}
			}
			.padding(.horizontal, 16)
			.frame(maxWidth: .infinity, alignment: .top)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
		.confirmationDialog(
			"Delete \"\(space?.name ?? "Space")\"?",
			isPresented: $showDeleteConfirmation,
			titleVisibility: .visible
		) {
			Button("Delete", role: .destructive) {
				deleteSpace()
			}
			Button("Cancel", role: .cancel) {}
		} message: {
			Text("This will permanently delete the space and all its projects and tags. This action cannot be undone.")
		}
	}

	// MARK: - Actions

	private func deleteSpace() {
		guard let space = space else { return }

		// Delete the space (SwiftData relationships will handle cascading)
		modelContext.delete(space)
		try? modelContext.save()

		// If the deleted space had any selected projects, clear the selection
		// and navigate to a default view
		if case .project(let projectId) = projectStore.selectedView {
			// Check if the deleted project belonged to this space
			let deletedProjectBelongedToSpace = spaceProjects.contains(where: { $0.id == projectId })
			if deletedProjectBelongedToSpace {
				projectStore.selectSystemView(.inbox)
			}
		}
	}
}
