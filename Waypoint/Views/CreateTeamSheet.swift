//
//  CreateTeamSheet.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/12/25.
//

import SwiftUI
import SwiftData

struct CreateTeamSheet: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(\.modelContext) private var modelContext

	@State private var name: String = ""
	@State private var description: String = ""
	@State private var selectedIcon: String = "person.3.fill"
	@State private var selectedColor: String = "#007AFF"
	@FocusState private var focusedField: Field?

	enum Field: Hashable {
		case name
		case description
	}

	// Common team icons
	private let commonIcons = [
		"person.3.fill", "person.2.fill", "person.fill",
		"figure.2", "figure.walk", "figure.wave",
		"person.crop.circle.fill", "person.crop.square.fill",
		"hand.raised.fill", "hand.thumbsup.fill", "hands.sparkles.fill",
		"heart.fill", "star.fill", "flag.fill",
		"shield.fill", "crown.fill", "medal.fill"
	]

	// Preset colors
	private let presetColors = [
		"#007AFF", "#FF9500", "#FF2D55", "#AF52DE",
		"#5856D6", "#32ADE6", "#00C7BE", "#34C759",
		"#FF3B30", "#FF9500", "#FFCC00", "#8E8E93"
	]

	var body: some View {
		NavigationStack {
			Form {
				Section {
					TextField("Team Name", text: $name, axis: .vertical)
						.textFieldStyle(.plain)
						.font(.title3)
						.fontWeight(.semibold)
						.focused($focusedField, equals: .name)
						.lineLimit(2)
				}

				Section("Description") {
					TextField("Add a description...", text: $description, axis: .vertical)
						.textFieldStyle(.plain)
						.focused($focusedField, equals: .description)
						.lineLimit(3...6)
				}

				Section("Icon") {
					LazyVGrid(columns: [
						GridItem(.adaptive(minimum: 44), spacing: 8)
					], spacing: 8) {
						ForEach(commonIcons, id: \.self) { icon in
							Button(action: { selectedIcon = icon }) {
								Image(systemName: icon)
									.font(.title3)
									.foregroundStyle(selectedIcon == icon ? .white : .primary)
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
			}
			.formStyle(.grouped)
			.navigationTitle("New Team")
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Cancel") {
						dismiss()
					}
					.keyboardShortcut(.cancelAction)
				}

				ToolbarItem(placement: .confirmationAction) {
					Button("Create") {
						createTeam()
					}
					.keyboardShortcut(.defaultAction)
					.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
				}
			}
			.onAppear {
				focusedField = .name
			}
		}
		.frame(width: 500, height: 600)
	}

	private func createTeam() {
		let newTeam = Team(
			name: name.trimmingCharacters(in: .whitespacesAndNewlines),
			teamDescription: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
			icon: selectedIcon,
			color: selectedColor
		)

		modelContext.insert(newTeam)

		dismiss()
	}
}

#Preview {
	CreateTeamSheet()
		.modelContainer(for: [Team.self], inMemory: true)
}
