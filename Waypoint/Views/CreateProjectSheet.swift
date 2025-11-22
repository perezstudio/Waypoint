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
	@State private var selectedIcon: String = "folder.fill"
	@State private var selectedColor: AppColor = .blue
	@State private var selectedSpace: Space?
	@State private var isFavorite: Bool = false
	@State private var highlightedIconIndex: Int = 0
	@State private var highlightedColorIndex: Int = 0
	@State private var showingSpacePicker: Bool = false
	@FocusState private var focusedField: Field?

	enum Field: Hashable {
		case name
		case spacePicker
		case favorite
		case iconGrid
		case colorGrid
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
		"cart.fill", "creditcard.fill", "chart.bar.fill", "chart.xyaxis.line",
		"safari.fill", "iphone", "laptopcomputer", "desktopcomputer"
	]

	// Use AppColor enum for consistent colors
	private let presetColors = AppColor.allCases

	var body: some View {
		NavigationStack {
			VStack(spacing: 0) {
				ModalHeader(title: "Create Project")

				ScrollViewReader { proxy in
					Form {
					Section("Name") {
						ZStack(alignment: .topLeading) {
							TextEditor(text: $name)
								.font(.title3)
								.fontWeight(.semibold)
								.focused($focusedField, equals: .name)
								.scrollContentBackground(.hidden)
								.frame(minHeight: 40, maxHeight: 80)
						}
					}
					.id(Field.name)

					// Organizational Settings Section
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

					Section {
						FavoriteToggleRow(isFavorite: $isFavorite, isFocused: focusedField == .favorite)
							.focusable()
							.focused($focusedField, equals: .favorite)
							.focusEffectDisabled()
							.id(Field.favorite)
							.onKeyPress(.space) {
								guard focusedField == .favorite else { return .ignored }
								isFavorite.toggle()
								return .handled
							}
							.onKeyPress(.return) {
								guard focusedField == .favorite else { return .ignored }
								isFavorite.toggle()
								return .handled
							}
					}

					iconGridSection
						.id(Field.iconGrid)

					colorScrollSection
						.id(Field.colorGrid)
				}
				.formStyle(.grouped)
				.onChange(of: focusedField) { _, newField in
					if let field = newField {
						DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
							withAnimation {
								proxy.scrollTo(field, anchor: .center)
							}
						}
					}
				}
			}

			ModalFooter(
				cancelAction: { dismiss() },
				primaryAction: { createProject() },
				primaryLabel: "Create",
				isPrimaryDisabled: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedSpace == nil
			)
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
			.onKeyPress(keys: [.return]) { press in
				if press.modifiers.contains(.command) {
					// Command+Return to create project
					if !(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedSpace == nil) {
						createProject()
						return .handled
					}
				}
				return .ignored
			}
			.onKeyPress(keys: [.escape]) { press in
				dismiss()
				return .handled
			}
		}
		.frame(width: 500, height: 550)
	}

	private var iconGridSection: some View {
		Section("Icon") {
			ScrollViewReader { iconProxy in
				ScrollView(.horizontal, showsIndicators: false) {
					VStack(spacing: 8) {
						// First row (icons 0-11)
						HStack(spacing: 8) {
							ForEach(Array(commonIcons.prefix(12).enumerated()), id: \.offset) { index, icon in
								iconButton(icon: icon, index: index)
							}
						}

						// Second row (icons 12-23)
						HStack(spacing: 8) {
							ForEach(Array(commonIcons.suffix(from: 12).enumerated()), id: \.offset) { index, icon in
								iconButton(icon: icon, index: index + 12)
							}
						}
					}
					.padding(.vertical, 4)
				}
				.focusable()
				.focused($focusedField, equals: .iconGrid)
				.focusEffectDisabled()
				.onKeyPress(.upArrow) {
					guard focusedField == .iconGrid else { return .ignored }
					let iconsPerRow = 12
					if highlightedIconIndex >= iconsPerRow {
						highlightedIconIndex -= iconsPerRow
						withAnimation {
							iconProxy.scrollTo(highlightedIconIndex, anchor: .center)
						}
					}
					return .handled
				}
				.onKeyPress(.downArrow) {
					guard focusedField == .iconGrid else { return .ignored }
					let iconsPerRow = 12
					if highlightedIconIndex < iconsPerRow {
						highlightedIconIndex = min(highlightedIconIndex + iconsPerRow, commonIcons.count - 1)
						withAnimation {
							iconProxy.scrollTo(highlightedIconIndex, anchor: .center)
						}
					}
					return .handled
				}
				.onKeyPress(.leftArrow) {
					guard focusedField == .iconGrid else { return .ignored }
					highlightedIconIndex = highlightedIconIndex > 0 ? highlightedIconIndex - 1 : commonIcons.count - 1
					withAnimation {
						iconProxy.scrollTo(highlightedIconIndex, anchor: .center)
					}
					return .handled
				}
				.onKeyPress(.rightArrow) {
					guard focusedField == .iconGrid else { return .ignored }
					highlightedIconIndex = highlightedIconIndex < commonIcons.count - 1 ? highlightedIconIndex + 1 : 0
					withAnimation {
						iconProxy.scrollTo(highlightedIconIndex, anchor: .center)
					}
					return .handled
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
						withAnimation {
							iconProxy.scrollTo(highlightedIconIndex, anchor: .center)
						}
						return .handled
					} else if press.characters == "0" && commonIcons.count >= 10 {
						highlightedIconIndex = 9
						selectedIcon = commonIcons[9]
						withAnimation {
							iconProxy.scrollTo(9, anchor: .center)
						}
						return .handled
					}
					return .ignored
				}
				.onChange(of: focusedField) { _, newField in
					if newField == .iconGrid {
						DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
							withAnimation {
								iconProxy.scrollTo(highlightedIconIndex, anchor: .center)
							}
						}
					}
				}
			}
		}
	}

	private func iconButton(icon: String, index: Int) -> some View {
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
		.id(index)
	}

	private var colorScrollSection: some View {
		Section("Color") {
			ScrollViewReader { colorProxy in
				ScrollView(.horizontal, showsIndicators: false) {
					HStack(spacing: 8) {
						ForEach(Array(presetColors.enumerated()), id: \.offset) { index, appColor in
							Button(action: { selectedColor = appColor }) {
								ZStack {
									RoundedRectangle(cornerRadius: 8)
										.fill(appColor.color)

									if selectedColor == appColor {
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
							.id(index)
						}
					}
					.padding(.vertical, 4)
				}
				.focusable()
				.focused($focusedField, equals: .colorGrid)
				.focusEffectDisabled()
				.onKeyPress(.leftArrow) {
					guard focusedField == .colorGrid else { return .ignored }
					highlightedColorIndex = highlightedColorIndex > 0 ? highlightedColorIndex - 1 : presetColors.count - 1
					withAnimation {
						colorProxy.scrollTo(highlightedColorIndex, anchor: .center)
					}
					return .handled
				}
				.onKeyPress(.rightArrow) {
					guard focusedField == .colorGrid else { return .ignored }
					highlightedColorIndex = highlightedColorIndex < presetColors.count - 1 ? highlightedColorIndex + 1 : 0
					withAnimation {
						colorProxy.scrollTo(highlightedColorIndex, anchor: .center)
					}
					return .handled
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
						withAnimation {
							colorProxy.scrollTo(highlightedColorIndex, anchor: .center)
						}
						return .handled
					} else if press.characters == "0" && presetColors.count >= 10 {
						highlightedColorIndex = 9
						selectedColor = presetColors[9]
						withAnimation {
							colorProxy.scrollTo(9, anchor: .center)
						}
						return .handled
					}
					return .ignored
				}
				.onChange(of: focusedField) { _, newField in
					if newField == .colorGrid {
						DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
							withAnimation {
								colorProxy.scrollTo(highlightedColorIndex, anchor: .center)
							}
						}
					}
				}
			}
		}
	}

	private func handleTab(isShift: Bool) {
		let fields: [Field] = [.name, .spacePicker, .favorite, .iconGrid, .colorGrid]
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
			color: selectedColor.hexString,
			space: selectedSpace
		)

		newProject.favorite = isFavorite

		modelContext.insert(newProject)

		dismiss()
	}
}

