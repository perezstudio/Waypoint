//
//  CreateIssueSheet.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/12/25.
//

import SwiftUI
import SwiftData

struct CreateIssueSheet: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(\.modelContext) private var modelContext
	@Query private var projects: [Project]
	@Query private var tags: [Tag]

	let defaultStatus: IssueStatus
	let project: Project?

	@State private var title: String = ""
	@State private var description: String = ""
	@State private var status: IssueStatus
	@State private var priority: IssuePriority = .medium
	@State private var dueDate: Date = Date()
	@State private var hasDueDate: Bool = false
	@State private var selectedProject: Project?
	@State private var selectedTags: Set<UUID> = []

	// Popover states
	@State private var showingStatusPicker: Bool = false
	@State private var showingPriorityPicker: Bool = false
	@State private var showingDueDatePicker: Bool = false
	@State private var showingProjectPicker: Bool = false
	@State private var showingTagsPicker: Bool = false

	@FocusState private var focusedField: Field?

	enum Field: Hashable {
		case title
		case description
	}

	init(defaultStatus: IssueStatus = .todo, project: Project? = nil) {
		self.defaultStatus = defaultStatus
		self.project = project
		_status = State(initialValue: defaultStatus)
		_selectedProject = State(initialValue: project)
	}

	var body: some View {
		VStack(spacing: 0) {
			// Title Field
			TextField("Issue title", text: $title, axis: .vertical)
				.textFieldStyle(.plain)
				.font(.title3)
				.fontWeight(.medium)
				.focused($focusedField, equals: .title)
				.lineLimit(1...2)
				.padding(.horizontal, 24)
				.padding(.top, 20)
				.padding(.bottom, 10)

			Divider()
				.padding(.horizontal, 24)

			// Description Field
			ZStack(alignment: .topLeading) {
				if description.isEmpty {
					Text("Add description...")
						.foregroundStyle(.tertiary)
						.padding(.horizontal, 24)
						.padding(.top, 10)
						.allowsHitTesting(false)
				}

				TextEditor(text: $description)
					.textEditorStyle(.plain)
					.font(.body)
					.focused($focusedField, equals: .description)
					.scrollContentBackground(.hidden)
					.padding(.horizontal, 20)
					.padding(.top, 6)
					.frame(minHeight: 80, maxHeight: 120)
			}

			Spacer()

			Divider()
				.padding(.horizontal, 24)

			// Properties Row
			HStack(spacing: 8) {
				ScrollView(.horizontal, showsIndicators: false) {
					HStack(spacing: 8) {
						// Status
						PropertyButton(
					icon: "circle.fill",
					label: statusLabel(for: status),
					color: statusColor(for: status),
					shortcut: "⌘S",
					showingPicker: $showingStatusPicker
				)
				.popover(isPresented: $showingStatusPicker, arrowEdge: .bottom) {
					StatusPickerPopover(selectedStatus: $status) {
						showingStatusPicker = false
					}
				}

				// Priority
				PropertyButton(
					icon: priorityIcon(for: priority),
					label: priority.rawValue.capitalized,
					color: priorityColor(for: priority),
					shortcut: "⌘P",
					showingPicker: $showingPriorityPicker
				)
				.popover(isPresented: $showingPriorityPicker, arrowEdge: .bottom) {
					PriorityPickerPopover(selectedPriority: $priority) {
						showingPriorityPicker = false
					}
				}

				// Due Date
				PropertyButton(
					icon: "calendar",
					label: hasDueDate ? dueDate.formatted(date: .abbreviated, time: .omitted) : "Due date",
					color: hasDueDate ? .blue : .secondary,
					shortcut: "⌘D",
					showingPicker: $showingDueDatePicker
				)
				.popover(isPresented: $showingDueDatePicker, arrowEdge: .bottom) {
					DueDatePickerPopover(hasDueDate: $hasDueDate, dueDate: $dueDate) {
						showingDueDatePicker = false
					}
				}

				// Project
				PropertyButton(
					icon: selectedProject?.icon ?? "folder",
					label: selectedProject?.name ?? "Project",
					color: selectedProject != nil ? Color(hex: selectedProject!.color) ?? .blue : .secondary,
					shortcut: "⌘J",
					showingPicker: $showingProjectPicker
				)
				.popover(isPresented: $showingProjectPicker, arrowEdge: .bottom) {
					ProjectPickerPopover(selectedProject: $selectedProject, projects: projects) {
						showingProjectPicker = false
					}
				}

				// Tags
				PropertyButton(
					icon: "tag",
					label: selectedTags.isEmpty ? "Tags" : "\(selectedTags.count) tag\(selectedTags.count == 1 ? "" : "s")",
					color: selectedTags.isEmpty ? .secondary : .blue,
					shortcut: "⌘T",
					showingPicker: $showingTagsPicker
				)
				.popover(isPresented: $showingTagsPicker, arrowEdge: .bottom) {
					TagsPickerPopover(selectedTags: $selectedTags, tags: tags) {
						showingTagsPicker = false
					}
				}
					}
				}

				// Create Button
				Button("Create") {
					createIssue()
				}
				.buttonStyle(.borderedProminent)
				.keyboardShortcut(.return, modifiers: .command)
				.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
			}
			.padding(.horizontal, 24)
			.padding(.vertical, 14)
		}
		.frame(width: 600, height: 300)
		.background(.ultraThinMaterial)
		.background(
			KeyboardShortcutHandler(
				showingStatusPicker: $showingStatusPicker,
				showingPriorityPicker: $showingPriorityPicker,
				showingDueDatePicker: $showingDueDatePicker,
				showingProjectPicker: $showingProjectPicker,
				showingTagsPicker: $showingTagsPicker
			)
		)
		.onAppear {
			focusedField = .title
		}
	}

	private func createIssue() {
		let newIssue = Issue(
			title: title.trimmingCharacters(in: .whitespacesAndNewlines),
			status: status,
			priority: priority,
			project: selectedProject
		)

		if !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
			newIssue.issueDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
		}

		if hasDueDate {
			newIssue.dueDate = dueDate
		}

		let selectedTagObjects = tags.filter { selectedTags.contains($0.id) }
		newIssue.tags = selectedTagObjects

		modelContext.insert(newIssue)
		dismiss()
	}

	// Helper functions
	private func statusColor(for status: IssueStatus) -> Color {
		switch status {
		case .todo: return .gray
		case .inProgress: return .orange
		case .review: return .purple
		case .done: return .green
		}
	}

	private func statusLabel(for status: IssueStatus) -> String {
		switch status {
		case .todo: return "To Do"
		case .inProgress: return "In Progress"
		case .review: return "Review"
		case .done: return "Done"
		}
	}

	private func priorityColor(for priority: IssuePriority) -> Color {
		switch priority {
		case .urgent: return .red
		case .high: return .orange
		case .medium: return .blue
		case .low: return .gray
		}
	}

	private func priorityIcon(for priority: IssuePriority) -> String {
		switch priority {
		case .urgent: return "exclamationmark.3"
		case .high: return "exclamationmark.2"
		case .medium: return "equal"
		case .low: return "minus"
		}
	}
}

