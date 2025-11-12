//
//  CreateLabelSheet.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/12/25.
//

import SwiftUI
import SwiftData

struct CreateLabelSheet: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(\.modelContext) private var modelContext

	@State private var name: String = ""
	@State private var selectedIcon: String? = nil
	@State private var selectedColor: String = "#007AFF"
	@FocusState private var focusedField: Field?

	enum Field: Hashable {
		case name
	}

	// Common label icons
	private let commonIcons: [String?] = [
		nil, // No icon option
		"tag", "tag.fill", "bookmark", "bookmark.fill",
		"star", "star.fill", "flag", "flag.fill",
		"circle", "circle.fill", "square", "square.fill",
		"heart", "heart.fill", "exclamationmark", "exclamationmark.circle.fill"
	]

	// Preset colors
	private let presetColors = [
		"#FF3B30", "#FF9500", "#FFCC00", "#34C759",
		"#00C7BE", "#32ADE6", "#007AFF", "#5856D6",
		"#AF52DE", "#FF2D55", "#A2845E", "#8E8E93"
	]

	var body: some View {
		NavigationStack {
			Form {
				Section {
					TextField("Label Name", text: $name, axis: .vertical)
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
						ForEach(presetColors, id: \.self) { colorHex in
							Button(action: { selectedColor = colorHex }) {
								RoundedRectangle(cornerRadius: 8)
									.fill(Color(hex: colorHex) ?? .blue)
									.frame(width: 44, height: 44)
									.overlay(
										RoundedRectangle(cornerRadius: 8)
											.strokeBorder(
												selectedColor == colorHex ? Color.primary : Color.clear,
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

				// Preview
				Section("Preview") {
					HStack(spacing: 8) {
						if let icon = selectedIcon {
							Image(systemName: icon)
								.font(.caption)
								.foregroundStyle(Color(hex: selectedColor) ?? .blue)
						}

						Text(name.isEmpty ? "Label Name" : name)
							.font(.caption)
							.foregroundStyle(.primary)

						Spacer()
					}
					.padding(.horizontal, 10)
					.padding(.vertical, 6)
					.background(Color(hex: selectedColor)?.opacity(0.15) ?? .blue.opacity(0.15))
					.clipShape(RoundedRectangle(cornerRadius: 6))
				}
			}
			.formStyle(.grouped)
			.navigationTitle("New Label")
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Cancel") {
						dismiss()
					}
					.keyboardShortcut(.cancelAction)
				}

				ToolbarItem(placement: .confirmationAction) {
					Button("Create") {
						createLabel()
					}
					.keyboardShortcut(.defaultAction)
					.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
				}
			}
			.onAppear {
				focusedField = .name
			}
		}
		.frame(width: 500, height: 550)
	}

	private func createLabel() {
		let newLabel = Label(
			name: name.trimmingCharacters(in: .whitespacesAndNewlines),
			color: selectedColor,
			icon: selectedIcon
		)

		modelContext.insert(newLabel)

		dismiss()
	}
}

#Preview {
	CreateLabelSheet()
		.modelContainer(for: [Label.self], inMemory: true)
}
