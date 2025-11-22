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
	@Environment(ProjectStore.self) private var projectStore

	@State private var name: String = ""
	@State private var description: String = ""
	@State private var selectedIcon: String = "person.3.fill"
	@State private var selectedColor: AppColor = .blue
	@State private var highlightedIconIndex: Int = 0
	@State private var highlightedColorIndex: Int = 0
	@FocusState private var focusedField: Field?

	enum Field: Hashable {
		case name
		case description
		case iconGrid
		case colorGrid
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
			VStack(spacing: 0) {
				ModalHeader(title: "Create Space")

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

						Section("Description") {
							ZStack(alignment: .topLeading) {
								TextEditor(text: $description)
									.font(.body)
									.focused($focusedField, equals: .description)
									.scrollContentBackground(.hidden)
									.frame(minHeight: 60, maxHeight: 120)
							}
						}
						.id(Field.description)

						iconScrollSection
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
					primaryAction: { createSpace() },
					primaryLabel: "Create",
					isPrimaryDisabled: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
					if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
						createSpace()
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
		.frame(width: 500, height: 600)
	}

	private var iconScrollSection: some View {
		Section("Icon") {
			ScrollViewReader { iconProxy in
				ScrollView(.horizontal, showsIndicators: false) {
					VStack(alignment: .leading, spacing: 8) {
						// First row (icons 0-8)
						HStack(spacing: 8) {
							ForEach(Array(commonIcons.prefix(9).enumerated()), id: \.offset) { index, icon in
								iconButton(icon: icon, index: index)
							}
						}

						// Second row (icons 9-16)
						HStack(spacing: 8) {
							ForEach(Array(commonIcons.suffix(from: 9).enumerated()), id: \.offset) { index, icon in
								iconButton(icon: icon, index: index + 9)
							}
						}
					}
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding(.vertical, 4)
				}
				.focusable()
				.focused($focusedField, equals: .iconGrid)
				.focusEffectDisabled()
				.onKeyPress(.upArrow) {
					guard focusedField == .iconGrid else { return .ignored }
					let iconsPerRow = 9
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
					let iconsPerRow = 9
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
		let fields: [Field] = [.name, .description, .iconGrid, .colorGrid]
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
			highlightedIconIndex = commonIcons.firstIndex(of: selectedIcon) ?? 0
		} else if focusedField == .colorGrid {
			highlightedColorIndex = presetColors.firstIndex(of: selectedColor) ?? 0
		}
	}

	private func createSpace() {
		// Find the max sort value to add the new space at the end
		let descriptor = FetchDescriptor<Space>(
			sortBy: [SortDescriptor(\.sort, order: .reverse)]
		)
		let existingSpaces = (try? modelContext.fetch(descriptor)) ?? []
		let maxSort = existingSpaces.first?.sort ?? -1

		let newSpace = Space(
			name: name.trimmingCharacters(in: .whitespacesAndNewlines),
			spaceDescription: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
			icon: selectedIcon,
			color: selectedColor.hexString,
			sort: maxSort + 1
		)

		modelContext.insert(newSpace)

		// Set the new space as the current space
		projectStore.currentSpace = newSpace

		dismiss()
	}
}

#Preview {
	CreateSpaceSheet()
		.modelContainer(for: [Space.self], inMemory: true)
}