// MARK: - Property Button

struct PropertyButton: View {
	let icon: String
	let label: String
	let color: Color
	let shortcut: String
	@Binding var showingPicker: Bool

	@State private var isHovered: Bool = false

	private var shortcutLetter: String {
		// Extract just the letter from "⌘S" -> "S"
		shortcut.replacingOccurrences(of: "⌘", with: "")
	}

	var body: some View {
		Button(action: { showingPicker = true }) {
			HStack(spacing: 6) {
				Image(systemName: icon)
					.font(.system(size: 11))
					.foregroundStyle(color)
					.frame(width: 12)

				Text(label)
					.font(.subheadline)
					.foregroundStyle(.primary)
					.lineLimit(1)
					.fixedSize()

				Text(shortcutLetter)
					.font(.caption2)
					.fontWeight(.medium)
					.foregroundStyle(.quaternary)
					.padding(.leading, 2)
			}
			.padding(.horizontal, 10)
			.padding(.vertical, 6)
			.background(
				RoundedRectangle(cornerRadius: 6, style: .continuous)
					.fill(Color.secondary.opacity(isHovered ? 0.15 : 0.08))
			)
		}
		.buttonStyle(.plain)
		.onHover { hovering in
			withAnimation(.easeInOut(duration: 0.15)) {
				isHovered = hovering
			}
		}
	}
}

// MARK: - Keyboard Shortcut Handler

struct KeyboardShortcutHandler: View {
	@Binding var showingStatusPicker: Bool
	@Binding var showingPriorityPicker: Bool
	@Binding var showingDueDatePicker: Bool
	@Binding var showingProjectPicker: Bool
	@Binding var showingTagsPicker: Bool

