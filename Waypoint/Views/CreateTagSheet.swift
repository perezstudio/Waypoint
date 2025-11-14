//
//  CreateTagSheet.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/12/25.
//

import SwiftUI
import SwiftData

struct CreateTagSheet: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(\.modelContext) private var modelContext
	@Query private var spaces: [Space]

	let preselectedSpace: Space?

	@State private var name: String = ""
	@State private var selectedIcon: String? = nil
	@State private var selectedColor: AppColor = .blue
	@State private var selectedSpace: Space?
	@FocusState private var focusedField: Field?

	enum Field: Hashable {
		case name
	}

	init(preselectedSpace: Space? = nil) {
		self.preselectedSpace = preselectedSpace
		_selectedSpace = State(initialValue: preselectedSpace)
	}

	// Common tag icons
	private let commonIcons: [String?] = [
		nil, // No icon option
		"tag", "tag.fill", "bookmark", "bookmark.fill",
		"star", "star.fill", "flag", "flag.fill",
		"circle", "circle.fill", "square", "square.fill",
		"heart", "heart.fill", "exclamationmark", "exclamationmark.circle.fill"
	]

	// Use AppColor enum for consistent colors
	private let presetColors = AppColor.allCases

	var body: some View {
		NavigationStack {
			Form {
				Section {
					TextField("Tag Name", text: $name, axis: .vertical)
						.textFieldStyle(.plain)
						.font(.title3)
						.fontWeight(.semibold)
						.focused($focusedField, equals: .name)
						.lineLimit(2)
				}

				Section("Color") {
					LazyVGrid(columns: [
						GridItem(.adaptive(minimum: 44), spacing: 8)
					], spacing: 8) {
						ForEach(presetColors, id: \.self) { appColor in
							Button(action: { selectedColor = appColor }) {
								RoundedRectangle(cornerRadius: 8)
									.fill(appColor.color)
									.frame(width: 44, height: 44)
									.overlay(
										RoundedRectangle(cornerRadius: 8)
											.strokeBorder(
												selectedColor == appColor ? Color.primary : Color.clear,
												lineWidth: 3
											)
									)
							}
							.buttonStyle(.plain)
						}
					}
				}

				Section("Icon (Optional)") {
					LazyVGrid(columns: [
						GridItem(.adaptive(minimum: 44), spacing: 8)
					], spacing: 8) {
						ForEach(Array(commonIcons.enumerated()), id: \.offset) { _, icon in
							Button(action: { selectedIcon = icon }) {
								Group {
									if let icon = icon {
										Image(systemName: icon)
											.font(.title3)
											.foregroundStyle(selectedIcon == icon ? .white : .primary)
									} else {
										Image(systemName: "slash.circle")
											.font(.title3)
											.foregroundStyle(selectedIcon == icon ? .white : .secondary)
									}
								}
								.frame(width: 44, height: 44)
								.background(
									RoundedRectangle(cornerRadius: 8)
										.fill(selectedIcon == icon ? Color.accentColor : Color.secondary.opacity(0.1))
								)
							}
							.buttonStyle(.plain)
						}
					}
				}

				Section("Space") {
					if spaces.isEmpty {
						Text("No spaces available. Create a space first.")
							.font(.caption)
							.foregroundStyle(.secondary)
					} else {
						Picker("Space", selection: $selectedSpace) {
							Text("Select a space").tag(nil as Space?)
							ForEach(spaces) { space in
								HStack {
									Image(systemName: space.icon)
										.foregroundStyle(Color(hex: space.color) ?? .blue)
									Text(space.name)
								}
								.tag(space as Space?)
							}
						}
					}
				}

				// Preview
				Section("Preview") {
					HStack(spacing: 8) {
						if let icon = selectedIcon {
							Image(systemName: icon)
								.font(.caption)
								.foregroundStyle(selectedColor.color)
						}

						Text(name.isEmpty ? "Tag Name" : name)
							.font(.caption)
							.foregroundStyle(.primary)

						Spacer()
					}
					.padding(.horizontal, 10)
					.padding(.vertical, 6)
					.background(selectedColor.color.opacity(0.15))
					.clipShape(RoundedRectangle(cornerRadius: 6))
				}
			}
			.formStyle(.grouped)
			.navigationTitle("New Tag")
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Cancel") {
						dismiss()
					}
					.keyboardShortcut(.cancelAction)
				}

				ToolbarItem(placement: .confirmationAction) {
					Button("Create") {
						createTag()
					}
					.keyboardShortcut(.defaultAction)
					.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedSpace == nil)
				}
			}
			.onAppear {
				focusedField = .name
			}
		}
		.frame(width: 500, height: 550)
	}

	private func createTag() {
		let newTag = Tag(
			name: name.trimmingCharacters(in: .whitespacesAndNewlines),
			color: selectedColor.hexString,
			icon: selectedIcon,
			space: selectedSpace
		)

		modelContext.insert(newTag)

		dismiss()
	}
}

#Preview {
	CreateTagSheet(preselectedSpace: nil)
		.modelContainer(for: [Tag.self, Space.self], inMemory: true)
}
