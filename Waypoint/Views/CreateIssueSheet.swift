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

	let defaultStatus: IssueStatus
	let project: Project?

	@State private var title: String = ""
	@State private var description: String = ""
	@State private var status: IssueStatus
	@State private var priority: IssuePriority = .medium
	@State private var dueDate: Date = Date()
	@State private var hasDueDate: Bool = false
	@State private var selectedProject: Project?
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
		NavigationStack {
			Form {
				Section {
					TextField("Issue Title", text: $title, axis: .vertical)
						.textFieldStyle(.plain)
						.font(.title3)
						.fontWeight(.semibold)
						.focused($focusedField, equals: .title)
						.lineLimit(3)
				}

				Section("Description") {
					TextField("Add a description...", text: $description, axis: .vertical)
						.textFieldStyle(.plain)
						.focused($focusedField, equals: .description)
						.lineLimit(5...10)
				}

				Section("Properties") {
					// Status picker
					Picker("Status", selection: $status) {
						ForEach([IssueStatus.todo, .inProgress, .review, .done], id: \.self) { status in
							HStack {
								Circle()
									.fill(statusColor(for: status))
									.frame(width: 8, height: 8)
								Text(statusLabel(for: status))
							}
							.tag(status)
						}
					}

					// Priority picker
					Picker("Priority", selection: $priority) {
						ForEach([IssuePriority.low, .medium, .high, .urgent], id: \.self) { priority in
							HStack {
								Image(systemName: priorityIcon(for: priority))
									.foregroundStyle(priorityColor(for: priority))
								Text(priority.rawValue.capitalized)
							}
							.tag(priority)
						}
					}

					// Due date toggle and picker
					Toggle("Due Date", isOn: $hasDueDate)

					if hasDueDate {
						DatePicker("", selection: $dueDate, displayedComponents: .date)
							.datePickerStyle(.graphical)
					}
				}

				Section("Project") {
					if project != nil {
						// Show read-only project
						HStack {
							Image(systemName: project!.icon)
								.foregroundStyle(.secondary)
							Text(project!.name)
						}
					} else {
						// Show project picker
						Picker("Project", selection: $selectedProject) {
							Text("None").tag(nil as Project?)
							ForEach(projects) { proj in
								HStack {
									Image(systemName: proj.icon)
										.foregroundStyle(Color(hex: proj.color) ?? .blue)
									Text(proj.name)
								}
								.tag(proj as Project?)
							}
						}
					}
				}
			}
			.formStyle(.grouped)
			.navigationTitle("New Issue")
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Cancel") {
						dismiss()
					}
					.keyboardShortcut(.cancelAction)
				}

				ToolbarItem(placement: .confirmationAction) {
					Button("Create") {
						createIssue()
					}
					.keyboardShortcut(.defaultAction)
					.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
				}
			}
			.onAppear {
				focusedField = .title
			}
		}
		.frame(width: 500, height: 600)
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

		modelContext.insert(newIssue)

		dismiss()
	}

	// Helper functions for styling
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

#Preview {
	CreateIssueSheet(defaultStatus: .todo, project: nil)
		.modelContainer(for: [Project.self, Issue.self], inMemory: true)
}
