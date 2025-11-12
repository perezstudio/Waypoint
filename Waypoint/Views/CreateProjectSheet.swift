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
	@Query private var spaces: [Space]

	let preselectedSpace: Space?

	@State private var name: String = ""
	@State private var description: String = ""
	@State private var selectedIcon: String = "folder.fill"
	@State private var selectedColor: String = "#007AFF"
	@State private var selectedSpace: Space?
	@State private var highlightedIconIndex: Int = 0
	@State private var highlightedColorIndex: Int = 0
	@State private var showingSpacePicker: Bool = false
	@FocusState private var focusedField: Field?

	enum Field: Hashable {
		case name
		case description
		case iconGrid
		case colorGrid
		case spacePicker
	}

	init(preselectedSpace: Space? = nil) {
		self.preselectedSpace = preselectedSpace
		_selectedSpace = State(initialValue: preselectedSpace)
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
			ScrollViewReader { proxy in
				Form {
					Section {
						TextField("Project Name", text: $name, axis: .vertical)
							.textFieldStyle(.plain)
							.font(.title3)
							.fontWeight(.semibold)
							.focused($focusedField, equals: .name)
							.lineLimit(2)
					}
					.id(Field.name)

					Section("Description") {
						TextField("Add a description...", text: $description, axis: .vertical)
							.textFieldStyle(.plain)
							.focused($focusedField, equals: .description)
							.lineLimit(3...6)
					}
					.id(Field.description)

					iconGridSection
						.id(Field.iconGrid)

					colorGridSection
						.id(Field.colorGrid)

					Section("Space") {
					if spaces.isEmpty {
						Text("No spaces available. Create a space first.")
							.font(.caption)
							.foregroundStyle(.secondary)
					} else {
						CustomSpacePickerButton(
							selectedSpace: $selectedSpace,
							spaces: spaces,
							isFocused: focusedField == .spacePicker,
							showingPopover: $showingSpacePicker
						)
						.focusable()
						.focused($focusedField, equals: .spacePicker)
						.focusEffectDisabled()
						.onKeyPress(.return) {
							if focusedField == .spacePicker {
								showingSpacePicker.toggle()
								return .handled
							}
							return .ignored
						}
						.onKeyPress(.space) {
							if focusedField == .spacePicker {
								showingSpacePicker.toggle()
								return .handled
							}
							return .ignored
						}
					}
				}
				.id(Field.spacePicker)
				}
				.formStyle(.grouped)
				.onChange(of: focusedField) { _, newField in
					if let field = newField {
						withAnimation {
							proxy.scrollTo(field, anchor: .center)
						}
					}
				}
			}
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
					.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedSpace == nil)
				}
			}
			.onAppear {
				focusedField = .name
			}
			.onKeyPress(keys: [.tab]) { press in
				if press.modifiers.contains(.shift) {
					handleTab(isShift: true)
				} else {
					handleTab(isShift: false)
				}
				return .handled
			}
		}
		.frame(width: 500, height: 650)
	}

	// Grid navigation helpers - Linear navigation
	private func navigateIconGrid(direction: GridDirection) {
		let itemsPerRow = 6
		let totalIcons = commonIcons.count

		switch direction {
		case .left:
			// Previous item, wrap to end
			highlightedIconIndex = highlightedIconIndex > 0 ? highlightedIconIndex - 1 : totalIcons - 1
		case .right:
			// Next item, wrap to start
			highlightedIconIndex = highlightedIconIndex < totalIcons - 1 ? highlightedIconIndex + 1 : 0
		case .up:
			// Move up one row (6 items back), clamp at start
			let newIndex = highlightedIconIndex - itemsPerRow
			highlightedIconIndex = max(0, newIndex)
		case .down:
			// Move down one row (6 items forward), clamp at end
			let newIndex = highlightedIconIndex + itemsPerRow
			highlightedIconIndex = min(totalIcons - 1, newIndex)
		}
	}

	private func navigateColorGrid(direction: GridDirection) {
		let itemsPerRow = 6
		let totalColors = presetColors.count

		switch direction {
		case .left:
			// Previous item, wrap to end
			highlightedColorIndex = highlightedColorIndex > 0 ? highlightedColorIndex - 1 : totalColors - 1
		case .right:
			// Next item, wrap to start
			highlightedColorIndex = highlightedColorIndex < totalColors - 1 ? highlightedColorIndex + 1 : 0
		case .up:
			// Move up one row (6 items back), clamp at start
			let newIndex = highlightedColorIndex - itemsPerRow
			highlightedColorIndex = max(0, newIndex)
		case .down:
			// Move down one row (6 items forward), clamp at end
			let newIndex = highlightedColorIndex + itemsPerRow
			highlightedColorIndex = min(totalColors - 1, newIndex)
		}
	}

	enum GridDirection {
		case up, down, left, right
	}

	private var iconGridSection: some View {
		Section("Icon") {
			LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
				ForEach(Array(commonIcons.enumerated()), id: \.offset) { index, icon in
					Button(action: { selectedIcon = icon }) {
						ZStack {
							RoundedRectangle(cornerRadius: 8)
								.fill(selectedIcon == icon ? Color.accentColor : Color.secondary.opacity(0.1))

							Image(systemName: icon)
								.font(.title3)
								.foregroundStyle(selectedIcon == icon ? .white : .primary)

							if highlightedIconIndex == index && focusedField == .iconGrid {
								RoundedRectangle(cornerRadius: 8)
									.strokeBorder(Color.accentColor, lineWidth: 3)
							}
						}
						.frame(width: 44, height: 44)
						.scaleEffect(highlightedIconIndex == index && focusedField == .iconGrid ? 1.05 : 1.0)
					}
					.buttonStyle(.plain)
				}
			}
			.focusable()
			.focused($focusedField, equals: .iconGrid)
			.focusEffectDisabled()
			.onKeyPress(.upArrow) {
				focusedField == .iconGrid ? (navigateIconGrid(direction: .up), .handled).1 : .ignored
			}
			.onKeyPress(.downArrow) {
				focusedField == .iconGrid ? (navigateIconGrid(direction: .down), .handled).1 : .ignored
			}
			.onKeyPress(.leftArrow) {
				focusedField == .iconGrid ? (navigateIconGrid(direction: .left), .handled).1 : .ignored
			}
			.onKeyPress(.rightArrow) {
				focusedField == .iconGrid ? (navigateIconGrid(direction: .right), .handled).1 : .ignored
			}
			.onKeyPress(.return) {
				focusedField == .iconGrid ? (selectedIcon = commonIcons[highlightedIconIndex], .handled).1 : .ignored
			}
			.onKeyPress(.space) {
				focusedField == .iconGrid ? (selectedIcon = commonIcons[highlightedIconIndex], .handled).1 : .ignored
			}
			.onKeyPress(characters: .decimalDigits) { press in
				guard focusedField == .iconGrid else { return .ignored }
				if let digit = Int(press.characters), digit >= 1 && digit <= 9, digit - 1 < commonIcons.count {
					highlightedIconIndex = digit - 1
					selectedIcon = commonIcons[digit - 1]
					return .handled
				} else if press.characters == "0" && commonIcons.count >= 10 {
					highlightedIconIndex = 9
					selectedIcon = commonIcons[9]
					return .handled
				}
				return .ignored
			}
		}
	}

	private var colorGridSection: some View {
		Section("Color") {
			LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
				ForEach(Array(presetColors.enumerated()), id: \.offset) { index, colorHex in
					Button(action: { selectedColor = colorHex }) {
						ZStack {
							RoundedRectangle(cornerRadius: 8)
								.fill(Color(hex: colorHex) ?? .blue)

							if selectedColor == colorHex {
								RoundedRectangle(cornerRadius: 8)
									.strokeBorder(Color.primary, lineWidth: 3)
							}

							if highlightedColorIndex == index && focusedField == .colorGrid {
								RoundedRectangle(cornerRadius: 8)
									.strokeBorder(Color.white, lineWidth: 2)
									.padding(1)
							}
						}
						.frame(width: 44, height: 44)
						.scaleEffect(highlightedColorIndex == index && focusedField == .colorGrid ? 1.05 : 1.0)
					}
					.buttonStyle(.plain)
				}
			}
			.focusable()
			.focused($focusedField, equals: .colorGrid)
			.focusEffectDisabled()
			.onKeyPress(.upArrow) {
				focusedField == .colorGrid ? (navigateColorGrid(direction: .up), .handled).1 : .ignored
			}
			.onKeyPress(.downArrow) {
				focusedField == .colorGrid ? (navigateColorGrid(direction: .down), .handled).1 : .ignored
			}
			.onKeyPress(.leftArrow) {
				focusedField == .colorGrid ? (navigateColorGrid(direction: .left), .handled).1 : .ignored
			}
			.onKeyPress(.rightArrow) {
				focusedField == .colorGrid ? (navigateColorGrid(direction: .right), .handled).1 : .ignored
			}
			.onKeyPress(.return) {
				focusedField == .colorGrid ? (selectedColor = presetColors[highlightedColorIndex], .handled).1 : .ignored
			}
			.onKeyPress(.space) {
				focusedField == .colorGrid ? (selectedColor = presetColors[highlightedColorIndex], .handled).1 : .ignored
			}
			.onKeyPress(characters: .decimalDigits) { press in
				guard focusedField == .colorGrid else { return .ignored }
				if let digit = Int(press.characters), digit >= 1 && digit <= 9, digit - 1 < presetColors.count {
					highlightedColorIndex = digit - 1
					selectedColor = presetColors[digit - 1]
					return .handled
				} else if press.characters == "0" && presetColors.count >= 10 {
					highlightedColorIndex = 9
					selectedColor = presetColors[9]
					return .handled
				}
				return .ignored
			}
		}
	}

	private func handleTab(isShift: Bool) {
		let fields: [Field] = [.name, .description, .iconGrid, .colorGrid, .spacePicker]
		guard let currentField = focusedField,
			  let currentIndex = fields.firstIndex(of: currentField) else {
			focusedField = fields.first
			return
		}

		if isShift {
			// Move to previous field
			let previousIndex = currentIndex > 0 ? currentIndex - 1 : fields.count - 1
			focusedField = fields[previousIndex]
		} else {
			// Move to next field
			let nextIndex = currentIndex < fields.count - 1 ? currentIndex + 1 : 0
			focusedField = fields[nextIndex]
		}

		// Reset highlighted indices when entering grids
		if focusedField == .iconGrid {
			highlightedIconIndex = commonIcons.firstIndex(of: selectedIcon) ?? 0
		} else if focusedField == .colorGrid {
			highlightedColorIndex = presetColors.firstIndex(of: selectedColor) ?? 0
		}
	}

	private func createProject() {
		let newProject = Project(
			name: name.trimmingCharacters(in: .whitespacesAndNewlines),
			icon: selectedIcon,
			color: selectedColor,
			space: selectedSpace
		)

		if !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
			// Note: Project model doesn't have description field yet, this is future-proofing
		}

		modelContext.insert(newProject)

		dismiss()
	}
}

