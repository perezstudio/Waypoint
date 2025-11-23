//
//  GenericProjectViews.swift
//  Waypoint
//
//  Created by Claude on 11/13/25.
//

import SwiftUI
import SwiftData

// MARK: - Helper Functions

private func colorForProjectGroup(_ group: ProjectGroup) -> Color {
    // Determine color based on group title/type
    switch group.title.lowercased() {
    // Status colors
    case "to do": return .gray
    case "in progress": return .orange
    case "review": return .purple
    case "done": return .green
    // Other grouping types - use a default color scheme
    default: return .blue
    }
}

// MARK: - Generic Project Board View

struct GenericProjectBoardView: View {
    let groups: [ProjectGroup]
    let grouping: ProjectGrouping
    let showAddButton: Bool
    let onAddProject: (() -> Void)?
    let onSelectProject: (Project) -> Void
    @FocusState private var focusedElement: FocusableElement?
    @StateObject private var dragManager = DragDropManager()

    init(groups: [ProjectGroup], grouping: ProjectGrouping, showAddButton: Bool = true, onAddProject: (() -> Void)? = nil, onSelectProject: @escaping (Project) -> Void) {
        self.groups = groups
        self.grouping = grouping
        self.showAddButton = showAddButton
        self.onAddProject = onAddProject
        self.onSelectProject = onSelectProject
    }

    // Build 2D grid structure: array of columns, each containing array of elements
    private var gridStructure: [[FocusableElement]] {
        var grid: [[FocusableElement]] = []
        for group in groups.sorted(by: { $0.order < $1.order }) {
            var column: [FocusableElement] = []
            // Add all projects
            for project in group.projects {
                column.append(.project(project.id))
            }
            // Add the add button if applicable
            if showAddButton {
                column.append(.addButton(group.id))
            }
            grid.append(column)
        }
        return grid
    }

    // Find current position in grid
    private func findPosition(of element: FocusableElement) -> (column: Int, row: Int)? {
        for (colIndex, column) in gridStructure.enumerated() {
            if let rowIndex = column.firstIndex(of: element) {
                return (colIndex, rowIndex)
            }
        }
        return nil
    }

    private func moveLeft() {
        guard let currentFocus = focusedElement,
              let position = findPosition(of: currentFocus),
              position.column > 0 else {
            // Focus first element in first column if nothing focused or at leftmost
            focusedElement = gridStructure.first?.first
            return
        }

        let targetColumn = position.column - 1
        let targetRow = min(position.row, gridStructure[targetColumn].count - 1)
        focusedElement = gridStructure[targetColumn][targetRow]
    }

    private func moveRight() {
        guard let currentFocus = focusedElement,
              let position = findPosition(of: currentFocus),
              position.column < gridStructure.count - 1 else {
            // Focus first element if nothing focused, stay at rightmost if at end
            if focusedElement == nil {
                focusedElement = gridStructure.first?.first
            }
            return
        }

        let targetColumn = position.column + 1
        let targetRow = min(position.row, gridStructure[targetColumn].count - 1)
        focusedElement = gridStructure[targetColumn][targetRow]
    }

    private func moveUp() {
        guard let currentFocus = focusedElement,
              let position = findPosition(of: currentFocus),
              position.row > 0 else {
            // Focus first element in first column if nothing focused or at top
            focusedElement = gridStructure.first?.first
            return
        }

        focusedElement = gridStructure[position.column][position.row - 1]
    }

    private func moveDown() {
        guard let currentFocus = focusedElement,
              let position = findPosition(of: currentFocus) else {
            // Focus first element if nothing focused
            focusedElement = gridStructure.first?.first
            return
        }

        let column = gridStructure[position.column]
        guard position.row < column.count - 1 else {
            // At bottom, stay there
            return
        }

        focusedElement = column[position.row + 1]
    }

