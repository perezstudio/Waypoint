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
	@Query private var projects: [Project]
	@Query private var tags: [Tag]

	@State private var isHoveringTab = false
	@State private var isHoveringClose = false
	@State private var showEditSpace = false
	@State private var showBookmarks = true

	// Filtered projects for this space
	private var spaceProjects: [Project] {
		guard let space = space else { return projects }
		return projects.filter { $0.space?.id == space.id }
	}

	// Filtered tags for this space
	private var spaceTags: [Tag] {
		guard let space = space else { return tags }
		return tags.filter { $0.space?.id == space.id }
	}

	// Get current day for calendar icon
	private var todayCalendarIcon: String {
		let day = Calendar.current.component(.day, from: Date())
		return "\(day).calendar"
	}

	var body: some View {
		ScrollView(.vertical, showsIndicators: true) {
			VStack(alignment: .leading, spacing: 20) {
				// Global Views Section (at top of every space)
				VStack(alignment: .leading, spacing: 4) {
					MenuItemView(
						icon: "tray.fill",
						label: "Inbox",
						count: 12,
						isSelected: projectStore.selectedView == .system(.inbox),
						iconColor: .blue,
						action: { projectStore.selectSystemView(.inbox) }
					)
					MenuItemView(
						icon: todayCalendarIcon,
						label: "Today",
						count: 5,
						isSelected: projectStore.selectedView == .system(.today),
						iconColor: .yellow,
						action: { projectStore.selectSystemView(.today) }
					)
					MenuItemView(
						icon: "calendar.badge.clock",
						label: "Upcoming",
						count: 8,
						isSelected: projectStore.selectedView == .system(.upcoming),
						iconColor: .red,
						action: { projectStore.selectSystemView(.upcoming) }
					)
					MenuItemView(
						icon: "checkmark.circle.fill",
						label: "Completed",
						isSelected: projectStore.selectedView == .system(.completed),
						iconColor: .green,
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
						Spacer()
						Menu {
							Button {
								showEditSpace = true
							} label: {
								SwiftUI.Label("Edit Space", systemImage: "pencil")
							}
						} label: {
							Image(systemName: "ellipsis.circle")
								.imageScale(.medium)
								.padding(6)
								.frame(width: 26, height: 26)
								.background {
									RoundedRectangle(cornerRadius: 8, style: .continuous)
										.fill(isHoveringClose ? Color.secondary.opacity(0.15) : .clear)
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
							.foregroundStyle(.secondary)
						Text("All Spaces")
							.fontWeight(.medium)
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
							icon: "list.bullet",
							label: "All Issues",
							count: spaceProjects.reduce(0) { $0 + $1.issues.count },
							isSelected: false,
							action: { /* TODO: Add All Issues view */ }
						)
					}
				}

				// Favorite Projects Section (collapsible)
				if showBookmarks {
					VStack(alignment: .leading, spacing: 8) {
						HStack {
							Text("Favorite Projects")
								.font(.caption)
								.foregroundStyle(.secondary)

							if space != nil {
								Text("(\(spaceProjects.count))")
									.font(.caption2)
									.foregroundStyle(.tertiary)
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
									action: { projectStore.selectProject(project) }
								)
							}

							if spaceProjects.isEmpty && space != nil {
								Text("No projects in this space")
									.font(.caption)
									.foregroundStyle(.tertiary)
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
								.foregroundStyle(.secondary)

							if space != nil {
								Text("(\(spaceTags.count))")
									.font(.caption2)
									.foregroundStyle(.tertiary)
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
									.foregroundStyle(.tertiary)
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
	}
}
