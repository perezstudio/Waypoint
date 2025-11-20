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
        // ⚠️ DATABASE RESET CODE - COMMENTED OUT TO PREVENT DATA LOSS
        // Uncomment this section ONLY if you need to completely reset the database
        // WARNING: This will delete ALL user data!
        /*
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!

        // Delete all SwiftData files (main store + auxiliary files)
        let filesToDelete = ["default.store", "default.store-shm", "default.store-wal"]
        for filename in filesToDelete {
            let fileURL = appSupportURL.appendingPathComponent(filename)
            if fileManager.fileExists(atPath: fileURL.path) {
                try? fileManager.removeItem(at: fileURL)
                print("🗑️ Reset database: Deleted \(filename) for fresh V1 schema")
            }
        }
        */

        do {
            // Use migration plan to handle schema changes
            // V1 uses the current models - when creating V2, current models move there
            return try ModelContainer(
                for: Project.self,
                Issue.self,
                ContentBlock.self,
                Tag.self,
                Space.self,
                Resource.self,
                ProjectUpdate.self,
                Milestone.self,
                ProjectIssuesViewSettings.self,
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
