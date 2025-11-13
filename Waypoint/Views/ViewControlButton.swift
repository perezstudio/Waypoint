//
//  ViewControlButton.swift
//  Waypoint
//

import SwiftUI

struct ViewControlButton: View {
	@Environment(ViewSettingsStore.self) private var viewSettingsStore

	let icon: String
	let text: String
	let showLabel: Bool
	let action: () -> Void

	init(icon: String, text: String, showLabel: Bool = true, action: @escaping () -> Void) {
		self.icon = icon
		self.text = text
		self.showLabel = showLabel
		self.action = action
	}

	var body: some View {
		if showLabel && viewSettingsStore.controlDisplayMode != .iconOnly {
			VStack(alignment: .center, spacing: 4) {
				Button(action: action) {
					if viewSettingsStore.controlDisplayMode == .textOnly {
						Text(text)
							.padding(6)
							.background(.bar)
							.clipShape(RoundedRectangle(cornerRadius: 5))
					} else {
						Image(systemName: icon)
							.padding(6)
							.background(.bar)
							.clipShape(RoundedRectangle(cornerRadius: 5))
					}
				}
				.buttonStyle(.plain)
				.help(text)

				Text(text)
					.font(.caption)
					.foregroundStyle(.secondary)
			}
		} else {
			Button(action: action) {
				if viewSettingsStore.controlDisplayMode == .textOnly {
					Text(text)
						.padding(6)
						.background(.bar)
						.clipShape(RoundedRectangle(cornerRadius: 5))
				} else {
					Image(systemName: icon)
						.padding(6)
						.background(.bar)
						.clipShape(RoundedRectangle(cornerRadius: 5))
				}
			}
			.buttonStyle(.plain)
			.help(text)
		}
	}
}

struct ViewControlMenu<Content: View>: View {
	@Environment(ViewSettingsStore.self) private var viewSettingsStore

	let icon: String
	let text: String
	let selectedText: String
	let showLabel: Bool
	let content: Content

	init(icon: String, text: String, selectedText: String? = nil, showLabel: Bool = true, @ViewBuilder content: () -> Content) {
		self.icon = icon
		self.text = text
		self.selectedText = selectedText ?? text
		self.showLabel = showLabel
		self.content = content()
	}

	var body: some View {
		if showLabel && viewSettingsStore.controlDisplayMode != .iconOnly {
			VStack(alignment: .center, spacing: 4) {
				Menu {
					content
				} label: {
					if viewSettingsStore.controlDisplayMode == .textOnly {
						Text(selectedText)
							.padding(6)
							.background(.bar)
							.clipShape(RoundedRectangle(cornerRadius: 5))
					} else {
						Image(systemName: icon)
							.padding(6)
							.background(.bar)
							.clipShape(RoundedRectangle(cornerRadius: 5))
					}
				}
				.buttonStyle(.plain)
				.help(text)

				Text(text)
					.font(.caption)
					.foregroundStyle(.secondary)
			}
		} else {
			Menu {
				content
			} label: {
				if viewSettingsStore.controlDisplayMode == .textOnly {
					Text(selectedText)
						.padding(6)
						.background(.bar)
						.clipShape(RoundedRectangle(cornerRadius: 5))
				} else {
					Image(systemName: icon)
						.padding(6)
						.background(.bar)
						.clipShape(RoundedRectangle(cornerRadius: 5))
				}
			}
			.buttonStyle(.plain)
			.help(text)
		}
	}
}
