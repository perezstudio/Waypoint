//
//  SettingsView.swift
//  Waypoint
//

import SwiftUI

struct SettingsView: View {
	var body: some View {
		TabView {
			GeneralSettingsView()
				.tabItem {
					Label("General", systemImage: "gear")
				}
		}
		.frame(width: 500, height: 300)
	}
}

struct GeneralSettingsView: View {
	@Environment(ViewSettingsStore.self) private var settingsStore

	var body: some View {
		@Bindable var viewSettingsStore = settingsStore

		Form {
			Section {
				Picker("Control Display Mode:", selection: $viewSettingsStore.controlDisplayMode) {
					ForEach(ControlDisplayMode.allCases, id: \.self) { mode in
						Text(mode.rawValue).tag(mode)
					}
				}
				.pickerStyle(.segmented)

				Text("Choose how view controls are displayed in the header toolbar")
					.font(.caption)
					.foregroundStyle(.secondary)
			} header: {
				Text("Appearance")
			}
		}
		.formStyle(.grouped)
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
}

#Preview {
	SettingsView()
		.environment(ViewSettingsStore())
}
