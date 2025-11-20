//
//  PropertySelector.swift
//  Waypoint
//
//  Interactive property selector with hover effects and popover
//

import SwiftUI

struct PropertySelector<T: Equatable>: View {
	let icon: String
	let label: String
	let value: String
	let valueColor: Color?
	let options: [PropertyOption]
	let selectedValue: T
	let onSelect: (Any) -> Void

	@State private var isHovering: Bool = false
	@State private var showPopover: Bool = false

	init(
		icon: String,
		label: String,
		value: String,
		valueColor: Color? = nil,
		options: [PropertyOption],
		selectedValue: T,
		onSelect: @escaping (Any) -> Void
	) {
		self.icon = icon
		self.label = label
		self.value = value
		self.valueColor = valueColor
		self.options = options
		self.selectedValue = selectedValue
		self.onSelect = onSelect
	}

	private var borderColor: Color {
		if showPopover {
			return .accentColor.opacity(0.5)
		} else if isHovering {
			return .primary.opacity(0.2)
		} else {
			return .clear
		}
	}

	var body: some View {
		Button(action: {
			showPopover = true
		}) {
			HStack(spacing: 8) {
				// Icon
				Image(systemName: icon)
					.font(.subheadline)
					.foregroundStyle(.secondary)
					.frame(width: 16)

				// Label
				Text(label)
					.font(.subheadline)
					.foregroundStyle(.secondary)

				Spacer()

				// Value
				Text(value)
					.font(.subheadline)
					.fontWeight(.medium)
					.foregroundStyle(valueColor ?? .primary)
			}
			.padding(.horizontal, 8)
			.padding(.vertical, 6)
			.contentShape(Rectangle())
			.background(
				RoundedRectangle(cornerRadius: 6)
					.strokeBorder(borderColor, lineWidth: 1)
			)
		}
		.buttonStyle(.plain)
		.onHover { hovering in
			isHovering = hovering
		}
		.popover(isPresented: $showPopover, arrowEdge: .trailing) {
			PropertyPopover(
				options: options,
				selectedValue: selectedValue,
				onSelect: { newValue in
					onSelect(newValue)
				}
			)
		}
	}
}