// Custom Space Picker Button with Keyboard Navigation
struct CustomSpacePickerButton: View {
	@Binding var selectedSpace: Space?
	let spaces: [Space]
	let isFocused: Bool
	@Binding var showingPopover: Bool

	var body: some View {
		HStack(spacing: 8) {
			if let space = selectedSpace {
				Image(systemName: space.icon)
					.foregroundStyle(Color(hex: space.color) ?? .blue)
				Text(space.name)
					.foregroundStyle(.primary)
			} else {
				Text("Select a space")
					.foregroundStyle(.secondary)
			}

			Spacer()

			Image(systemName: "chevron.up.chevron.down")
				.font(.caption2)
				.foregroundStyle(.secondary)
		}
		.padding(.horizontal, 12)
		.padding(.vertical, 8)
		.background(Color.secondary.opacity(0.1))
		.clipShape(RoundedRectangle(cornerRadius: 6))
		.overlay(
			RoundedRectangle(cornerRadius: 6)
				.strokeBorder(isFocused ? Color.accentColor : Color.clear, lineWidth: 2)
		)
		.contentShape(Rectangle())
		.onTapGesture {
			showingPopover.toggle()
		}
		.popover(isPresented: $showingPopover, arrowEdge: .bottom) {
			SpacePickerPopover(selectedSpace: $selectedSpace, spaces: spaces) {
				showingPopover = false
			}
		}
	}
}