    private func activateFocused() {
        guard let focused = focusedElement else { return }

        switch focused {
        case .project(let projectId):
            // Find and select the project
            for group in groups {
                if let project = group.projects.first(where: { $0.id == projectId }) {
                    onSelectProject(project)
                    return
                }
            }
        case .addButton:
            // Trigger add project
            onAddProject?()
        case .issue:
            // Issues not applicable in project views
            break
        }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 16) {
                ForEach(groups.sorted(by: { $0.order < $1.order })) { group in
                    GenericProjectColumn(
                        group: group,
                        grouping: grouping,
                        showAddButton: showAddButton,
                        onAddProject: onAddProject,
                        onSelectProject: onSelectProject,
                        focusedElement: $focusedElement
                    )
                    .environmentObject(dragManager)
                }
            }
            .padding(20)
        }
        .onAppear {
            // Clean up drag state when view appears
            dragManager.endDrag()
        }
        .onKeyPress(.upArrow) {
            moveUp()
            return .handled
        }
        .onKeyPress(.downArrow) {
            moveDown()
            return .handled
        }
        .onKeyPress(.leftArrow) {
            moveLeft()
            return .handled
        }
        .onKeyPress(.rightArrow) {
            moveRight()
            return .handled
        }
        .onKeyPress(.return) {
            activateFocused()
            return .handled
        }
        .onKeyPress(.escape) {
            focusedElement = nil
            return .handled
        }
    }
}

// MARK: - Generic Project List View

struct GenericProjectListView: View {
    let groups: [ProjectGroup]
    let grouping: ProjectGrouping
    let showAddButton: Bool
    let onAddProject: (() -> Void)?
    let onSelectProject: (Project) -> Void
    @FocusState private var focusedElement: FocusableElement?
    @StateObject private var dragManager = DragDropManager()

    init(groups: [ProjectGroup], grouping: ProjectGrouping, showAddButton: Bool = true, onAddProject: (() -> Void)? = nil, onSelectProject: @escaping (Project) -> Void) {
        self.groups = groups
        self.grouping = grouping
        self.showAddButton = showAddButton
        self.onAddProject = onAddProject
        self.onSelectProject = onSelectProject
    }

    // Build flat list of all focusable elements in order
    private var focusableElements: [FocusableElement] {
        var elements: [FocusableElement] = []
        for group in groups.sorted(by: { $0.order < $1.order }) {
            // Add all projects in this group
            for project in group.projects {
                elements.append(.project(project.id))
            }
            // Add the add button for this group if applicable
            if showAddButton {
                elements.append(.addButton(group.id))
            }
        }
        return elements
    }

    private func moveUp() {
        guard let currentFocus = focusedElement,
              let currentIndex = focusableElements.firstIndex(of: currentFocus),
              currentIndex > 0 else {
            // Focus first element if nothing focused or at top
            focusedElement = focusableElements.first
            return
        }
        focusedElement = focusableElements[currentIndex - 1]
    }

    private func moveDown() {
        guard let currentFocus = focusedElement,
              let currentIndex = focusableElements.firstIndex(of: currentFocus),
              currentIndex < focusableElements.count - 1 else {
            // Focus first element if nothing focused, stay at bottom if at end
            if focusedElement == nil {
                focusedElement = focusableElements.first
            }
            return
        }
        focusedElement = focusableElements[currentIndex + 1]
    }

    private func activateFocused() {
        guard let focused = focusedElement else { return }

        switch focused {
        case .project(let projectId):
            // Find and select the project
            for group in groups {
                if let project = group.projects.first(where: { $0.id == projectId }) {
                    onSelectProject(project)
                    return
                }
            }
        case .addButton:
            // Trigger add project
            onAddProject?()
        case .issue:
            // Issues not applicable in project views
            break
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(groups.sorted(by: { $0.order < $1.order })) { group in
                GenericProjectSection(
                    group: group,
                    grouping: grouping,
                    showAddButton: showAddButton,
                    onAddProject: onAddProject,
                    onSelectProject: onSelectProject,
                    focusedElement: $focusedElement
                )
                .environmentObject(dragManager)
            }
        }
        .padding(20)
        .onAppear {
            // Clean up drag state when view appears
            dragManager.endDrag()
        }
        .onKeyPress(.upArrow) {
            moveUp()
            return .handled
        }
        .onKeyPress(.downArrow) {
            moveDown()
            return .handled
        }
        .onKeyPress(.return) {
            activateFocused()
            return .handled
        }
        .onKeyPress(.escape) {
            focusedElement = nil
            return .handled
        }
    }
}

// MARK: - Generic Project Column (for Board)

struct GenericProjectColumn: View {
    let group: ProjectGroup
    let grouping: ProjectGrouping
    let showAddButton: Bool
    let onAddProject: (() -> Void)?
    let onSelectProject: (Project) -> Void
    @FocusState.Binding var focusedElement: FocusableElement?

    @EnvironmentObject var dragManager: DragDropManager
    @Environment(\.modelContext) private var modelContext

