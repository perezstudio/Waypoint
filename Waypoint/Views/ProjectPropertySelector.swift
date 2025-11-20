//
//  ProjectPropertySelector.swift
//  Waypoint
//
//  Project selector with hover effects and popover
//

import SwiftUI
import SwiftData

struct ProjectPropertySelector: View {
	let icon: String
	let label: String
	let project: Project?
	let onSelect: (Project?) -> Void

	@Query private var projects: [Project]
	@State private var isHovering: Bool = false
	@State private var showPopover: Bool = false

	private var borderColor: Color {
		if showPopover {
			return .accentColor.opacity(0.5)
		} else if isHovering {
			return .primary.opacity(0.2)
		} else {
			return .clear
		}
	}

	private var displayValue: String {
		project?.name ?? "None"
	}

	var body: some View {
		Button(action: {
			showPopover = true
		}) {
			HStack(spacing: 8) {
				// Icon
				Image(systemName: icon)
					.font(.subheadline)
					.foregroundStyle(.secondary)
					.frame(width: 16)

				// Label
				Text(label)
					.font(.subheadline)
					.foregroundStyle(.secondary)

				Spacer()

				// Value
				Text(displayValue)
					.font(.subheadline)
					.fontWeight(.medium)
					.foregroundStyle(project == nil ? .secondary : .primary)
			}
			.padding(.horizontal, 8)
			.padding(.vertical, 6)
			.contentShape(Rectangle())
			.background(
				RoundedRectangle(cornerRadius: 6)
					.strokeBorder(borderColor, lineWidth: 1)
			)
		}
		.buttonStyle(.plain)
		.onHover { hovering in
			isHovering = hovering
		}
		.popover(isPresented: $showPopover, arrowEdge: .trailing) {
			ProjectPopoverContent(
				projects: projects,
				selectedProject: project,
				onSelect: { newProject in
					onSelect(newProject)
				}
			)
		}
	}
}

struct ProjectPopoverContent: View {
	let projects: [Project]
	let selectedProject: Project?
	let onSelect: (Project?) -> Void

	@Environment(\.dismiss) private var dismiss
	@State private var hoveredIndex: Int? = nil
	@FocusState private var isFocused: Bool

	private var sortedProjects: [Project] {
		projects.sorted { $0.name < $1.name }
	}

	var body: some View {
		VStack(spacing: 2) {
			// None option
			Button(action: {
				onSelect(nil)
				dismiss()
			}) {
				HStack(spacing: 8) {
					Text("0")
						.font(.caption)
						.foregroundStyle(.secondary)
						.frame(width: 16, alignment: .trailing)

					Image(systemName: "xmark.circle")
						.font(.subheadline)
						.foregroundStyle(.secondary)
						.frame(width: 16)

					Text("None")
						.font(.subheadline)
						.foregroundStyle(.secondary)

					Spacer()

					if selectedProject == nil {
						Image(systemName: "checkmark")
							.font(.caption)
							.foregroundStyle(Color.accentColor)
					}
				}
				.padding(.horizontal, 10)
				.padding(.vertical, 6)
				.contentShape(Rectangle())
				.background(
					RoundedRectangle(cornerRadius: 4)
						.fill(hoveredIndex == -1 ? Color.accentColor.opacity(0.1) : Color.clear)
				)
			}
			.buttonStyle(.plain)
			.onHover { hovering in
				hoveredIndex = hovering ? -1 : nil
			}

			// Project options
			ForEach(Array(sortedProjects.enumerated()), id: \.element.id) { index, project in
				Button(action: {
					onSelect(project)
					dismiss()
				}) {
					HStack(spacing: 8) {
						Text("\(index + 1)")
							.font(.caption)
							.foregroundStyle(.secondary)
							.frame(width: 16, alignment: .trailing)

						Image(systemName: project.icon)
							.font(.subheadline)
							.foregroundStyle(Color(hex: project.color) ?? .accentColor)
							.frame(width: 16)

						Text(project.name)
							.font(.subheadline)

						Spacer()

						if selectedProject?.id == project.id {
							Image(systemName: "checkmark")
								.font(.caption)
								.foregroundStyle(Color.accentColor)
						}
					}
					.padding(.horizontal, 10)
					.padding(.vertical, 6)
					.contentShape(Rectangle())
					.background(
						RoundedRectangle(cornerRadius: 4)
							.fill(hoveredIndex == index ? Color.accentColor.opacity(0.1) : Color.clear)
					)
				}
				.buttonStyle(.plain)
				.onHover { hovering in
					hoveredIndex = hovering ? index : nil
				}
			}
		}
		.padding(6)
		.frame(minWidth: 200, maxHeight: 400)
		.focusable()
		.focused($isFocused)
		.focusEffectDisabled()
		.onAppear {
			isFocused = true
		}
		.onKeyPress(.escape) {
			dismiss()
			return .handled
		}
		.onKeyPress(.return) {
			if let hoveredIndex = hoveredIndex {
				if hoveredIndex == -1 {
					onSelect(nil)
				} else if hoveredIndex < sortedProjects.count {
					onSelect(sortedProjects[hoveredIndex])
				}
				dismiss()
			}
			return .handled
		}
		.onKeyPress(.upArrow) {
			if let current = hoveredIndex {
				hoveredIndex = max(-1, current - 1)
			} else {
				hoveredIndex = sortedProjects.count - 1
			}
			return .handled
		}
		.onKeyPress(.downArrow) {
			if let current = hoveredIndex {
				hoveredIndex = min(sortedProjects.count - 1, current + 1)
			} else {
				hoveredIndex = -1
			}
			return .handled
		}
		.onKeyPress(characters: .decimalDigits) { press in
			switch press.characters {
			case "0":
				onSelect(nil)
				dismiss()
			case "1": selectProject(at: 0)
			case "2": selectProject(at: 1)
			case "3": selectProject(at: 2)
			case "4": selectProject(at: 3)
			case "5": selectProject(at: 4)
			case "6": selectProject(at: 5)
			case "7": selectProject(at: 6)
			case "8": selectProject(at: 7)
			case "9": selectProject(at: 8)
			default: return .ignored
			}
			return .handled
		}
	}

	private func selectProject(at index: Int) {
		guard index < sortedProjects.count else { return }
		onSelect(sortedProjects[index])
		dismiss()
	}
}
