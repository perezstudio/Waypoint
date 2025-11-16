//
//  KeyboardShortcutButton.swift
//  Waypoint
//
//  Created by Claude on 11/15/25.
//

import SwiftUI

enum KeyboardShortcutButtonStyle {
	case primary
	case secondary
}

struct KeyboardShortcutButton: View {
	let label: String
	let action: () -> Void
	var icon: String? = nil
	var iconColor: Color? = nil
	var isSelected: Bool = false
	var shortcutKey: String? = nil
	var tooltip: String? = nil
	var style: KeyboardShortcutButtonStyle = .secondary
	var accentColor: Color? = nil  // For primary style tinting

	@State private var isHovered: Bool = false

	var body: some View {
		Button(action: action) {
			HStack(spacing: 8) {
				// Icon (optional)
				if let icon = icon {
					Image(systemName: icon)
						.frame(width: 18, height: 18)
						.foregroundStyle(iconForegroundColor)
				}

				// Label
				Text(label)
					.fontWeight(.medium)
					.foregroundStyle(.white)

				// Keyboard shortcut badge (optional)
				if let key = shortcutKey {
					shortcutBadge(key: key)
				}
			}
			.frame(height: 26)
			.padding(.horizontal, 12)
			.padding(.vertical, 6)
			.background {
				backgroundView
			}
			.contentShape(Rectangle())
		}
		.buttonStyle(.plain)
		.onHover { hovering in
			withAnimation(.easeInOut(duration: 0.15)) {
				isHovered = hovering
			}
		}
		.help(tooltip ?? "")
		.accessibilityLabel(label)
		.accessibilityHint(shortcutKey != nil ? "Keyboard shortcut: Command+\(shortcutKey!)" : "")
		.accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
	}

	// MARK: - Computed Properties

	private var iconForegroundColor: Color {
		switch style {
		case .primary:
			// Primary style: use white or custom icon color
			return iconColor ?? .white
		case .secondary:
			// Secondary style: use custom color when selected, dimmed white otherwise
			return isSelected ? (iconColor ?? .blue) : .white.opacity(0.6)
		}
	}

	@ViewBuilder
	private var backgroundView: some View {
		switch style {
		case .primary:
			// Primary style: always show background with accent color tint
			RoundedRectangle(cornerRadius: 8, style: .continuous)
				.fill(accentColor?.opacity(0.2) ?? Color.blue.opacity(0.2))
				.overlay {
					RoundedRectangle(cornerRadius: 8, style: .continuous)
						.strokeBorder(accentColor?.opacity(0.3) ?? Color.blue.opacity(0.3), lineWidth: 1)
				}
				.opacity(isHovered ? 0.8 : 1.0)
		case .secondary:
			// Secondary style: show background only on hover/selected
			RoundedRectangle(cornerRadius: 8, style: .continuous)
				.fill(Color.secondary.opacity(0.15))
				.opacity(isSelected || isHovered ? 1 : 0)
		}
	}

	@ViewBuilder
	private func shortcutBadge(key: String) -> some View {
		Text(key.uppercased())
			.font(.system(size: 10, weight: .semibold))
			.foregroundStyle(.white.opacity(0.8))
			.padding(.horizontal, 5)
			.padding(.vertical, 2)
			.background {
				RoundedRectangle(cornerRadius: 4, style: .continuous)
					.fill(.white.opacity(0.15))
			}
			.overlay {
				RoundedRectangle(cornerRadius: 4, style: .continuous)
					.strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
			}
	}
}

#Preview {
	VStack(alignment: .leading, spacing: 16) {
		Text("Primary Style (Always has background with accent color)")
			.font(.caption)
			.foregroundStyle(.secondary)

		KeyboardShortcutButton(
			label: "Create Issue",
			action: {},
			icon: "plus",
			iconColor: .white,
			shortcutKey: "⇧N",
			tooltip: "Create new issue (⌘⇧N)",
			style: .primary,
			accentColor: .blue
		)

		KeyboardShortcutButton(
			label: "New Project",
			action: {},
			icon: "folder.badge.plus",
			iconColor: .white,
			shortcutKey: "N",
			tooltip: "Create new project (⌘N)",
			style: .primary,
			accentColor: .green
		)

		Divider()

		Text("Secondary Style (Background on hover/selected)")
			.font(.caption)
			.foregroundStyle(.secondary)

		KeyboardShortcutButton(
			label: "Inbox",
			action: {},
			icon: "tray.fill",
			iconColor: .blue,
			shortcutKey: "I",
			tooltip: "View inbox (⌘I)",
			style: .secondary
		)

		KeyboardShortcutButton(
			label: "Today",
			action: {},
			icon: "calendar",
			iconColor: .orange,
			isSelected: true,
			shortcutKey: "T",
			tooltip: "View today (⌘T)",
			style: .secondary
		)

		Divider()

		Text("Label + Shortcut (No Icon)")
			.font(.caption)
			.foregroundStyle(.secondary)

		KeyboardShortcutButton(
			label: "Settings",
			action: {},
			shortcutKey: ",",
			tooltip: "Settings (⌘,)"
		)

		Divider()

		Text("Multiple primary buttons in HStack")
			.font(.caption)
			.foregroundStyle(.secondary)

		HStack(spacing: 12) {
			KeyboardShortcutButton(
				label: "Save",
				action: {},
				icon: "square.and.arrow.down",
				shortcutKey: "S",
				style: .primary,
				accentColor: .blue
			)

			KeyboardShortcutButton(
				label: "Delete",
				action: {},
				icon: "trash",
				shortcutKey: "⌫",
				style: .primary,
				accentColor: .red
			)
		}
	}
	.padding()
	.frame(width: 500)
	.background(.black.opacity(0.8))
}
