//
//  ProjectSheets.swift
//  Waypoint
//
//  Created by Claude on 11/14/25.
//

import SwiftUI
import SwiftData

// MARK: - Add Resource Sheet

struct AddResourceSheet: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(\.modelContext) private var modelContext

	let project: Project

	@State private var title = ""
	@State private var url = ""
	@State private var type: ResourceType = .link

	var body: some View {
		VStack(spacing: 0) {
			// Header
			HStack {
				Text("Add Resource")
					.font(.headline)
				Spacer()
				Button("Cancel") {
					dismiss()
				}
				.keyboardShortcut(.escape, modifiers: [])
			}
			.padding()

			Divider()

			// Form
			Form {
				Section {
					TextField("Title", text: $title)
					TextField("URL", text: $url)
					Picker("Type", selection: $type) {
						ForEach([ResourceType.link, ResourceType.file], id: \.self) { type in
							Text(type.rawValue).tag(type)
						}
					}
					.pickerStyle(.segmented)
				}
			}
			.formStyle(.grouped)
			.scrollContentBackground(.hidden)

			Divider()

			// Footer
			HStack {
				Spacer()
				Button("Add Resource") {
					addResource()
				}
				.buttonStyle(.borderedProminent)
				.disabled(title.isEmpty || url.isEmpty)
				.keyboardShortcut(.return, modifiers: .command)
			}
			.padding()
		}
		.frame(width: 400, height: 280)
	}

	private func addResource() {
		let resource = Resource(title: title, url: url, type: type, project: project)
		modelContext.insert(resource)
		try? modelContext.save()
		dismiss()
	}
}

// MARK: - Add Update Sheet

struct AddUpdateSheet: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(\.modelContext) private var modelContext

	let project: Project

	@State private var content = ""
	@State private var author = ""

	var body: some View {
		VStack(spacing: 0) {
			// Header
			HStack {
				Text("Add Update")
					.font(.headline)
				Spacer()
				Button("Cancel") {
					dismiss()
				}
				.keyboardShortcut(.escape, modifiers: [])
			}
			.padding()

			Divider()

			// Form
			Form {
				Section {
					TextField("Author (optional)", text: $author)

					VStack(alignment: .leading, spacing: 8) {
						Text("Content")
							.font(.caption)
							.foregroundStyle(.secondary)
						TextEditor(text: $content)
							.font(.body)
							.frame(height: 150)
							.overlay(
								RoundedRectangle(cornerRadius: 6)
									.stroke(Color.gray.opacity(0.2), lineWidth: 1)
							)
					}
				}
			}
			.formStyle(.grouped)
			.scrollContentBackground(.hidden)

			Divider()

			// Footer
			HStack {
				Spacer()
				Button("Add Update") {
					addUpdate()
				}
				.buttonStyle(.borderedProminent)
				.disabled(content.isEmpty)
				.keyboardShortcut(.return, modifiers: .command)
			}
			.padding()
		}
		.frame(width: 500, height: 350)
	}

	private func addUpdate() {
		let update = ProjectUpdate(
			content: content,
			author: author.isEmpty ? nil : author,
			project: project
		)
		modelContext.insert(update)
		try? modelContext.save()
		dismiss()
	}
}

// MARK: - Add Milestone Sheet

struct AddMilestoneSheet: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(\.modelContext) private var modelContext

	let project: Project

	@State private var title = ""
	@State private var description = ""
	@State private var hasDueDate = false
	@State private var dueDate = Date()

	var body: some View {
		VStack(spacing: 0) {
			// Header
			HStack {
				Text("Add Milestone")
					.font(.headline)
				Spacer()
				Button("Cancel") {
					dismiss()
				}
				.keyboardShortcut(.escape, modifiers: [])
			}
			.padding()

			Divider()

			// Form
			Form {
				Section {
					TextField("Title", text: $title)

					VStack(alignment: .leading, spacing: 8) {
						Text("Description (optional)")
							.font(.caption)
							.foregroundStyle(.secondary)
						TextEditor(text: $description)
							.font(.body)
							.frame(height: 80)
							.overlay(
								RoundedRectangle(cornerRadius: 6)
									.stroke(Color.gray.opacity(0.2), lineWidth: 1)
							)
					}

					Toggle("Set due date", isOn: $hasDueDate)

					if hasDueDate {
						DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
					}
				}
			}
			.formStyle(.grouped)
			.scrollContentBackground(.hidden)

			Divider()

			// Footer
			HStack {
				Spacer()
				Button("Add Milestone") {
					addMilestone()
				}
				.buttonStyle(.borderedProminent)
				.disabled(title.isEmpty)
				.keyboardShortcut(.return, modifiers: .command)
			}
			.padding()
		}
		.frame(width: 500, height: 400)
	}

	private func addMilestone() {
		// Get next order number
		let maxOrder = project.milestones.map { $0.order }.max() ?? -1
		let newOrder = maxOrder + 1

		let milestone = Milestone(
			title: title,
			description: description.isEmpty ? nil : description,
			dueDate: hasDueDate ? dueDate : nil,
			order: newOrder,
			project: project
		)
		modelContext.insert(milestone)
		try? modelContext.save()
		dismiss()
	}
}
