//
//  DatePropertySelector.swift
//  Waypoint
//
//  Date picker property selector with hover effects
//

import SwiftUI

struct DatePropertySelector: View {
	let icon: String
	let label: String
	let date: Date?
	let onSelect: (Date?) -> Void

	@State private var isHovering: Bool = false
	@State private var showPopover: Bool = false
	@State private var selectedDate: Date
	@FocusState private var isFocused: Bool

	init(icon: String, label: String, date: Date?, onSelect: @escaping (Date?) -> Void) {
		self.icon = icon
		self.label = label
		self.date = date
		self.onSelect = onSelect
		_selectedDate = State(initialValue: date ?? Date())
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

	private var displayValue: String {
		if let date = date {
			return date.formatted(date: .long, time: .omitted)
		}
		return "Not set"
	}

	var body: some View {
		Button(action: {
			if date != nil {
				selectedDate = date!
			}
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
				Text(displayValue)
					.font(.subheadline)
					.fontWeight(.medium)
					.foregroundStyle(date == nil ? .secondary : .primary)
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
			VStack(spacing: 12) {
				DatePicker(
					"Select Date",
					selection: $selectedDate,
					displayedComponents: .date
				)
				.datePickerStyle(.graphical)
				.labelsHidden()

				HStack(spacing: 8) {
					// Clear button
					if date != nil {
						Button("Clear") {
							onSelect(nil)
							showPopover = false
						}
						.buttonStyle(.bordered)
					}

					Button("Done") {
						onSelect(selectedDate)
						showPopover = false
					}
					.buttonStyle(.borderedProminent)
				}
			}
			.padding()
			.focusable()
			.focused($isFocused)
			.focusEffectDisabled()
			.onAppear {
				isFocused = true
			}
			.onKeyPress(.escape) {
				showPopover = false
				return .handled
			}
			.onKeyPress(.return) {
				onSelect(selectedDate)
				showPopover = false
				return .handled
			}
		}
	}
}
