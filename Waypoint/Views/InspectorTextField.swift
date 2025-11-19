//
//  InspectorTextField.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/19/25.
//

import SwiftUI

struct InspectorTextField<FocusValue: Hashable>: View {
	@Binding var text: String
	var focused: FocusState<FocusValue?>.Binding?
	var focusValue: FocusValue?
	@State private var isHovering: Bool = false

	var placeholder: String = ""
	var font: Font = .headline
	var onCommit: (() -> Void)? = nil

	@FocusState private var internalFocus: Bool

	private var isFocused: Bool {
		if let focused = focused, let focusValue = focusValue {
			return focused.wrappedValue == focusValue
		}
		return internalFocus
	}

	var body: some View {
		Group {
			if let focused = focused, let focusValue = focusValue {
				TextField(placeholder, text: $text, axis: .vertical)
					.font(font)
					.textFieldStyle(.plain)
					.focused(focused, equals: focusValue)
			} else {
				TextField(placeholder, text: $text, axis: .vertical)
					.font(font)
					.textFieldStyle(.plain)
					.focused($internalFocus)
			}
		}
		.padding(.horizontal, 8)
		.padding(.vertical, 6)
			.background(
				RoundedRectangle(cornerRadius: 6)
					.strokeBorder(
						borderColor,
						lineWidth: 1
					)
					.background(
						RoundedRectangle(cornerRadius: 6)
							.fill(isFocused ? Color(nsColor: .controlBackgroundColor) : .clear)
					)
			)
			.onHover { hovering in
				isHovering = hovering
			}
			.onAppear {
				// When the field appears focused, select all text
				if isFocused {
					// Delay slightly to ensure the text field is ready
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
						NSApp.keyWindow?.firstResponder?.performSelector(
							onMainThread: #selector(NSText.selectAll(_:)),
							with: nil,
							waitUntilDone: false
						)
					}
				}
			}
			.onChange(of: isFocused) { oldValue, newValue in
				if newValue {
					// When focused, select all text
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
						NSApp.keyWindow?.firstResponder?.performSelector(
							onMainThread: #selector(NSText.selectAll(_:)),
							with: nil,
							waitUntilDone: false
						)
					}
				} else if !newValue && oldValue {
					// When focus is lost, call onCommit
					onCommit?()
				}
			}
			.onSubmit {
				if let focused = focused {
					focused.wrappedValue = nil
				} else {
					internalFocus = false
				}
				onCommit?()
			}
	}

	private var borderColor: Color {
		if isFocused {
			return .accentColor.opacity(0.5)
		} else if isHovering {
			return .primary.opacity(0.2)
		} else {
			return .clear
		}
	}
}

#Preview {
	@Previewable @State var text = "Sample Issue Title"

	VStack(alignment: .leading, spacing: 20) {
		InspectorTextField<Int>(
			text: $text,
			focused: nil,
			focusValue: nil,
			placeholder: "Enter title..."
		)
		.frame(maxWidth: 300)

		Text("Text: \(text)")
			.font(.caption)
			.foregroundStyle(.secondary)
	}
	.padding()
	.frame(width: 400, height: 300)
}