	var body: some View {
		ZStack {
			Button("") { showingStatusPicker = true }
				.keyboardShortcut("s", modifiers: .command)
				.hidden()

			Button("") { showingPriorityPicker = true }
				.keyboardShortcut("p", modifiers: .command)
				.hidden()

			Button("") { showingDueDatePicker = true }
				.keyboardShortcut("d", modifiers: .command)
				.hidden()

			Button("") { showingProjectPicker = true }
				.keyboardShortcut("j", modifiers: .command)
				.hidden()

			Button("") { showingTagsPicker = true }
				.keyboardShortcut("t", modifiers: .command)
				.hidden()
		}
		.frame(width: 0, height: 0)
	}
}

// MARK: - Status Picker Popover

struct StatusPickerPopover: View {
	@Binding var selectedStatus: IssueStatus
	let onDismiss: () -> Void

	@State private var selectedIndex: Int = 0
	@FocusState private var isFocused: Bool

	private let statuses: [IssueStatus] = [.todo, .inProgress, .review, .done]

	var body: some View {
		VStack(spacing: 4) {
			ForEach(Array(statuses.enumerated()), id: \.offset) { index, status in
				Button(action: {
					selectedStatus = status
					onDismiss()
				}) {
					HStack(spacing: 12) {
						Circle()
							.fill(statusColor(for: status))
							.frame(width: 8, height: 8)

						Text(statusLabel(for: status))
							.font(.subheadline)
							.foregroundStyle(.primary)

						Spacer()

						if selectedStatus == status {
							Image(systemName: "checkmark")
								.font(.caption)
								.foregroundStyle(.secondary)
						}
					}
					.padding(.horizontal, 10)
					.padding(.vertical, 8)
					.background(
						RoundedRectangle(cornerRadius: 6)
							.fill(selectedIndex == index ? Color.accentColor.opacity(0.1) : Color.clear)
					)
				}
				.buttonStyle(.plain)
				.onHover { isHovering in
					if isHovering {
						selectedIndex = index
					}
				}
			}
		}
		.padding(8)
		.frame(width: 200)
		.focusable()
		.focused($isFocused)
		.focusEffectDisabled()
		.onAppear {
			if let index = statuses.firstIndex(of: selectedStatus) {
				selectedIndex = index
			}
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
				isFocused = true
			}
		}
		.onKeyPress(.upArrow) {
			selectedIndex = selectedIndex > 0 ? selectedIndex - 1 : statuses.count - 1
			return .handled
		}
		.onKeyPress(.downArrow) {
			selectedIndex = selectedIndex < statuses.count - 1 ? selectedIndex + 1 : 0
			return .handled
		}
		.onKeyPress(.return) {
			if selectedIndex < statuses.count {
				selectedStatus = statuses[selectedIndex]
				onDismiss()
			}
			return .handled
		}
		.onKeyPress(.escape) {
			onDismiss()
			return .handled
		}
	}

	private func statusColor(for status: IssueStatus) -> Color {
		switch status {
		case .todo: return .gray
		case .inProgress: return .orange
		case .review: return .purple
		case .done: return .green
		}
	}

	private func statusLabel(for status: IssueStatus) -> String {
		switch status {
		case .todo: return "To Do"
		case .inProgress: return "In Progress"
		case .review: return "Review"
		case .done: return "Done"
		}
	}
}

// MARK: - Priority Picker Popover

struct PriorityPickerPopover: View {
	@Binding var selectedPriority: IssuePriority
	let onDismiss: () -> Void

	@State private var selectedIndex: Int = 0
	@FocusState private var isFocused: Bool

	private let priorities: [IssuePriority] = [.low, .medium, .high, .urgent]