// Custom Favorite Toggle Row
struct FavoriteToggleRow: View {
	@Binding var isFavorite: Bool
	let isFocused: Bool

	var body: some View {
		HStack(spacing: 12) {
			Toggle("Mark as Favorite", isOn: $isFavorite)
			Spacer()
		}
		.contentShape(Rectangle())
		.overlay(
			RoundedRectangle(cornerRadius: 6)
				.strokeBorder(isFocused ? Color.accentColor : Color.clear, lineWidth: 2)
		)
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

// MARK: - Reusable Modal Components

struct ModalHeader: View {
	let title: String

	var body: some View {
		Text(title)
			.font(.title)
			.fontWeight(.bold)
			.frame(maxWidth: .infinity, alignment: .leading)
			.padding(.horizontal, 20)
			.padding(.vertical, 24)
	}
}

struct ModalFooter: View {
	let cancelAction: () -> Void
	let primaryAction: () -> Void
	let primaryLabel: String
	var isPrimaryDisabled: Bool = false

	var body: some View {
		HStack(spacing: 12) {
			Spacer()

			KeyboardShortcutButton(
				label: "Cancel",
				action: cancelAction,
				shortcutKey: "esc",
				style: .primary,
				accentColor: .gray
			)
			.keyboardShortcut(.cancelAction)

			KeyboardShortcutButton(
				label: primaryLabel,
				action: primaryAction,
				shortcutKey: "↵",
				style: .primary,
				accentColor: .blue
			)
			.keyboardShortcut(.defaultAction)
			.disabled(isPrimaryDisabled)
		}
		.padding()
	}
}

#Preview {
	CreateProjectSheet(preselectedSpace: nil)
		.modelContainer(for: [Project.self, Space.self], inMemory: true)
}
