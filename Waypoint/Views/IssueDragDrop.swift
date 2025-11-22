//
//  IssueDragDrop.swift
//  Waypoint
//
//  Drag and drop components for issue cards
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import Combine

// MARK: - Drag Drop Manager

@MainActor
class DragDropManager: ObservableObject {
	@Published var isDragging: Bool = false
	@Published var draggedIssueId: UUID? = nil
	@Published var hoveredGroupId: String? = nil
	@Published var hoveredDropZoneId: String? = nil

	func startDrag(_ issueId: UUID) {
		isDragging = true
		draggedIssueId = issueId
	}

	func endDrag() {
		isDragging = false
		draggedIssueId = nil
		hoveredGroupId = nil
		hoveredDropZoneId = nil
	}

	func updateHoveredGroup(_ groupId: String?) {
		hoveredGroupId = groupId
	}

	func updateHoveredDropZone(_ zoneId: String?) {
		hoveredDropZoneId = zoneId
	}
}

// MARK: - Drag Data

struct IssueDragData: Codable, Transferable {
	let issueId: UUID
	let sourceGroupId: String
	let currentGrouping: IssueGrouping

	static var transferRepresentation: some TransferRepresentation {
		CodableRepresentation(contentType: .data)
	}
}

// Wrapper class for NSItemProvider
class IssueDragDataWrapper: NSObject, NSItemProviderWriting {
	let data: IssueDragData

	init(data: IssueDragData) {
		self.data = data
		super.init()
	}

	static var writableTypeIdentifiersForItemProvider: [String] {
		[UTType.data.identifier]
	}

	func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
		let encoder = JSONEncoder()
		do {
			let encoded = try encoder.encode(data)
			completionHandler(encoded, nil)
		} catch {
			completionHandler(nil, error)
		}
		return nil
	}
}

// MARK: - Drop Position

enum DropPosition: Equatable, Hashable {
	case before(UUID) // Before specific issue
	case end // End of list
	case empty // In empty group

	var id: String {
		switch self {
		case .before(let id): return "before-\(id.uuidString)"
		case .end: return "end"
		case .empty: return "empty"
		}
	}
}

// MARK: - Issue Drop Zone (Between Cards)

struct IssueDropZone: View {
	let groupId: String
	let position: DropPosition
	let onDrop: (IssueDragData, DropPosition) -> Bool

	@EnvironmentObject var dragManager: DragDropManager
	@State private var isHovered: Bool = false

	private var isActive: Bool {
		dragManager.isDragging && isHovered
	}

	private var dropZoneHeight: CGFloat {
		isActive ? 40 : 4
	}

	var body: some View {
		Rectangle()
			.fill(isActive ? Color.accentColor.opacity(0.2) : Color.clear)
			.frame(height: dropZoneHeight)
			.frame(maxWidth: .infinity)
			.animation(.spring(response: 0.3, dampingFraction: 0.8), value: isActive)
			.dropDestination(for: IssueDragData.self) { items, location in
				guard let dragData = items.first else { return false }
				return onDrop(dragData, position)
			} isTargeted: { targeted in
				withAnimation {
					isHovered = targeted
					if targeted {
						dragManager.updateHoveredDropZone(position.id)
					} else if dragManager.hoveredDropZoneId == position.id {
						dragManager.updateHoveredDropZone(nil)
					}
				}
			}
	}
}

// MARK: - Empty Group Drop Zone

struct EmptyGroupDropZone: View {
	let group: IssueGroup
	let onDrop: (IssueDragData, DropPosition) -> Bool

	@EnvironmentObject var dragManager: DragDropManager
	@State private var isHovered: Bool = false

	private var isActive: Bool {
		dragManager.isDragging && (isHovered || dragManager.hoveredGroupId == group.id)
	}

