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
        // TEMPORARY: Delete database if migration fails (remove after first successful run)
        let shouldResetDatabase = true  // Set to false after first successful run

        if shouldResetDatabase {
            // Get the default database URL for SwiftData
            if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let storeURL = appSupport.appendingPathComponent("default.store")
                print("🗑️ Attempting to delete database at: \(storeURL.path)")

                // Delete the main database file and its associated files
                try? FileManager.default.removeItem(at: storeURL)
                try? FileManager.default.removeItem(at: URL(fileURLWithPath: storeURL.path + "-shm"))
                try? FileManager.default.removeItem(at: URL(fileURLWithPath: storeURL.path + "-wal"))

                print("✅ Database files deleted (if they existed)")
            }
        }

        do {
            // Use migration plan to handle schema changes
            return try ModelContainer(
                for: Project.self, Issue.self, Item.self, Tag.self, Space.self, Resource.self, ProjectUpdate.self, Milestone.self, ContentBlock.self,
                migrationPlan: WaypointMigrationPlan.self
            )
        } catch {
            print("❌ Failed to create ModelContainer with migration: \(error)")
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
