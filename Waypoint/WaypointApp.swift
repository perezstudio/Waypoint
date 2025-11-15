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
        // TEMPORARY: Delete the database to test fresh user flows
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!

        // Delete all SwiftData files (main store + auxiliary files)
        let filesToDelete = ["default.store", "default.store-shm", "default.store-wal"]
        for filename in filesToDelete {
            let fileURL = appSupportURL.appendingPathComponent(filename)
            if fileManager.fileExists(atPath: fileURL.path) {
                try? fileManager.removeItem(at: fileURL)
                print("🗑️ TEMPORARY: Deleted \(filename)")
            }
        }

        do {
            // Use migration plan to handle schema changes
            return try ModelContainer(
                for: Project.self, Issue.self, Item.self, Tag.self, Space.self, Resource.self, ProjectUpdate.self, Milestone.self, ContentBlock.self,
                migrationPlan: WaypointMigrationPlan.self
            )
        } catch {
            print("Failed to create ModelContainer with migration: \(error)")
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
