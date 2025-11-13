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
		.onAppear {
			createSampleDataIfNeeded()
		}
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
			Button("") { showingCreateIssue = true }
				.keyboardShortcut("i", modifiers: .command)
				.hidden()
		)
    }

	private func createSampleDataIfNeeded() {
		// Create sample spaces if they don't exist
		let engineeringSpace: Space
		let designSpace: Space

		if spaces.isEmpty {
			engineeringSpace = Space(name: "Engineering", spaceDescription: "Product development team", icon: "hammer.fill", color: "#007AFF")
			designSpace = Space(name: "Design", spaceDescription: "Design and UX team", icon: "paintbrush.fill", color: "#AF52DE")

			modelContext.insert(engineeringSpace)
			modelContext.insert(designSpace)
		} else {
			// Use existing spaces
			engineeringSpace = spaces.first { $0.name == "Engineering" } ?? spaces[0]
			designSpace = spaces.first { $0.name == "Design" } ?? spaces[0]
		}

		// Only create sample projects if no projects exist
		guard projects.isEmpty else { return }

		// Create sample projects
		let websiteProject = Project(name: "Website Redesign", icon: "safari.fill", color: "#007AFF", space: engineeringSpace)
		let mobileProject = Project(name: "Mobile App", icon: "iphone", color: "#FF9500", space: engineeringSpace)
		let marketingProject = Project(name: "Marketing Campaign", icon: "megaphone.fill", color: "#FF2D55", space: designSpace)

		modelContext.insert(websiteProject)
		modelContext.insert(mobileProject)
		modelContext.insert(marketingProject)

		// Create sample issues for website project
		let issue1 = Issue(title: "Update homepage design", status: .inProgress, priority: .high, project: websiteProject)
		issue1.issueDescription = "Redesign the homepage to match the new brand guidelines"
		issue1.dueDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())

		let issue2 = Issue(title: "Implement responsive layout", status: .todo, priority: .medium, project: websiteProject)
		issue2.issueDescription = "Ensure the website works well on mobile and tablet devices"
		issue2.dueDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())

		let issue3 = Issue(title: "Optimize images for web", status: .done, priority: .low, project: websiteProject)
		issue3.issueDescription = "Compress and optimize all images for faster load times"

		let issue6 = Issue(title: "Fix navigation menu", status: .review, priority: .urgent, project: websiteProject)
		issue6.issueDescription = "Navigation menu is broken on Safari"
		issue6.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())

		modelContext.insert(issue1)
		modelContext.insert(issue2)
		modelContext.insert(issue3)
		modelContext.insert(issue6)

		// Create sample issues for mobile project
		let issue4 = Issue(title: "Design onboarding flow", status: .review, priority: .high, project: mobileProject)
		issue4.issueDescription = "Create user-friendly onboarding screens for new users"
		issue4.dueDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())

		let issue5 = Issue(title: "Implement dark mode", status: .todo, priority: .medium, project: mobileProject)
		issue5.issueDescription = "Add system-wide dark mode support"

		let issue7 = Issue(title: "Add biometric authentication", status: .inProgress, priority: .high, project: mobileProject)
		issue7.issueDescription = "Support Face ID and Touch ID for secure login"

		modelContext.insert(issue4)
		modelContext.insert(issue5)
		modelContext.insert(issue7)

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
