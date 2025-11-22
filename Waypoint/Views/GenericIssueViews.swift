//
//  GenericIssueViews.swift
//  Waypoint
//

import SwiftUI
import SwiftData

// MARK: - Issue Defaults

struct IssueDefaults {
	var status: Status?
	var priority: IssuePriority?
	var project: Project?
	var dueDate: Date?
	var tags: Set<UUID>?
}

// MARK: - Generic Board View

struct GenericIssueBoardView: View {
    let groups: [IssueGroup]
    let grouping: IssueGrouping
    let showAddButton: Bool
    let onAddIssue: ((IssueDefaults) -> Void)?
    @Binding var isInspectorVisible: Bool
    @FocusState private var focusedElement: FocusableElement?
    @Environment(ProjectStore.self) private var projectStore
    @Environment(\.modelContext) private var modelContext
    @StateObject private var dragManager = DragDropManager()

    init(groups: [IssueGroup], grouping: IssueGrouping, showAddButton: Bool = true, onAddIssue: ((IssueDefaults) -> Void)? = nil, isInspectorVisible: Binding<Bool>) {
        self.groups = groups
        self.grouping = grouping
        self.showAddButton = showAddButton
        self.onAddIssue = onAddIssue
        self._isInspectorVisible = isInspectorVisible
    }

