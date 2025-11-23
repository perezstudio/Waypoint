//
//  ProjectMigration.swift
//  Waypoint
//
//  Migration Plan for SwiftData Schema Changes
//  Created on 11/19/25 - Reset to V1 baseline
//

import Foundation
import SwiftData

// MARK: - Schema V1 (Baseline - Frozen state WITHOUT completedDate)

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            ProjectV1.self,
            IssueV1.self,
            ContentBlockV1.self,
            TagV1.self,
            SpaceV1.self,
            ResourceV1.self,
            ProjectUpdateV1.self,
            MilestoneV1.self,
            ProjectIssuesViewSettingsV1.self
        ]
    }

    // MARK: - Enums

    enum Status: String, Codable {
        case todo
        case inProgress
        case review
        case done
    }

    enum IssuePriority: String, Codable {
        case low
        case medium
        case high
        case urgent
    }

    enum BlockType: String, Codable {
        case heading1 = "heading1"
        case heading2 = "heading2"
        case heading3 = "heading3"
        case paragraph = "paragraph"
        case bulletList = "bulletList"
        case numberedList = "numberedList"
        case code = "code"
        case image = "image"

        var displayName: String {
            switch self {
            case .heading1: return "Heading 1"
            case .heading2: return "Heading 2"
            case .heading3: return "Heading 3"
            case .paragraph: return "Text"
            case .bulletList: return "Bulleted List"
            case .numberedList: return "Numbered List"
            case .code: return "Code"
            case .image: return "Image"
            }
        }

        var icon: String {
            switch self {
            case .heading1: return "textformat.size.larger"
            case .heading2: return "textformat.size"
            case .heading3: return "textformat.size.smaller"
            case .paragraph: return "text.alignleft"
            case .bulletList: return "list.bullet"
            case .numberedList: return "list.number"
            case .code: return "curlybraces"
            case .image: return "photo"
            }
        }
    }

    enum ResourceType: String, Codable {
        case link = "Link"
        case file = "File"
    }

    enum IssuesViewMode: String, CaseIterable, Codable {
        case list = "List"
        case board = "Board"
    }

    enum IssueGrouping: String, CaseIterable, Codable {
        case status = "Status"
        case priority = "Priority"
        case project = "Project"
        case dueDate = "Due Date"
        case tags = "Tags"
        case none = "None"

        var icon: String {
            switch self {
            case .status: return "checkmark.circle"
            case .priority: return "exclamationmark.triangle"
            case .project: return "folder"
            case .dueDate: return "calendar"
            case .tags: return "tag"
            case .none: return "list.bullet"
            }
        }
    }

    enum IssueSorting: String, CaseIterable, Codable {
        case dueDate = "Due Date"
        case priority = "Priority"
        case status = "Status"
        case createdAt = "Created"
        case title = "Title"

        var icon: String {
            switch self {
            case .dueDate: return "calendar"
            case .priority: return "exclamationmark.triangle"
            case .status: return "checkmark.circle"
            case .createdAt: return "clock"
            case .title: return "textformat"
            }
        }
    }

    enum SortDirection: String, CaseIterable, Codable {
        case ascending = "Ascending"
        case descending = "Descending"

        var icon: String {
            switch self {
            case .ascending: return "arrow.up"
            case .descending: return "arrow.down"
            }
        }
    }

    // MARK: - Versioned Models (V1 - Baseline WITHOUT completedDate)

    @Model
    final class IssueV1 {
        var id: UUID
        var title: String
        var issueDescription: String?
        var status: Status
        var priority: IssuePriority
        var createdAt: Date
        var updatedAt: Date
        var dueDate: Date?
        var sortOrder: Double?

        var project: ProjectV1?
        var tags: [TagV1] = []

        @Relationship(deleteRule: .cascade, inverse: \ContentBlockV1.issue)
        var contentBlocks: [ContentBlockV1] = []

        init(title: String, status: Status = .todo, priority: IssuePriority = .medium, project: ProjectV1? = nil) {
            self.id = UUID()
            self.title = title
            self.status = status
            self.priority = priority
            self.createdAt = Date()
            self.updatedAt = Date()
            self.project = project
            self.sortOrder = Date().timeIntervalSince1970
        }

        var effectiveSortOrder: Double {
            sortOrder ?? createdAt.timeIntervalSince1970
        }
    }

    @Model
    final class ProjectV1 {
        var id: UUID
        var name: String
        var icon: String
        var color: String
        var status: Status
        var projectDescription: String?
        var createdAt: Date
        var updatedAt: Date
        var favorite: Bool = false
        var sortOrder: Double?

        @Relationship(deleteRule: .cascade, inverse: \IssueV1.project)
        var issues: [IssueV1] = []

        @Relationship(deleteRule: .cascade, inverse: \ResourceV1.project)
        var resources: [ResourceV1] = []

        @Relationship(deleteRule: .cascade, inverse: \ProjectUpdateV1.project)
        var updates: [ProjectUpdateV1] = []

        @Relationship(deleteRule: .cascade, inverse: \MilestoneV1.project)
        var milestones: [MilestoneV1] = []

        @Relationship(deleteRule: .cascade, inverse: \ContentBlockV1.project)
        var contentBlocks: [ContentBlockV1] = []

        @Relationship(deleteRule: .cascade, inverse: \ProjectIssuesViewSettingsV1.project)
        var viewSettings: ProjectIssuesViewSettingsV1?

        var space: SpaceV1?

        init(name: String, icon: String = "folder.fill", color: String = "#007AFF", status: Status = .inProgress, space: SpaceV1? = nil) {
            self.id = UUID()
            self.name = name
            self.icon = icon
            self.color = color
            self.status = status
            self.createdAt = Date()
            self.updatedAt = Date()
            self.favorite = false
            self.sortOrder = Date().timeIntervalSince1970
            self.space = space
            self.viewSettings = ProjectIssuesViewSettingsV1(project: nil)
        }

        var effectiveSortOrder: Double {
            sortOrder ?? createdAt.timeIntervalSince1970
        }
    }

    @Model
    final class ContentBlockV1 {
        var id: UUID
        var type: BlockType
        var content: String
        var order: Int
        var indentLevel: Int
        var createdAt: Date
        var updatedAt: Date

        var project: ProjectV1?
        var issue: IssueV1?

        init(type: BlockType = .paragraph, content: String = "", order: Int = 0, indentLevel: Int = 0, project: ProjectV1? = nil, issue: IssueV1? = nil) {
            self.id = UUID()
            self.type = type
            self.content = content
            self.order = order
            self.indentLevel = indentLevel
            self.createdAt = Date()
            self.updatedAt = Date()
            self.project = project
            self.issue = issue
        }
    }

    @Model
    final class TagV1 {
        var id: UUID
        var name: String
        var color: String
        var icon: String?
        var createdAt: Date
        var space: SpaceV1?

        @Relationship(inverse: \IssueV1.tags)
        var issues: [IssueV1] = []

        init(name: String, color: String, icon: String? = nil, space: SpaceV1? = nil) {
            self.id = UUID()
            self.name = name
            self.color = color
            self.icon = icon
            self.space = space
            self.createdAt = Date()
        }
    }

    @Model
    final class SpaceV1 {
        var id: UUID
        var name: String
        var spaceDescription: String?
        var icon: String
        var color: String
        var createdAt: Date
        var sort: Int

        @Relationship(deleteRule: .nullify, inverse: \ProjectV1.space)
        var projects: [ProjectV1] = []

        @Relationship(deleteRule: .nullify, inverse: \TagV1.space)
        var tags: [TagV1] = []

        init(name: String, spaceDescription: String? = nil, icon: String = "person.3.fill", color: String = "#007AFF", sort: Int = 0) {
            self.id = UUID()
            self.name = name
            self.spaceDescription = spaceDescription
            self.icon = icon
            self.color = color
            self.createdAt = Date()
            self.sort = sort
        }
    }

    @Model
    final class ResourceV1 {
        var id: UUID
        var title: String
        var url: String
        var type: ResourceType
        var createdAt: Date

        var project: ProjectV1?

        init(title: String, url: String, type: ResourceType = .link, project: ProjectV1? = nil) {
            self.id = UUID()
            self.title = title
            self.url = url
            self.type = type
            self.createdAt = Date()
            self.project = project
        }
    }

    @Model
    final class ProjectUpdateV1 {
        var id: UUID
        var content: String
        var author: String?
        var createdAt: Date

        var project: ProjectV1?

        init(content: String, author: String? = nil, project: ProjectV1? = nil) {
            self.id = UUID()
            self.content = content
            self.author = author
            self.createdAt = Date()
            self.project = project
        }
    }

    @Model
    final class MilestoneV1 {
        var id: UUID
        var title: String
        var milestoneDescription: String?
        var dueDate: Date?
        var isCompleted: Bool
        var completedAt: Date?
        var order: Int
        var createdAt: Date

        var project: ProjectV1?

        init(title: String, description: String? = nil, dueDate: Date? = nil, order: Int = 0, project: ProjectV1? = nil) {
            self.id = UUID()
            self.title = title
            self.milestoneDescription = description
            self.dueDate = dueDate
            self.isCompleted = false
            self.order = order
            self.createdAt = Date()
            self.project = project
        }
    }

    @Model
    final class ProjectIssuesViewSettingsV1 {
        var id: UUID
        var viewMode: IssuesViewMode
        var groupBy: IssueGrouping
        var sortBy: IssueSorting
        var sortDirection: SortDirection

        var project: ProjectV1?

        init(
            viewMode: IssuesViewMode = .list,
            groupBy: IssueGrouping = .status,
            sortBy: IssueSorting = .priority,
            sortDirection: SortDirection = .descending,
            project: ProjectV1? = nil
        ) {
            self.id = UUID()
            self.viewMode = viewMode
            self.groupBy = groupBy
            self.sortBy = sortBy
            self.sortDirection = sortDirection
            self.project = project
        }
    }
}

// MARK: - Schema V2 (Current - WITH completedDate)

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

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

    // V2 uses current models from Models/ directory
    // Issue model in Models/Issue.swift has completedDate field
}

// MARK: - Migration Plan

enum WaypointMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )
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
            let descriptor = FetchDescriptor<SchemaV2.IssueV1>()
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