	var body: some View {
		VStack(spacing: 4) {
			ForEach(Array(priorities.enumerated()), id: \.offset) { index, priority in
				Button(action: {
					selectedPriority = priority
					onDismiss()
				}) {
					HStack(spacing: 12) {
						Image(systemName: priorityIcon(for: priority))
							.font(.system(size: 12))
							.foregroundStyle(priorityColor(for: priority))
							.frame(width: 16)

						Text(priority.rawValue.capitalized)
							.font(.subheadline)
							.foregroundStyle(.primary)

						Spacer()

						if selectedPriority == priority {
							Image(systemName: "checkmark")
								.font(.caption)
								.foregroundStyle(.secondary)
						}
					}
					.padding(.horizontal, 10)
					.padding(.vertical, 8)
					.background(
						RoundedRectangle(cornerRadius: 6)
							.fill(selectedIndex == index ? Color.accentColor.opacity(0.1) : Color.clear)
					)
				}
				.buttonStyle(.plain)
				.onHover { isHovering in
					if isHovering {
						selectedIndex = index
					}
				}
			}
		}
		.padding(8)
		.frame(width: 200)
		.focusable()
		.focused($isFocused)
		.focusEffectDisabled()
		.onAppear {
			if let index = priorities.firstIndex(of: selectedPriority) {
				selectedIndex = index
			}
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
				isFocused = true
			}
		}
		.onKeyPress(.upArrow) {
			selectedIndex = selectedIndex > 0 ? selectedIndex - 1 : priorities.count - 1
			return .handled
		}
		.onKeyPress(.downArrow) {
			selectedIndex = selectedIndex < priorities.count - 1 ? selectedIndex + 1 : 0
			return .handled
		}
		.onKeyPress(.return) {
			if selectedIndex < priorities.count {
				selectedPriority = priorities[selectedIndex]
				onDismiss()
			}
			return .handled
		}
		.onKeyPress(.escape) {
			onDismiss()
			return .handled
		}
	}

	private func priorityColor(for priority: IssuePriority) -> Color {
		switch priority {
		case .urgent: return .red
		case .high: return .orange
		case .medium: return .blue
		case .low: return .gray
		}
	}

	private func priorityIcon(for priority: IssuePriority) -> String {
		switch priority {
		case .urgent: return "exclamationmark.3"
		case .high: return "exclamationmark.2"
		case .medium: return "equal"
		case .low: return "minus"
		}
	}
}

// MARK: - Due Date Picker Popover

struct DueDatePickerPopover: View {
	@Binding var hasDueDate: Bool
	@Binding var dueDate: Date
	let onDismiss: () -> Void

	var body: some View {
		VStack(spacing: 12) {
			Toggle("Set Due Date", isOn: $hasDueDate)
				.toggleStyle(.switch)
				.padding(.horizontal, 12)

			if hasDueDate {
				DatePicker("", selection: $dueDate, displayedComponents: .date)
					.datePickerStyle(.graphical)
					.labelsHidden()
			}

			HStack {
				Button("Clear") {
					hasDueDate = false
					onDismiss()
				}
				.buttonStyle(.plain)

				Spacer()

				Button("Done") {
					onDismiss()
				}
				.buttonStyle(.borderedProminent)
				.keyboardShortcut(.defaultAction)
			}
			.padding(.horizontal, 12)
		}
		.padding(.vertical, 12)
		.frame(width: 280)
		.onKeyPress(.escape) {
			onDismiss()
			return .handled
		}
	}
}

// MARK: - Project Picker Popover

struct ProjectPickerPopover: View {
	@Binding var selectedProject: Project?
	let projects: [Project]
	let onDismiss: () -> Void

	@State private var selectedIndex: Int = -1
	@FocusState private var isFocused: Bool

	var body: some View {
		VStack(spacing: 4) {
			Button(action: {
				selectedProject = nil
				onDismiss()
			}) {
				HStack(spacing: 12) {
					Image(systemName: "minus.circle")
						.font(.system(size: 14))
						.foregroundStyle(.secondary)
						.frame(width: 16)

					Text("None")
						.font(.subheadline)
						.foregroundStyle(.primary)

					Spacer()

					if selectedProject == nil {
						Image(systemName: "checkmark")
							.font(.caption)
							.foregroundStyle(.secondary)
					}
				}
				.padding(.horizontal, 10)
				.padding(.vertical, 8)
				.background(
					RoundedRectangle(cornerRadius: 6)
						.fill(selectedIndex == -1 ? Color.accentColor.opacity(0.1) : Color.clear)
				)
			}
			.buttonStyle(.plain)
			.onHover { isHovering in
				if isHovering {
					selectedIndex = -1
				}
			}

			ForEach(Array(projects.enumerated()), id: \.element.id) { index, project in
				Button(action: {
					selectedProject = project
					onDismiss()
				}) {
					HStack(spacing: 12) {
						Image(systemName: project.icon)
							.font(.system(size: 14))
							.foregroundStyle(Color(hex: project.color) ?? .blue)
							.frame(width: 16)

						Text(project.name)
							.font(.subheadline)
							.foregroundStyle(.primary)

						Spacer()

						if selectedProject?.id == project.id {
							Image(systemName: "checkmark")
								.font(.caption)
								.foregroundStyle(.secondary)
						}
					}
					.padding(.horizontal, 10)
					.padding(.vertical, 8)
					.background(
						RoundedRectangle(cornerRadius: 6)
							.fill(selectedIndex == index ? Color.accentColor.opacity(0.1) : Color.clear)
					)
				}
				.buttonStyle(.plain)
				.onHover { isHovering in
					if isHovering {
						selectedIndex = index
					}
				}
			}
		}
		.padding(8)
		.frame(width: 200)
		.focusable()
		.focused($isFocused)
		.focusEffectDisabled()
		.onAppear {
			if let currentProject = selectedProject,
			   let index = projects.firstIndex(where: { $0.id == currentProject.id }) {
				selectedIndex = index
			} else if selectedProject == nil {
				selectedIndex = -1
			}
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
				isFocused = true
			}
		}
		.onKeyPress(.upArrow) {
			selectedIndex = selectedIndex > -1 ? selectedIndex - 1 : projects.count - 1
			return .handled
		}
		.onKeyPress(.downArrow) {
			selectedIndex = selectedIndex < projects.count - 1 ? selectedIndex + 1 : -1
			return .handled
		}
		.onKeyPress(.return) {
			if selectedIndex == -1 {
				selectedProject = nil
			} else if selectedIndex < projects.count {
				selectedProject = projects[selectedIndex]
			}
			onDismiss()
			return .handled
		}
		.onKeyPress(.escape) {
			onDismiss()
			return .handled
		}
	}
}

