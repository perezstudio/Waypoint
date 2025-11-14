//
//  GenericProjectViews.swift
//  Waypoint
//
//  Created by Claude on 11/13/25.
//

import SwiftUI

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
    let showAddButton: Bool
    let onAddProject: (() -> Void)?
    let onSelectProject: (Project) -> Void
    @FocusState private var focusedElement: FocusableElement?

    init(groups: [ProjectGroup], showAddButton: Bool = true, onAddProject: (() -> Void)? = nil, onSelectProject: @escaping (Project) -> Void) {
        self.groups = groups
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
                        showAddButton: showAddButton,
                        onAddProject: onAddProject,
                        onSelectProject: onSelectProject,
                        focusedElement: $focusedElement
                    )
                }
            }
            .padding(20)
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
    let showAddButton: Bool
    let onAddProject: (() -> Void)?
    let onSelectProject: (Project) -> Void
    @FocusState private var focusedElement: FocusableElement?

    init(groups: [ProjectGroup], showAddButton: Bool = true, onAddProject: (() -> Void)? = nil, onSelectProject: @escaping (Project) -> Void) {
        self.groups = groups
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
                    showAddButton: showAddButton,
                    onAddProject: onAddProject,
                    onSelectProject: onSelectProject,
                    focusedElement: $focusedElement
                )
            }
        }
        .padding(20)
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
    let showAddButton: Bool
    let onAddProject: (() -> Void)?
    let onSelectProject: (Project) -> Void
    @FocusState.Binding var focusedElement: FocusableElement?

    private var color: Color {
        colorForProjectGroup(group)
    }

    private var isAddButtonFocused: Bool {
        if case .addButton(let id) = focusedElement {
            return id == group.id
        }
        return false
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
                    ForEach(group.projects, id: \.id) { project in
                        ProjectCard(
                            project: project,
                            onSelect: { onSelectProject(project) },
                            focusedElement: $focusedElement
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

                    if group.projects.isEmpty {
                        Text("No projects")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
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
    let showAddButton: Bool
    let onAddProject: (() -> Void)?
    let onSelectProject: (Project) -> Void
    @FocusState.Binding var focusedElement: FocusableElement?

    private var color: Color {
        colorForProjectGroup(group)
    }

    private var isAddButtonFocused: Bool {
        if case .addButton(let id) = focusedElement {
            return id == group.id
        }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)

                    Text(group.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("\(group.projects.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.tertiary.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                Spacer()

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

            // Project cards
            VStack(spacing: 8) {
                ForEach(group.projects, id: \.id) { project in
                    ProjectCard(
                        project: project,
                        onSelect: { onSelectProject(project) },
                        focusedElement: $focusedElement
                    )
                }

                if group.projects.isEmpty {
                    Text("No projects")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}
