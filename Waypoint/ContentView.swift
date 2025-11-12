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
    @Query private var items: [Item]
	@Query private var projects: [Project]
	@State private var isInspectorVisible: Bool = false
	@State private var isSidebarCollapsed: Bool = false
	@State private var projectStore = ProjectStore()

	var body: some View {
		SplitView(
			sidebar: SidebarView(isSidebarCollapsed: $isSidebarCollapsed),
			detail: DetailPaneView(isInspectorVisible: $isInspectorVisible, isSidebarCollapsed: $isSidebarCollapsed),
			isSidebarCollapsed: $isSidebarCollapsed
		)
		.environment(projectStore)
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.ignoresSafeArea()
		.onAppear {
			createSampleDataIfNeeded()
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
    }

	private func createSampleDataIfNeeded() {
		// Only create sample data if no projects exist
		guard projects.isEmpty else { return }

		// Create sample projects
		let websiteProject = Project(name: "Website Redesign", icon: "safari.fill", color: "#007AFF")
		let mobileProject = Project(name: "Mobile App", icon: "iphone", color: "#FF9500")
		let marketingProject = Project(name: "Marketing Campaign", icon: "megaphone.fill", color: "#FF2D55")

		modelContext.insert(websiteProject)
		modelContext.insert(mobileProject)
		modelContext.insert(marketingProject)

		// Create sample issues for website project
		let issue1 = Issue(title: "Update homepage design", status: .inProgress, priority: .high, project: websiteProject)
		let issue2 = Issue(title: "Implement responsive layout", status: .todo, priority: .medium, project: websiteProject)
		let issue3 = Issue(title: "Optimize images for web", status: .done, priority: .low, project: websiteProject)

		modelContext.insert(issue1)
		modelContext.insert(issue2)
		modelContext.insert(issue3)

		// Create sample issues for mobile project
		let issue4 = Issue(title: "Design onboarding flow", status: .review, priority: .high, project: mobileProject)
		let issue5 = Issue(title: "Implement dark mode", status: .todo, priority: .medium, project: mobileProject)

		modelContext.insert(issue4)
		modelContext.insert(issue5)

		// Start with Inbox selected (already default in ProjectStore)
	}

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