    private var color: Color {
        colorForProjectGroup(group)
    }

    private var isAddButtonFocused: Bool {
        if case .addButton(let id) = focusedElement {
            return id == group.id
        }
        return false
    }

    private func handleDrop(_ dragData: ProjectDragData, at position: DropPosition) -> Bool {
        // Find the dragged project
        guard let project = group.projects.first(where: { $0.id == dragData.projectId }) ??
                          findProjectInAllGroups(dragData.projectId) else {
            return false
        }

        // Update project properties if moving to different group
        if dragData.sourceGroupId != group.id {
            updateProjectForGroup(
                project: project,
                targetGroupId: group.id,
                grouping: grouping,
                modelContext: modelContext
            )
        }

        // Update sortOrder based on drop position
        let newSortOrder = calculateSortOrder(for: position, in: group, excluding: project)
        project.sortOrder = newSortOrder
        project.updatedAt = Date()

        try? modelContext.save()

        // End drag state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            dragManager.endDrag()
        }

        return true
    }

    private func calculateSortOrder(for position: DropPosition, in group: ProjectGroup, excluding project: Project) -> Double {
        // Get all projects in this group except the one being dragged
        let otherProjects = group.projects.filter { $0.id != project.id }.sorted { $0.effectiveSortOrder < $1.effectiveSortOrder }

        switch position {
        case .before(let beforeProjectId):
            // Find the project we're inserting before
            guard let beforeProject = group.projects.first(where: { $0.id == beforeProjectId }) else {
                return Date().timeIntervalSince1970
            }

            // Find the project before this one (if any)
            if let beforeIndex = otherProjects.firstIndex(where: { $0.id == beforeProjectId }),
               beforeIndex > 0 {
                let previousProject = otherProjects[beforeIndex - 1]
                // Insert between previous and before
                return (previousProject.effectiveSortOrder + beforeProject.effectiveSortOrder) / 2.0
            } else {
                // Insert before the first project
                return beforeProject.effectiveSortOrder - 1.0
            }

        case .end:
            // Insert at the end
            if let lastProject = otherProjects.last {
                return lastProject.effectiveSortOrder + 1.0
            } else {
                return Date().timeIntervalSince1970
            }

        case .empty:
            // First item in empty group
            return Date().timeIntervalSince1970
        }
    }

    private func findProjectInAllGroups(_ projectId: UUID) -> Project? {
        // Search through model context for the project
        let descriptor = FetchDescriptor<Project>(
            predicate: #Predicate { $0.id == projectId }
        )
        return try? modelContext.fetch(descriptor).first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Column header
            HStack {
                Text(group.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                Text("\(group.projects.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.tertiary.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Project cards
            ScrollView {
                VStack(spacing: 8) {
                    if group.projects.isEmpty {
                        // Show empty drop zone when dragging
                        if dragManager.isDragging {
                            EmptyProjectGroupDropZone(group: group, onDrop: handleDrop)
                                .transition(.opacity.combined(with: .scale))
                        } else {
                            Text("No projects")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                    } else {
                        ForEach(group.projects, id: \.id) { project in
                            // Drop zone before each card
                            ProjectDropZone(
                                groupId: group.id,
                                position: .before(project.id),
                                onDrop: handleDrop
                            )

                            // Draggable card
                            DraggableProjectCard(
                                project: project,
                                groupId: group.id,
                                grouping: grouping,
                                onSelect: { onSelectProject(project) },
                                focusedElement: $focusedElement
                            )
                        }

                        // Drop zone at end
                        ProjectDropZone(
                            groupId: group.id,
                            position: .end,
                            onDrop: handleDrop
                        )
                    }

                    // Add project button
                    if showAddButton {
                        Button(action: { onAddProject?() }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(.secondary)

                                Text("Add Project")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(isAddButtonFocused ? Color.accentColor.opacity(0.1) : Color(nsColor: .controlBackgroundColor).opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isAddButtonFocused ? Color.accentColor : .clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                        .focusable()
                        .focused($focusedElement, equals: .addButton(group.id))
                        .onTapGesture {
                            focusedElement = .addButton(group.id)
                        }
                    }
                }
            }
        }
        .frame(minWidth: 250, maxWidth: 400)
    }
}

// MARK: - Generic Project Section (for List)

struct GenericProjectSection: View {
    let group: ProjectGroup
    let grouping: ProjectGrouping
    let showAddButton: Bool
    let onAddProject: (() -> Void)?
    let onSelectProject: (Project) -> Void
    @FocusState.Binding var focusedElement: FocusableElement?

    @EnvironmentObject var dragManager: DragDropManager
    @Environment(\.modelContext) private var modelContext

    private var color: Color {
        colorForProjectGroup(group)
    }

    private var isAddButtonFocused: Bool {
        if case .addButton(let id) = focusedElement {
            return id == group.id
        }
        return false
    }

    private func handleDrop(_ dragData: ProjectDragData, at position: DropPosition) -> Bool {
        // Find the dragged project
        guard let project = group.projects.first(where: { $0.id == dragData.projectId }) ??
                          findProjectInAllGroups(dragData.projectId) else {
            return false
        }

        // Update project properties if moving to different group
        if dragData.sourceGroupId != group.id {
            updateProjectForGroup(
                project: project,
                targetGroupId: group.id,
                grouping: grouping,
                modelContext: modelContext
            )
        }

        // Update sortOrder based on drop position
        let newSortOrder = calculateSortOrder(for: position, in: group, excluding: project)
        project.sortOrder = newSortOrder
        project.updatedAt = Date()

        try? modelContext.save()

        // End drag state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            dragManager.endDrag()
        }

        return true
    }

    private func calculateSortOrder(for position: DropPosition, in group: ProjectGroup, excluding project: Project) -> Double {
        // Get all projects in this group except the one being dragged
        let otherProjects = group.projects.filter { $0.id != project.id }.sorted { $0.effectiveSortOrder < $1.effectiveSortOrder }

        switch position {
        case .before(let beforeProjectId):
            // Find the project we're inserting before
            guard let beforeProject = group.projects.first(where: { $0.id == beforeProjectId }) else {
                return Date().timeIntervalSince1970
            }

            // Find the project before this one (if any)
            if let beforeIndex = otherProjects.firstIndex(where: { $0.id == beforeProjectId }),
               beforeIndex > 0 {
                let previousProject = otherProjects[beforeIndex - 1]
                // Insert between previous and before
                return (previousProject.effectiveSortOrder + beforeProject.effectiveSortOrder) / 2.0
            } else {
                // Insert before the first project
                return beforeProject.effectiveSortOrder - 1.0
            }

        case .end:
            // Insert at the end
            if let lastProject = otherProjects.last {
                return lastProject.effectiveSortOrder + 1.0
            } else {
                return Date().timeIntervalSince1970
            }

        case .empty:
            // First item in empty group
            return Date().timeIntervalSince1970
        }
    }

    private func findProjectInAllGroups(_ projectId: UUID) -> Project? {
        // Search through model context for the project
        let descriptor = FetchDescriptor<Project>(
            predicate: #Predicate { $0.id == projectId }
        )
        return try? modelContext.fetch(descriptor).first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Text(group.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                Text("\(group.projects.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.tertiary.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                // Add project button
                if showAddButton {
                    Button(action: { onAddProject?() }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(color)
                    }
                    .buttonStyle(.plain)
                    .padding(4)
                    .background(isAddButtonFocused ? Color.accentColor.opacity(0.1) : .clear)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(isAddButtonFocused ? Color.accentColor : .clear, lineWidth: 2)
                    )
                    .focusable()
                    .focused($focusedElement, equals: .addButton(group.id))
                    .onTapGesture {
                        focusedElement = .addButton(group.id)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Project cards
            VStack(spacing: 8) {
                if group.projects.isEmpty {
                    // Show empty drop zone when dragging
                    if dragManager.isDragging {
                        EmptyProjectGroupDropZone(group: group, onDrop: handleDrop)
                            .transition(.opacity.combined(with: .scale))
                    } else {
                        Text("No projects")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                } else {
                    ForEach(group.projects, id: \.id) { project in
                        // Drop zone before each card
                        ProjectDropZone(
                            groupId: group.id,
                            position: .before(project.id),
                            onDrop: handleDrop
                        )

                        // Draggable card
                        DraggableProjectCard(
                            project: project,
                            groupId: group.id,
                            grouping: grouping,
                            onSelect: { onSelectProject(project) },
                            focusedElement: $focusedElement
                        )
                    }

                    // Drop zone at end
                    ProjectDropZone(
                        groupId: group.id,
                        position: .end,
                        onDrop: handleDrop
                    )
                }
            }
        }
    }
}