	var body: some View {
		VStack(spacing: 12) {
			Image(systemName: "arrow.down.circle")
				.font(.system(size: 32))
				.foregroundStyle(isActive ? Color.accentColor : .secondary)

			Text("Drop here")
				.font(.subheadline)
				.foregroundStyle(isActive ? Color.accentColor : .secondary)
		}
		.frame(maxWidth: .infinity)
		.frame(height: 120)
		.background(
			RoundedRectangle(cornerRadius: 8)
				.fill(isActive ? Color.accentColor.opacity(0.15) : Color.accentColor.opacity(0.05))
		)
		.overlay(
			RoundedRectangle(cornerRadius: 8)
				.strokeBorder(
					isActive ? Color.accentColor : Color.accentColor.opacity(0.3),
					style: StrokeStyle(lineWidth: 2, dash: isActive ? [] : [8, 4])
				)
		)
		.scaleEffect(isActive ? 1.02 : 1.0)
		.animation(.spring(response: 0.3, dampingFraction: 0.8), value: isActive)
		.dropDestination(for: IssueDragData.self) { items, location in
			guard let dragData = items.first else { return false }
			return onDrop(dragData, .empty)
		} isTargeted: { targeted in
			withAnimation {
				isHovered = targeted
				if targeted {
					dragManager.updateHoveredGroup(group.id)
				} else if dragManager.hoveredGroupId == group.id {
					dragManager.updateHoveredGroup(nil)
				}
			}
		}
	}
}

// MARK: - Draggable Issue Card

struct DraggableIssueCard: View {
	let issue: Issue
	let groupId: String
	let grouping: IssueGrouping
	@Binding var isInspectorVisible: Bool
	@FocusState.Binding var focusedElement: FocusableElement?

	@EnvironmentObject var dragManager: DragDropManager

	private var isDragging: Bool {
		dragManager.draggedIssueId == issue.id
	}

	var body: some View {
		IssueCard(
			issue: issue,
			isInspectorVisible: $isInspectorVisible,
			focusedElement: $focusedElement
		)
		.opacity(isDragging ? 0.5 : 1.0)
		.scaleEffect(isDragging ? 0.95 : 1.0)
		.animation(.spring(response: 0.3, dampingFraction: 0.8), value: isDragging)
		.onDrag {
			// Start drag state immediately
			dragManager.startDrag(issue.id)

			// Return the drag data wrapped in NSItemProvider
			let dragData = IssueDragData(
				issueId: issue.id,
				sourceGroupId: groupId,
				currentGrouping: grouping
			)
			return NSItemProvider(object: IssueDragDataWrapper(data: dragData))
		} preview: {
			// Drag preview
			IssueCard(
				issue: issue,
				isInspectorVisible: $isInspectorVisible,
				focusedElement: $focusedElement
			)
			.frame(width: 250)
			.opacity(0.8)
		}
	}
}

// MARK: - Helper Functions

func updateIssueForGroup(
	issue: Issue,
	targetGroupId: String,
	grouping: IssueGrouping,
	modelContext: ModelContext
) {
	switch grouping {
	case .status:
		if let status = statusFromGroupId(targetGroupId) {
			issue.status = status
			issue.updatedAt = Date()
		}

	case .priority:
		if let priority = priorityFromGroupId(targetGroupId) {
			issue.priority = priority
			issue.updatedAt = Date()
		}

	case .project:
		// Find project by group ID
		let projectId = targetGroupId == "no-project" ? nil : UUID(uuidString: targetGroupId)
		if let projectId = projectId {
			let descriptor = FetchDescriptor<Project>(
				predicate: #Predicate { $0.id == projectId }
			)
			if let project = try? modelContext.fetch(descriptor).first {
				issue.project = project
				issue.updatedAt = Date()
			}
		} else {
			issue.project = nil
			issue.updatedAt = Date()
		}

	case .tags:
		// Tags are complex - would need to add/remove tags
		// For now, skip auto-update for tags
		break

	case .dueDate, .none:
		// These don't have property mappings
		break
	}

	try? modelContext.save()
}

private func statusFromGroupId(_ groupId: String) -> Status? {
	switch groupId {
	case "todo": return .todo
	case "inProgress": return .inProgress
	case "review": return .review
	case "done": return .done
	default: return nil
	}
}

private func priorityFromGroupId(_ groupId: String) -> IssuePriority? {
	switch groupId {
	case "low": return .low
	case "medium": return .medium
	case "high": return .high
	case "urgent": return .urgent
	default: return nil
	}
}
