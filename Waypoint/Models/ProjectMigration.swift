//
//  ProjectMigration.swift
//  Waypoint
//
//  Migration Plan for SwiftData Schema Changes
//  Created on 11/19/25 - Reset to V1 baseline
//

import Foundation
import SwiftData

// MARK: - Schema V1 (Baseline - All current models with Issue-ContentBlock relationship)

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Project.self,
            Issue.self,
            ContentBlock.self,
            Tag.self,
            Space.self,
            Resource.self,
            ProjectUpdate.self,
            Milestone.self,
            ProjectIssuesViewSettings.self
        ]
    }

    // Note: V1 uses the current, unversioned models from Models/
    // When you create V2, you'll version the V1 models and V2 will use current models
}

// MARK: - Migration Plan

enum WaypointMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    static var stages: [MigrationStage] {
        // No migration stages yet - V1 is the baseline
        []
    }
}

/*
 ⚠️  IMPORTANT: SWIFTDATA MIGRATION GUIDE  ⚠️
 =============================================

 Before modifying ANY @Model class, read the complete migration guide:
 📄 .claude/swiftdata-migration-guide.md

 Quick Summary:
 - Latest schema uses CURRENT models (Project, Issue, etc.)
 - Historical schemas use VERSIONED models (ProjectV1, IssueV1, etc.)
 - When creating V2: freeze V1's models, then V2 uses current models

 =============================================

 When you need to modify the data model, follow these steps:

 1. CREATE A NEW SCHEMA VERSION
    - Copy the previous schema version (e.g., SchemaV1) to a new version (e.g., SchemaV2)
    - ALL models must be versioned - never share model classes between schemas
    - Update the versionIdentifier to the next version number

 2. MAKE YOUR CHANGES IN THE NEW SCHEMA
    - Modify the models as needed in the new schema version
    - For property renames, use @Attribute(originalName: "oldName")
    - For type changes, you'll need a custom migration

 3. UPDATE THE MIGRATION PLAN
    - Add the new schema to the schemas array
    - Create a migration stage (lightweight or custom)
    - Add the stage to the stages array

 4. EXAMPLE: Adding a new property to Issue

    STEP A: First, version the V1 models (freeze them)

    enum SchemaV1: VersionedSchema {
        static var versionIdentifier = Schema.Version(1, 0, 0)

        static var models: [any PersistentModel.Type] {
            [ProjectV1.self, IssueV1.self, ...]  // Now versioned
        }

        // Copy all current models and add V1 suffix
        @Model
        final class IssueV1 {
            // Copy EXACTLY from Models/Issue.swift
        }

        // ... all other V1 models ...
    }

    STEP B: Create V2 using current models

    enum SchemaV2: VersionedSchema {
        static var versionIdentifier = Schema.Version(2, 0, 0)

        static var models: [any PersistentModel.Type] {
            [Project.self, Issue.self, ...]  // Current models (no suffix)
        }

        // No model definitions here - uses Models/ directory
    }

    STEP C: Make changes in Models/Issue.swift

    // In Models/Issue.swift
    @Model
    final class Issue {
        // ... existing properties ...
        var estimatedHours: Int? = nil  // NEW PROPERTY (optional for safety)
    }

    STEP D: Update migration plan

    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]  // Add new schema
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )

 5. LIGHTWEIGHT VS CUSTOM MIGRATIONS

    Use LIGHTWEIGHT for:
    - Adding optional properties
    - Removing properties
    - Renaming properties (with @Attribute(originalName:))
    - Adding new entities

    Use CUSTOM for:
    - Changing property types
    - Making optional properties required
    - Complex data transformations
    - Setting default values for new required properties

    Example custom migration:

    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: { context in
            // Runs before migration
        },
        didMigrate: { context in
            // Runs after migration - set defaults, transform data, etc.
            let descriptor = FetchDescriptor<SchemaV2.IssueV2>()
            let issues = try context.fetch(descriptor)
            for issue in issues {
                // Set default values for new properties
                issue.estimatedHours = 0
            }
            try context.save()
        }
    )

 6. TESTING
    - Always test migrations with real data
    - Never skip schema versions in the migration path
    - Keep old schema definitions - they're needed for migration

 7. IMPORTANT RULES
    - NEVER modify an existing schema version once it's released
    - NEVER delete old schema versions - they're part of the migration history
    - LATEST schema uses CURRENT models (Project, Issue, etc.)
    - HISTORICAL schemas use VERSIONED models (ProjectV1, IssueV1, etc.)
    - When creating V2, first freeze V1's models, then V2 uses current models
    - ALWAYS test migrations before releasing
    - ALWAYS use optional properties for new fields when possible

 8. PATTERN SUMMARY
    - V1: Uses current models (Project, Issue, Space, etc.)
    - When adding V2:
      1. Add V1 suffix to all models IN SchemaV1 (ProjectV1, IssueV1, etc.)
      2. Create SchemaV2 using current models (Project, Issue, etc.)
      3. Make your changes in Models/ directory (Models/Issue.swift, etc.)
      4. V2 automatically picks up the changes
 */
