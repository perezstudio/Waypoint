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
	@State private var highlightedIconIndex: Int = 0
	@State private var highlightedColorIndex: Int = 0
	@State private var showingSpacePicker: Bool = false
	@FocusState private var focusedField: Field?

	enum Field: Hashable {
		case name
		case spacePicker
		case colorGrid
		case iconGrid
	}

	init(preselectedSpace: Space? = nil) {
		self.preselectedSpace = preselectedSpace
		_selectedSpace = State(initialValue: preselectedSpace)
	}

	// Get tag icons from unified catalog
	private let commonIcons = AppIcon.icons(for: .tag)

	// Use AppColor enum for consistent colors
	private let presetColors = AppColor.allCases

	var body: some View {
		NavigationStack {
			VStack(spacing: 0) {
				ModalHeader(title: "Create Tag")

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

						colorScrollSection
							.id(Field.colorGrid)

						iconScrollSection
							.id(Field.iconGrid)
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
					primaryAction: { createTag() },
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
					if !(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedSpace == nil) {
						createTag()
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

	// Binding helper to convert between String? and String for IconPickerGrid
	private var iconBinding: Binding<String> {
		Binding(
			get: { selectedIcon ?? "" },
			set: { newValue in
				selectedIcon = newValue.isEmpty ? nil : newValue
			}
		)
	}

	private var iconScrollSection: some View {
		Section("Icon (Optional)") {
			ScrollViewReader { iconProxy in
				IconPickerGrid(
					selectedIcon: iconBinding,
					icons: commonIcons,
					allowNone: true,
					highlightedIndex: $highlightedIconIndex,
					iconsPerRow: 8
				)
				.focusable()
				.focused($focusedField, equals: .iconGrid)
				.focusEffectDisabled()
				.onKeyPress(.upArrow) {
					guard focusedField == .iconGrid else { return .ignored }
					let iconsPerRow = 8
					// Account for the nil option at index 0
					let totalIcons = commonIcons.count + 1
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
					let iconsPerRow = 8
					// Account for the nil option at index 0
					let totalIcons = commonIcons.count + 1
					if highlightedIconIndex < iconsPerRow {
						highlightedIconIndex = min(highlightedIconIndex + iconsPerRow, totalIcons - 1)
						withAnimation {
							iconProxy.scrollTo(highlightedIconIndex, anchor: .center)
						}
					}
					return .handled
				}
				.onKeyPress(.leftArrow) {
					guard focusedField == .iconGrid else { return .ignored }
					// Account for the nil option at index 0
					let totalIcons = commonIcons.count + 1
					highlightedIconIndex = highlightedIconIndex > 0 ? highlightedIconIndex - 1 : totalIcons - 1
					withAnimation {
						iconProxy.scrollTo(highlightedIconIndex, anchor: .center)
					}
					return .handled
				}
				.onKeyPress(.rightArrow) {
					guard focusedField == .iconGrid else { return .ignored }
					// Account for the nil option at index 0
					let totalIcons = commonIcons.count + 1
					highlightedIconIndex = highlightedIconIndex < totalIcons - 1 ? highlightedIconIndex + 1 : 0
					withAnimation {
						iconProxy.scrollTo(highlightedIconIndex, anchor: .center)
					}
					return .handled
				}
				.onKeyPress(.return) {
					guard focusedField == .iconGrid else { return .ignored }
					// Index 0 is nil, indices 1+ are the actual icons
					selectedIcon = highlightedIconIndex == 0 ? nil : commonIcons[highlightedIconIndex - 1]
					return .handled
				}
				.onKeyPress(.space) {
					guard focusedField == .iconGrid else { return .ignored }
					// Index 0 is nil, indices 1+ are the actual icons
					selectedIcon = highlightedIconIndex == 0 ? nil : commonIcons[highlightedIconIndex - 1]
					return .handled
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

	private func handleTab(isShift: Bool) {
		let fields: [Field] = [.name, .spacePicker, .colorGrid, .iconGrid]
		guard let currentField = focusedField,
			  let currentIndex = fields.firstIndex(of: currentField) else {
			focusedField = fields.first
			return
		}

		if isShift {
			let previousIndex = currentIndex > 0 ? currentIndex - 1 : fields.count - 1
			focusedField = fields[previousIndex]
		} else {
			let nextIndex = currentIndex < fields.count - 1 ? currentIndex + 1 : 0
			focusedField = fields[nextIndex]
		}

		if focusedField == .iconGrid {
			if let icon = selectedIcon, let index = commonIcons.firstIndex(of: icon) {
				highlightedIconIndex = index + 1  // +1 because index 0 is the nil option
			} else {
				highlightedIconIndex = 0  // nil option
			}
		} else if focusedField == .colorGrid {
			highlightedColorIndex = presetColors.firstIndex(of: selectedColor) ?? 0
		}
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
