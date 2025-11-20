//
//  PropertyPopover.swift
//  Waypoint
//
//  Popover content for property selection with keyboard navigation
//

import SwiftUI

struct PropertyOption: Identifiable {
	let id = UUID()
	let label: String
	let icon: String?
	let color: Color?
	let value: Any

	init(label: String, icon: String? = nil, color: Color? = nil, value: Any) {
		self.label = label
		self.icon = icon
		self.color = color
		self.value = value
	}
}

struct PropertyPopover<T: Equatable>: View {
	let options: [PropertyOption]
	let selectedValue: T
	let onSelect: (Any) -> Void
	@Environment(\.dismiss) private var dismiss
	@State private var hoveredIndex: Int? = nil
	@FocusState private var isFocused: Bool

	var selectedIndex: Int? {
		options.firstIndex(where: { option in
			if let value = option.value as? T {
				return value == selectedValue
			}
			return false
		})
	}

	var body: some View {
		VStack(spacing: 2) {
			ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
				Button(action: {
					onSelect(option.value)
					dismiss()
				}) {
					HStack(spacing: 8) {
						// Number prefix
						Text("\(index + 1)")
							.font(.caption)
							.foregroundStyle(.secondary)
							.frame(width: 16, alignment: .trailing)

						// Icon if provided
						if let icon = option.icon {
							Image(systemName: icon)
								.font(.subheadline)
								.foregroundStyle(option.color ?? .primary)
								.frame(width: 16)
						}

						// Label
						Text(option.label)
							.font(.subheadline)
							.foregroundStyle(option.color ?? .primary)

						Spacer()

						// Checkmark for selected item
						if index == selectedIndex {
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
							.fill(backgroundColor(for: index))
					)
				}
				.buttonStyle(.plain)
				.onHover { hovering in
					hoveredIndex = hovering ? index : nil
				}
			}
		}
		.padding(6)
		.frame(minWidth: 200)
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
				onSelect(options[hoveredIndex].value)
				dismiss()
			}
			return .handled
		}
		.onKeyPress(.upArrow) {
			if let current = hoveredIndex {
				hoveredIndex = max(0, current - 1)
			} else {
				hoveredIndex = options.count - 1
			}
			return .handled
		}
		.onKeyPress(.downArrow) {
			if let current = hoveredIndex {
				hoveredIndex = min(options.count - 1, current + 1)
			} else {
				hoveredIndex = 0
			}
			return .handled
		}
		.onKeyPress(characters: .decimalDigits) { press in
			switch press.characters {
			case "1": selectOption(at: 0)
			case "2": selectOption(at: 1)
			case "3": selectOption(at: 2)
			case "4": selectOption(at: 3)
			case "5": selectOption(at: 4)
			case "6": selectOption(at: 5)
			case "7": selectOption(at: 6)
			case "8": selectOption(at: 7)
			case "9": selectOption(at: 8)
			default: return .ignored
			}
			return .handled
		}
	}

	private func backgroundColor(for index: Int) -> Color {
		if index == hoveredIndex {
			return Color.accentColor.opacity(0.1)
		}
		return Color.clear
	}

	private func selectOption(at index: Int) {
		guard index < options.count else { return }
		onSelect(options[index].value)
		dismiss()
	}
}