    // Build 2D grid structure: array of columns, each containing array of elements
    private var gridStructure: [[FocusableElement]] {
        var grid: [[FocusableElement]] = []
        for group in groups.sorted(by: { $0.order < $1.order }) {
            var column: [FocusableElement] = []
            // Add all issues
            for issue in group.issues {
                column.append(.issue(issue.id))
            }
            // Add the add button if applicable
            if showAddButton && shouldShowAddButton(for: group, grouping: grouping) {
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
        case .issue(let issueId):
            // Find and select the issue
            for group in groups {
                if let issue = group.issues.first(where: { $0.id == issueId }) {
                    projectStore.selectedIssue = issue
                    isInspectorVisible = true
                    return
                }
            }
        case .addButton(let groupId):
            // Trigger add issue for this group
            if let group = groups.first(where: { $0.id == groupId }) {
                let defaults = defaultsForGroup(group, grouping: grouping, modelContext: modelContext)
                onAddIssue?(defaults)
            }
        case .project:
            // Projects not applicable in issue views
            break
        }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 16) {
                ForEach(groups.sorted(by: { $0.order < $1.order })) { group in
                    GenericIssueColumn(
                        group: group,
                        grouping: grouping,
                        showAddButton: showAddButton,
                        onAddIssue: onAddIssue,
                        isInspectorVisible: $isInspectorVisible,
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

// MARK: - Generic List View

struct GenericIssueListView: View {
    let groups: [IssueGroup]
    let grouping: IssueGrouping
    let showAddButton: Bool
    let onAddIssue: ((IssueDefaults) -> Void)?
    @Binding var isInspectorVisible: Bool
    @FocusState private var focusedElement: FocusableElement?
    @Environment(ProjectStore.self) private var projectStore
    @Environment(\.modelContext) private var modelContext
    @StateObject private var dragManager = DragDropManager()

    init(groups: [IssueGroup], grouping: IssueGrouping, showAddButton: Bool = true, onAddIssue: ((IssueDefaults) -> Void)? = nil, isInspectorVisible: Binding<Bool>) {
        self.groups = groups
        self.grouping = grouping
        self.showAddButton = showAddButton
        self.onAddIssue = onAddIssue
        self._isInspectorVisible = isInspectorVisible
    }

    // Build flat list of all focusable elements in order
    private var focusableElements: [FocusableElement] {
        var elements: [FocusableElement] = []
        for group in groups.sorted(by: { $0.order < $1.order }) {
            // Add all issues in this group
            for issue in group.issues {
                elements.append(.issue(issue.id))
            }
            // Add the add button for this group if applicable
            if showAddButton && shouldShowAddButton(for: group, grouping: grouping) {
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
        case .issue(let issueId):
            // Find and select the issue
            for group in groups {
                if let issue = group.issues.first(where: { $0.id == issueId }) {
                    projectStore.selectedIssue = issue
                    isInspectorVisible = true
                    return
                }
            }
        case .addButton(let groupId):
            // Trigger add issue for this group
            if let group = groups.first(where: { $0.id == groupId }) {
                let defaults = defaultsForGroup(group, grouping: grouping, modelContext: modelContext)
                onAddIssue?(defaults)
            }
        case .project:
            // Projects not applicable in issue views
            break
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(groups.sorted(by: { $0.order < $1.order })) { group in
                GenericIssueSection(
                    group: group,
                    grouping: grouping,
                    showAddButton: showAddButton,
                    onAddIssue: onAddIssue,
                    isInspectorVisible: $isInspectorVisible,
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

// MARK: - Generic Issue Column (for Board)

struct GenericIssueColumn: View {
    let group: IssueGroup
    let grouping: IssueGrouping
    let showAddButton: Bool
    let onAddIssue: ((IssueDefaults) -> Void)?
    @Binding var isInspectorVisible: Bool
    @FocusState.Binding var focusedElement: FocusableElement?

    @EnvironmentObject var dragManager: DragDropManager
    @Environment(\.modelContext) private var modelContext

    private var color: Color {
        colorForGroup(group)
    }

    private var isAddButtonFocused: Bool {
        if case .addButton(let id) = focusedElement {
            return id == group.id
        }
        return false
    }

    private func handleDrop(_ dragData: IssueDragData, at position: DropPosition) -> Bool {
        // Find the dragged issue
        guard let issue = group.issues.first(where: { $0.id == dragData.issueId }) ??
                          findIssueInAllGroups(dragData.issueId) else {
            return false
        }

        // Update issue properties if moving to different group
        if dragData.sourceGroupId != group.id {
            updateIssueForGroup(
                issue: issue,
                targetGroupId: group.id,
                grouping: grouping,
                modelContext: modelContext
            )
        }

        // End drag state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            dragManager.endDrag()
        }

        return true
    }

    private func findIssueInAllGroups(_ issueId: UUID) -> Issue? {
        // Search through model context for the issue
        let descriptor = FetchDescriptor<Issue>(
            predicate: #Predicate { $0.id == issueId }
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

                Text("\(group.issues.count)")
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

            // Issue cards
            ScrollView {
                VStack(spacing: 8) {
                    if group.issues.isEmpty {
                        // Show empty drop zone when dragging
                        if dragManager.isDragging {
                            EmptyGroupDropZone(group: group, onDrop: handleDrop)
                                .transition(.opacity.combined(with: .scale))
                        } else {
                            Text("No issues")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                    } else {
                        ForEach(group.issues) { issue in
                            // Drop zone before each card
                            IssueDropZone(
                                groupId: group.id,
                                position: .before(issue.id),
                                onDrop: handleDrop
                            )

                            // Draggable card
                            DraggableIssueCard(
                                issue: issue,
                                groupId: group.id,
                                grouping: grouping,
                                isInspectorVisible: $isInspectorVisible,
                                focusedElement: $focusedElement
                            )
                        }

                        // Drop zone at end
                        IssueDropZone(
                            groupId: group.id,
                            position: .end,
                            onDrop: handleDrop
                        )
                    }

                    // Add issue button (for all applicable groupings)
                    if showAddButton, shouldShowAddButton(for: group, grouping: grouping) {
                        Button(action: {
                            let defaults = defaultsForGroup(group, grouping: grouping, modelContext: modelContext)
                            onAddIssue?(defaults)
                        }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(.secondary)

                                Text("Add Issue")
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

// MARK: - Generic Issue Section (for List)

struct GenericIssueSection: View {
    let group: IssueGroup
    let grouping: IssueGrouping
    let showAddButton: Bool
    let onAddIssue: ((IssueDefaults) -> Void)?
    @Binding var isInspectorVisible: Bool
    @FocusState.Binding var focusedElement: FocusableElement?

    @EnvironmentObject var dragManager: DragDropManager
    @Environment(\.modelContext) private var modelContext

    private var color: Color {
        colorForGroup(group)
    }

    private var isAddButtonFocused: Bool {
        if case .addButton(let id) = focusedElement {
            return id == group.id
        }
        return false
    }

    private func handleDrop(_ dragData: IssueDragData, at position: DropPosition) -> Bool {
        // Find the dragged issue
        guard let issue = group.issues.first(where: { $0.id == dragData.issueId }) ??
                          findIssueInAllGroups(dragData.issueId) else {
            return false
        }

        // Update issue properties if moving to different group
        if dragData.sourceGroupId != group.id {
            updateIssueForGroup(
                issue: issue,
                targetGroupId: group.id,
                grouping: grouping,
                modelContext: modelContext
            )
        }

        // End drag state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            dragManager.endDrag()
        }

        return true
    }

    private func findIssueInAllGroups(_ issueId: UUID) -> Issue? {
        // Search through model context for the issue
        let descriptor = FetchDescriptor<Issue>(
            predicate: #Predicate { $0.id == issueId }
        )
        return try? modelContext.fetch(descriptor).first
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

                    Text("\(group.issues.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.tertiary.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                Spacer()

                // Add button (for all applicable groupings)
                if showAddButton, shouldShowAddButton(for: group, grouping: grouping) {
                    Button(action: {
                        let defaults = defaultsForGroup(group, grouping: grouping, modelContext: modelContext)
                        onAddIssue?(defaults)
                    }) {
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

            // Issue cards
            VStack(spacing: 8) {
                if group.issues.isEmpty {
                    // Show empty drop zone when dragging
                    if dragManager.isDragging {
                        EmptyGroupDropZone(group: group, onDrop: handleDrop)
                            .transition(.opacity.combined(with: .scale))
                    } else {
                        Text("No issues")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                } else {
                    ForEach(group.issues) { issue in
                        // Drop zone before each card
                        IssueDropZone(
                            groupId: group.id,
                            position: .before(issue.id),
                            onDrop: handleDrop
                        )

                        // Draggable card
                        DraggableIssueCard(
                            issue: issue,
                            groupId: group.id,
                            grouping: grouping,
                            isInspectorVisible: $isInspectorVisible,
                            focusedElement: $focusedElement
                        )
                    }

                    // Drop zone at end
                    IssueDropZone(
                        groupId: group.id,
                        position: .end,
                        onDrop: handleDrop
                    )
                }
            }
        }
    }
}

// MARK: - Helper Functions

private func colorForGroup(_ group: IssueGroup) -> Color {
    // Try to match status-based colors
    switch group.id {
    case "todo": return .gray
    case "inProgress": return .orange
    case "review": return .purple
    case "done": return .green
    case "urgent": return .red
    case "high": return .orange
    case "medium": return .blue
    case "low": return .gray
    case "overdue": return .red
    case "today": return .orange
    case "tomorrow": return .blue
    default: return .blue
    }
}

private func statusForGroup(_ group: IssueGroup) -> Status? {
    // Only return status if this is a status-based group
    switch group.id {
    case "todo": return .todo
    case "inProgress": return .inProgress
    case "review": return .review
    case "done": return .done
    default: return nil
    }
}

private func priorityForGroup(_ group: IssueGroup) -> IssuePriority? {
    // Only return priority if this is a priority-based group
    switch group.id {
    case "low": return .low
    case "medium": return .medium
    case "high": return .high
    case "urgent": return .urgent
    default: return nil
    }
}

private func projectIdForGroup(_ group: IssueGroup) -> UUID? {
    // Return project UUID from group ID (excludes "no-project")
    if group.id == "no-project" {
        return nil // Explicitly no project
    }
    return UUID(uuidString: group.id)
}

private func dueDateForGroup(_ group: IssueGroup) -> Date? {
    // Return due date based on group ID
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())

    switch group.id {
    case "overdue":
        // Set to yesterday for overdue
        return calendar.date(byAdding: .day, value: -1, to: today)
    case "today":
        return today
    case "tomorrow":
        return calendar.date(byAdding: .day, value: 1, to: today)
    case "this-week":
        // Set to 3 days from now (middle of the week)
        return calendar.date(byAdding: .day, value: 3, to: today)
    case "later":
        // Set to 2 weeks from now
        return calendar.date(byAdding: .day, value: 14, to: today)
    default:
        return nil
    }
}

private func tagIdForGroup(_ group: IssueGroup) -> UUID? {
    // Return tag UUID from group ID (excludes "no-tags")
    if group.id == "no-tags" {
        return nil
    }
    return UUID(uuidString: group.id)
}

private func defaultsForGroup(_ group: IssueGroup, grouping: IssueGrouping, modelContext: ModelContext) -> IssueDefaults {
    var defaults = IssueDefaults()

    switch grouping {
    case .status:
        defaults.status = statusForGroup(group)
    case .priority:
        defaults.priority = priorityForGroup(group)
    case .project:
        if let projectId = projectIdForGroup(group) {
            // Fetch the project from model context
            let descriptor = FetchDescriptor<Project>(
                predicate: #Predicate { $0.id == projectId }
            )
            defaults.project = try? modelContext.fetch(descriptor).first
        }
    case .dueDate:
        defaults.dueDate = dueDateForGroup(group)
    case .tags:
        if let tagId = tagIdForGroup(group) {
            defaults.tags = [tagId]
        }
    case .none:
        break
    }

    return defaults
}

private func shouldShowAddButton(for group: IssueGroup, grouping: IssueGrouping) -> Bool {
    // Determine if this group can provide meaningful defaults for new issues
    switch grouping {
    case .status:
        return statusForGroup(group) != nil
    case .priority:
        return priorityForGroup(group) != nil
    case .project:
        // Show for all project groups (including "no-project")
        return true
    case .dueDate:
        return dueDateForGroup(group) != nil
    case .tags:
        return tagIdForGroup(group) != nil
    case .none:
        return false
    }
}
