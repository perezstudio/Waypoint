//
//  InspectorView.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/11/25.
//

import SwiftUI
import SwiftData

struct InspectorView: View {
	@Binding var isVisible: Bool
	@Environment(ProjectStore.self) private var projectStore

	private var priorityColor: Color {
		guard let issue = projectStore.selectedIssue else { return .gray }
		switch issue.priority {
		case .urgent: return .red
		case .high: return .orange
		case .medium: return .blue
		case .low: return .gray
		}
	}

	private var statusText: String {
		guard let issue = projectStore.selectedIssue else { return "-" }
		switch issue.status {
		case .todo: return "To Do"
		case .inProgress: return "In Progress"
		case .review: return "Review"
		case .done: return "Done"
		}
	}

	private var priorityText: String {
		guard let issue = projectStore.selectedIssue else { return "-" }
		switch issue.priority {
		case .urgent: return "Urgent"
		case .high: return "High"
		case .medium: return "Medium"
		case .low: return "Low"
		}
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 0) {
			// Inspector header
			HStack(alignment: .center) {
				Text("Inspector")
					.font(.title2)
					.fontWeight(.semibold)

				Spacer()

				// Close button - only show when inspector has content or is visible
				IconButton(
					icon: "xmark",
					action: {
						withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
							isVisible = false
						}
					},
					tooltip: "Close Inspector"
				)
				.transition(.asymmetric(
					insertion: .move(edge: .trailing).combined(with: .opacity),
					removal: .move(edge: .trailing).combined(with: .opacity)
				))
			}
			.padding(.horizontal, 20)
			.padding(.vertical, 16)
			.frame(maxHeight: 60)
			.clipped()

			Divider()

			// Inspector content
			if let issue = projectStore.selectedIssue {
				ScrollView {
					VStack(alignment: .leading, spacing: 20) {
						// Issue title
						VStack(alignment: .leading, spacing: 8) {
							Text("Title")
								.font(.caption)
								.foregroundStyle(.secondary)
								.textCase(.uppercase)

							Text(issue.title)
								.font(.headline)
						}

						Divider()

						// Properties section
						VStack(alignment: .leading, spacing: 12) {
							Text("Properties")
								.font(.caption)
								.foregroundStyle(.secondary)
								.textCase(.uppercase)

							VStack(alignment: .leading, spacing: 8) {
								PropertyRow(label: "Status", value: statusText)
								PropertyRow(label: "Priority", value: priorityText, valueColor: priorityColor)
								if let dueDate = issue.dueDate {
									PropertyRow(label: "Due Date", value: dueDate.formatted(date: .long, time: .omitted))
								}
								if let project = issue.project {
									PropertyRow(label: "Project", value: project.name)
								}
							}
						}

						Divider()

						// Description section
						if let description = issue.issueDescription, !description.isEmpty {
							VStack(alignment: .leading, spacing: 12) {
								Text("Description")
									.font(.caption)
									.foregroundStyle(.secondary)
									.textCase(.uppercase)

								Text(description)
									.font(.subheadline)
									.foregroundStyle(.primary)
							}

							Divider()
						}

						// Timestamps section
						VStack(alignment: .leading, spacing: 12) {
							Text("Timestamps")
								.font(.caption)
								.foregroundStyle(.secondary)
								.textCase(.uppercase)

							VStack(alignment: .leading, spacing: 8) {
								PropertyRow(label: "Created", value: issue.createdAt.formatted(date: .abbreviated, time: .shortened))
								PropertyRow(label: "Updated", value: issue.updatedAt.formatted(date: .abbreviated, time: .shortened))
							}
						}

						Spacer()
					}
					.padding(16)
				}
			} else {
				// Empty state when no issue is selected
				VStack(spacing: 16) {
					Image(systemName: "doc.text")
						.font(.system(size: 48))
						.foregroundStyle(.secondary)

					Text("No Selection")
						.font(.headline)
						.foregroundStyle(.primary)

					Text("Select an issue to view its details")
						.font(.subheadline)
						.foregroundStyle(.secondary)
						.multilineTextAlignment(.center)
				}
				.frame(maxWidth: .infinity, maxHeight: .infinity)
				.padding(40)
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
}

// Property row component
struct PropertyRow: View {
	let label: String
	let value: String
	var valueColor: Color?

	var body: some View {
		HStack {
			Text(label)
				.font(.subheadline)
				.foregroundStyle(.secondary)

			Spacer()

			Text(value)
				.font(.subheadline)
				.fontWeight(.medium)
				.foregroundStyle(valueColor ?? .primary)
		}
		.padding(.vertical, 4)
	}
}

#Preview {
	InspectorView(isVisible: .constant(true))
		.environment(ProjectStore())
		.frame(width: 280, height: 600)
}
