//
//  CreateSpaceSheet.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/12/25.
//

import SwiftUI
import SwiftData

struct CreateSpaceSheet: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(\.modelContext) private var modelContext

	@State private var name: String = ""
	@State private var description: String = ""
	@State private var selectedIcon: String = "person.3.fill"
	@State private var selectedColor: AppColor = .blue
	@FocusState private var focusedField: Field?

	enum Field: Hashable {
		case name
		case description
	}

	// Common space icons
	private let commonIcons = [
		"person.3.fill", "person.2.fill", "person.fill",
		"figure.2", "figure.walk", "figure.wave",
		"person.crop.circle.fill", "person.crop.square.fill",
		"hand.raised.fill", "hand.thumbsup.fill", "hands.sparkles.fill",
		"heart.fill", "star.fill", "flag.fill",
		"shield.fill", "crown.fill", "medal.fill"
	]

	// Use AppColor enum for consistent colors
	private let presetColors = AppColor.allCases

	var body: some View {
		NavigationStack {
			Form {
				Section {
					TextField("Space Name", text: $name, axis: .vertical)
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
			}
			.formStyle(.grouped)
			.navigationTitle("New Space")
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Cancel") {
						dismiss()
					}
					.keyboardShortcut(.cancelAction)
				}

				ToolbarItem(placement: .confirmationAction) {
					Button("Create") {
						createSpace()
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

	private func createSpace() {
		let newSpace = Space(
			name: name.trimmingCharacters(in: .whitespacesAndNewlines),
			spaceDescription: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
			icon: selectedIcon,
			color: selectedColor.hexString
		)

		modelContext.insert(newSpace)

		dismiss()
	}
}

#Preview {
	CreateSpaceSheet()
		.modelContainer(for: [Space.self], inMemory: true)
}
