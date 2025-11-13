//
//  WaypointApp.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/11/25.
//

import SwiftUI
import SwiftData

@main
struct WaypointApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            Project.self,
            Issue.self,
            Tag.self,
            Space.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

	@State private var viewSettingsStore = ViewSettingsStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
				.containerBackground(.thinMaterial, for: .window)
				.environment(viewSettingsStore)
        }
		.windowStyle(.hiddenTitleBar)
        .modelContainer(sharedModelContainer)

		Settings {
			SettingsView()
				.environment(viewSettingsStore)
		}
    }
}
