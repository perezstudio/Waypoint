//
//  ContentView.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/11/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
	@Environment(ViewSettingsStore.self) private var viewSettingsStore
    @Query private var items: [Item]
	@Query private var projects: [Project]
	@Query private var spaces: [Space]
	@State private var isInspectorVisible: Bool = false
	@State private var isSidebarCollapsed: Bool = false
	@State private var projectStore = ProjectStore()
	@State private var showingCreateIssue: Bool = false

	var body: some View {
		SplitView(
			sidebar: SidebarView(isSidebarCollapsed: $isSidebarCollapsed),
			detail: DetailPaneView(isInspectorVisible: $isInspectorVisible, isSidebarCollapsed: $isSidebarCollapsed),
			isSidebarCollapsed: $isSidebarCollapsed
		)
		.environment(projectStore)
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.ignoresSafeArea()
		.onChange(of: projectStore.selectedView) { oldValue, newValue in
			// Close inspector and clear selected issue when switching views/tabs from sidebar
			if isInspectorVisible {
				withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
					isInspectorVisible = false
				}
			}
			// Clear selected issue so inspector starts fresh in new view
			projectStore.selectedIssue = nil
		}
		.configureWindow { window in
			// Remove toolbar completely
			window.toolbar = nil

			// Configure title bar for edge-to-edge content
			window.titlebarAppearsTransparent = true
			window.titleVisibility = .hidden
			window.titlebarSeparatorStyle = .none

			// Full size content view
			window.styleMask.insert(.fullSizeContentView)

			// Make traffic lights visible
			window.standardWindowButton(.closeButton)?.isHidden = false
			window.standardWindowButton(.miniaturizeButton)?.isHidden = false
			window.standardWindowButton(.zoomButton)?.isHidden = false

			// Position traffic lights - leave them in default position for now
			// We'll adjust this based on sidebar state later
		}
		.sheet(isPresented: $showingCreateIssue) {
			CreateIssueSheet()
		}
		.background(
			Group {
				// Create issue shortcut
				Button("") { showingCreateIssue = true }
					.keyboardShortcut("n", modifiers: [.command, .shift])
					.hidden()

				// Navigation shortcuts - Inbox
				Button("") { projectStore.selectSystemView(.inbox) }
					.keyboardShortcut("i", modifiers: .command)
					.hidden()

				// Navigation shortcuts - All Issues
				Button("") { projectStore.selectSystemView(.allIssues) }
					.keyboardShortcut("a", modifiers: .command)
					.hidden()

				// Navigation shortcuts - Today
				Button("") { projectStore.selectSystemView(.today) }
					.keyboardShortcut("t", modifiers: .command)
					.hidden()

				// Navigation shortcuts - Upcoming
				Button("") { projectStore.selectSystemView(.upcoming) }
					.keyboardShortcut("u", modifiers: .command)
					.hidden()

				// Navigation shortcuts - Completed
				Button("") { projectStore.selectSystemView(.completed) }
					.keyboardShortcut("d", modifiers: .command)
					.hidden()

				// Navigation shortcuts - Projects
				Button("") { projectStore.selectSystemView(.projects) }
					.keyboardShortcut("p", modifiers: .command)
					.hidden()

				// View mode shortcuts - List view
				Button("") { setViewMode(.list) }
					.keyboardShortcut("1", modifiers: [.command, .shift])
					.hidden()

				// View mode shortcuts - Board view
				Button("") { setViewMode(.board) }
					.keyboardShortcut("2", modifiers: [.command, .shift])
					.hidden()
			}
		)
    }

	private func setViewMode(_ mode: IssuesViewMode) {
		switch projectStore.selectedView {
		case .system(let systemView):
			if systemView == .projects {
				// Handle projects view separately
				var settings = viewSettingsStore.projectsSettings
				settings.viewMode = mode
				viewSettingsStore.projectsSettings = settings
			} else {
				var settings = viewSettingsStore.getSettings(for: systemView)
				settings.viewMode = mode
				viewSettingsStore.updateSettings(settings, for: systemView)
			}
		case .project:
			// For now, do nothing for project views - we can add project-specific settings later
			break
		}
	}
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
