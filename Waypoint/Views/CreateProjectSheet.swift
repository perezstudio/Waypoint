//
//  CreateProjectSheet.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/12/25.
//

import SwiftUI
import SwiftData

struct CreateProjectSheet: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(\.modelContext) private var modelContext
	@Query private var teams: [Team]

	@State private var name: String = ""
	@State private var description: String = ""
	@State private var selectedIcon: String = "folder.fill"
	@State private var selectedColor: String = "#007AFF"
	@State private var selectedTeam: Team?
	@FocusState private var focusedField: Field?

	enum Field: Hashable {
		case name
		case description
	}

	// Common project icons
	private let commonIcons = [
		"folder.fill", "star.fill", "heart.fill", "flag.fill",
		"bolt.fill", "lightbulb.fill", "gear", "hammer.fill",
		"wrench.fill", "paintbrush.fill", "photo.fill", "video.fill",
		"music.note", "book.fill", "graduationcap.fill", "briefcase.fill",
		"cart.fill", "creditcard.fill", "chart.bar.fill", "graph.fill",
		"safari.fill", "iphone", "laptopcomputer", "desktopcomputer"
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
					TextField("Project Name", text: $name, axis: .vertical)
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

				if !teams.isEmpty {
					Section("Team") {
						Picker("Team", selection: $selectedTeam) {
							Text("None").tag(nil as Team?)
							ForEach(teams) { team in
								HStack {
									Image(systemName: team.icon)
										.foregroundStyle(Color(hex: team.color) ?? .blue)
									Text(team.name)
								}
								.tag(team as Team?)
							}
						}
					}
				}
			}
			.formStyle(.grouped)
			.navigationTitle("New Project")
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Cancel") {
						dismiss()
					}
					.keyboardShortcut(.cancelAction)
				}

				ToolbarItem(placement: .confirmationAction) {
					Button("Create") {
						createProject()
					}
					.keyboardShortcut(.defaultAction)
					.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
				}
			}
			.onAppear {
				focusedField = .name
			}
		}
		.frame(width: 500, height: 650)
	}

	private func createProject() {
		let newProject = Project(
			name: name.trimmingCharacters(in: .whitespacesAndNewlines),
			icon: selectedIcon,
			color: selectedColor,
			team: selectedTeam
		)

		if !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
			// Note: Project model doesn't have description field yet, this is future-proofing
		}

		modelContext.insert(newProject)

		dismiss()
	}
}

// Helper extension for hex colors
extension Color {
	init?(hex: String) {
		let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
		guard hex.count == 6 else { return nil }

		var rgb: UInt64 = 0
		Scanner(string: hex).scanHexInt64(&rgb)

		let r = Double((rgb & 0xFF0000) >> 16) / 255.0
		let g = Double((rgb & 0x00FF00) >> 8) / 255.0
		let b = Double(rgb & 0x0000FF) / 255.0

		self.init(red: r, green: g, blue: b)
	}
}

#Preview {
	CreateProjectSheet()
		.modelContainer(for: [Project.self, Team.self], inMemory: true)
}