// Space Picker Popover with Keyboard Navigation
struct SpacePickerPopover: View {
	@Binding var selectedSpace: Space?
	let spaces: [Space]
	let onDismiss: () -> Void

	@State private var selectedIndex: Int = 0
	@FocusState private var isFocused: Bool

	var body: some View {
		VStack(spacing: 4) {
			ForEach(Array(spaces.enumerated()), id: \.element.id) { index, space in
				Button(action: {
					selectedSpace = space
					onDismiss()
				}) {
					HStack(spacing: 12) {
						Image(systemName: space.icon)
							.font(.system(size: 14))
							.foregroundStyle(Color(hex: space.color) ?? .blue)
							.frame(width: 16)

						Text(space.name)
							.font(.subheadline)
							.foregroundStyle(.primary)

						Spacer()

						if selectedSpace?.id == space.id {
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
		.frame(width: 220)
		.focusable()
		.focused($isFocused)
		.focusEffectDisabled()
		.onAppear {
			// Auto-focus and find current selection
			if let currentSpace = selectedSpace,
			   let index = spaces.firstIndex(where: { $0.id == currentSpace.id }) {
				selectedIndex = index
			}
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
				isFocused = true
			}
		}
		.onKeyPress(.upArrow) {
			selectedIndex = selectedIndex > 0 ? selectedIndex - 1 : spaces.count - 1
			return .handled
		}
		.onKeyPress(.downArrow) {
			selectedIndex = selectedIndex < spaces.count - 1 ? selectedIndex + 1 : 0
			return .handled
		}
		.onKeyPress(.return) {
			if selectedIndex < spaces.count {
				selectedSpace = spaces[selectedIndex]
				onDismiss()
			}
			return .handled
		}
		.onKeyPress(.escape) {
			onDismiss()
			return .handled
		}
		.onKeyPress(characters: .decimalDigits) { press in
			if let digit = Int(press.characters), digit >= 1 && digit <= 9, digit - 1 < spaces.count {
				selectedIndex = digit - 1
				selectedSpace = spaces[digit - 1]
				onDismiss()
				return .handled
			} else if press.characters == "0" && spaces.count >= 10 {
				selectedIndex = 9
				selectedSpace = spaces[9]
				onDismiss()
				return .handled
			}
			return .ignored
		}
	}
}

#Preview {
	CreateProjectSheet(preselectedSpace: nil)
		.modelContainer(for: [Project.self, Space.self], inMemory: true)
}