// MARK: - Tags Picker Popover

struct TagsPickerPopover: View {
	@Binding var selectedTags: Set<UUID>
	let tags: [Tag]
	let onDismiss: () -> Void

	@State private var selectedIndex: Int = 0
	@FocusState private var isFocused: Bool

	var body: some View {
		VStack(spacing: 12) {
			if tags.isEmpty {
				Text("No tags available")
					.font(.subheadline)
					.foregroundStyle(.secondary)
					.padding()
			} else {
				ScrollView {
					VStack(spacing: 4) {
						ForEach(Array(tags.enumerated()), id: \.element.id) { index, tag in
							Button(action: {
								toggleTag(tag.id)
							}) {
								HStack(spacing: 12) {
									Image(systemName: tag.icon ?? "tag.fill")
										.font(.system(size: 14))
										.foregroundStyle(Color(hex: tag.color) ?? .blue)
										.frame(width: 16)

									Text(tag.name)
										.font(.subheadline)
										.foregroundStyle(.primary)

									Spacer()

									if selectedTags.contains(tag.id) {
										Image(systemName: "checkmark.circle.fill")
											.font(.caption)
											.foregroundStyle(Color.accentColor)
									} else {
										Image(systemName: "circle")
											.font(.caption)
											.foregroundStyle(.secondary)
									}
								}
								.padding(.horizontal, 10)
								.padding(.vertical, 8)
								.background(
									RoundedRectangle(cornerRadius: 6)
										.fill(selectedIndex == index ? Color.accentColor.opacity(0.1) : Color.clear)
								)
							}
							.buttonStyle(.plain)
							.onHover { isHovering in
								if isHovering {
									selectedIndex = index
								}
							}
						}
					}
				}
				.frame(maxHeight: 200)
			}

			Divider()

			HStack {
				Button("Clear All") {
					selectedTags.removeAll()
				}
				.buttonStyle(.plain)
				.disabled(selectedTags.isEmpty)

				Spacer()

				Button("Done") {
					onDismiss()
				}
				.buttonStyle(.borderedProminent)
				.keyboardShortcut(.defaultAction)
			}
			.padding(.horizontal, 12)
		}
		.padding(.vertical, 12)
		.frame(width: 220)
		.focusable()
		.focused($isFocused)
		.focusEffectDisabled()
		.onAppear {
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
				isFocused = true
			}
		}
		.onKeyPress(.upArrow) {
			guard !tags.isEmpty else { return .ignored }
			selectedIndex = selectedIndex > 0 ? selectedIndex - 1 : tags.count - 1
			return .handled
		}
		.onKeyPress(.downArrow) {
			guard !tags.isEmpty else { return .ignored }
			selectedIndex = selectedIndex < tags.count - 1 ? selectedIndex + 1 : 0
			return .handled
		}
		.onKeyPress(.return) {
			guard selectedIndex < tags.count else { return .ignored }
			toggleTag(tags[selectedIndex].id)
			return .handled
		}
		.onKeyPress(.space) {
			guard selectedIndex < tags.count else { return .ignored }
			toggleTag(tags[selectedIndex].id)
			return .handled
		}
		.onKeyPress(.escape) {
			onDismiss()
			return .handled
		}
	}

	private func toggleTag(_ tagId: UUID) {
		if selectedTags.contains(tagId) {
			selectedTags.remove(tagId)
		} else {
			selectedTags.insert(tagId)
		}
	}
}

#Preview {
	CreateIssueSheet(defaultStatus: .todo, project: nil)
		.modelContainer(for: [Project.self, Issue.self, Tag.self], inMemory: true)
}
