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
	@Environment(ProjectStore.self) private var projectStore

	// Creation menu and sheets state
	@State private var showingCreationMenu = false
	@State private var showingCreateProject = false
	@State private var showingCreateIssue = false
	@State private var showingCreateLabel = false
	@State private var showingCreateSpace = false

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

			// Horizontal scrolling sidebar content
			HorizontalSidebarContainer()

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
			CreateProjectSheet(preselectedSpace: nil)
		}
		.sheet(isPresented: $showingCreateIssue) {
			CreateIssueSheet()
		}
		.sheet(isPresented: $showingCreateLabel) {
			CreateLabelSheet(preselectedSpace: nil)
		}
		.sheet(isPresented: $showingCreateSpace) {
			CreateSpaceSheet()
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
		case .space:
			showingCreateSpace = true
		}
	}
}

#Preview {
	SidebarView(isSidebarCollapsed: .constant(false))
		.environment(ProjectStore())
		.modelContainer(for: [Project.self, Issue.self, Space.self, Label.self], inMemory: true)
}
