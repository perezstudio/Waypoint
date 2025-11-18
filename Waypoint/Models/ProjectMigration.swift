//
//  ProjectMigration.swift
//  Waypoint
//
//  Created by Claude on 11/13/25.
//

import Foundation
import SwiftData

// MARK: - Schema V1 (Before adding Project status field)

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [ProjectV1.self, IssueV1.self, Item.self, Tag.self, Space.self]
    }

    @Model
    final class ProjectV1 {
        var id: UUID
        var name: String
        var icon: String
        var color: String
        // No status field in V1
        var createdAt: Date
        var updatedAt: Date

        @Relationship(deleteRule: .cascade, inverse: \IssueV1.project)
        var issues: [IssueV1] = []

        var space: Space?

        init(name: String, icon: String = "folder.fill", color: String = "#007AFF", space: Space? = nil) {
            self.id = UUID()
            self.name = name
            self.icon = icon
            self.color = color
            self.createdAt = Date()
            self.updatedAt = Date()
            self.space = space
        }
    }

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

        var project: ProjectV1?

        @Relationship(deleteRule: .nullify, inverse: \Tag.issues)
        var tags: [Tag] = []

        init(title: String, status: Status = .todo, priority: IssuePriority = .medium, project: ProjectV1? = nil) {
            self.id = UUID()
            self.title = title
            self.status = status
            self.priority = priority
            self.createdAt = Date()
            self.updatedAt = Date()
            self.project = project
        }
    }
}

// MARK: - Schema V2 (After adding Project status field)

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [ProjectV2.self, Issue.self, Item.self, Tag.self, Space.self]
    }

    @Model
    final class ProjectV2 {
        var id: UUID
        var name: String
        var icon: String
        var color: String
        var status: Status
        var createdAt: Date
        var updatedAt: Date

        @Relationship(deleteRule: .cascade, inverse: \Issue.project)
        var issues: [Issue] = []

        var space: Space?

        init(name: String, icon: String = "folder.fill", color: String = "#007AFF", status: Status = .inProgress, space: Space? = nil) {
            self.id = UUID()
            self.name = name
            self.icon = icon
            self.color = color
            self.status = status
            self.createdAt = Date()
            self.updatedAt = Date()
            self.space = space
        }
    }
}

// MARK: - Schema V3 (After adding Resources, Updates, Milestones)

enum SchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        [ProjectV3.self, Issue.self, Item.self, Tag.self, Space.self, Resource.self, ProjectUpdate.self, Milestone.self]
    }

    @Model
    final class ProjectV3 {
        var id: UUID
        var name: String
        var icon: String
        var color: String
        var status: Status
        var projectDescription: String?
        var createdAt: Date
        var updatedAt: Date

        @Relationship(deleteRule: .cascade, inverse: \Issue.project)
        var issues: [Issue] = []

        @Relationship(deleteRule: .cascade, inverse: \Resource.project)
        var resources: [Resource] = []

        @Relationship(deleteRule: .cascade, inverse: \ProjectUpdate.project)
        var updates: [ProjectUpdate] = []

        @Relationship(deleteRule: .cascade, inverse: \Milestone.project)
        var milestones: [Milestone] = []

        var space: Space?

        init(name: String, icon: String = "folder.fill", color: String = "#007AFF", status: Status = .inProgress, space: Space? = nil) {
            self.id = UUID()
            self.name = name
            self.icon = icon
            self.color = color
            self.status = status
            self.createdAt = Date()
            self.updatedAt = Date()
            self.space = space
        }
    }
}

// MARK: - Schema V4 (After adding ContentBlock for block editor - WITHOUT indentLevel)

enum SchemaV4: VersionedSchema {
    static var versionIdentifier = Schema.Version(4, 0, 0)

    static var models: [any PersistentModel.Type] {
        [ProjectV4.self, IssueV4.self, Item.self, Tag.self, Space.self, Resource.self, ProjectUpdate.self, Milestone.self, ContentBlockV4.self]
    }

    @Model
    final class ProjectV4 {
        var id: UUID
        var name: String
        var icon: String
        var color: String
        var status: Status
        var projectDescription: String?
        var createdAt: Date
        var updatedAt: Date

        @Relationship(deleteRule: .cascade, inverse: \IssueV4.project)
        var issues: [IssueV4] = []

        @Relationship(deleteRule: .cascade, inverse: \Resource.project)
        var resources: [Resource] = []

        @Relationship(deleteRule: .cascade, inverse: \ProjectUpdate.project)
        var updates: [ProjectUpdate] = []

        @Relationship(deleteRule: .cascade, inverse: \Milestone.project)
        var milestones: [Milestone] = []

        @Relationship(deleteRule: .cascade, inverse: \ContentBlockV4.project)
        var contentBlocks: [ContentBlockV4] = []

        var space: Space?

        init(name: String, icon: String = "folder.fill", color: String = "#007AFF", status: Status = .inProgress, space: Space? = nil) {
            self.id = UUID()
            self.name = name
            self.icon = icon
            self.color = color
            self.status = status
            self.createdAt = Date()
            self.updatedAt = Date()
            self.space = space
        }
    }

    @Model
    final class IssueV4 {
        var id: UUID
        var title: String
        var issueDescription: String?
        var status: Status
        var priority: IssuePriority
        var createdAt: Date
        var updatedAt: Date
        var dueDate: Date?

        var project: ProjectV4?

        @Relationship(deleteRule: .nullify, inverse: \Tag.issues)
        var tags: [Tag] = []

        init(title: String, status: Status = .todo, priority: IssuePriority = .medium, project: ProjectV4? = nil) {
            self.id = UUID()
            self.title = title
            self.status = status
            self.priority = priority
            self.createdAt = Date()
            self.updatedAt = Date()
            self.project = project
        }
    }

    @Model
    final class ContentBlockV4 {
        var id: UUID
        var type: BlockType
        var content: String
        var order: Int
        // No indentLevel in V4
        var createdAt: Date
        var updatedAt: Date

        var project: ProjectV4?

        init(type: BlockType = .paragraph, content: String = "", order: Int = 0, project: ProjectV4? = nil) {
            self.id = UUID()
            self.type = type
            self.content = content
            self.order = order
            self.createdAt = Date()
            self.updatedAt = Date()
            self.project = project
        }
    }
}

// MARK: - Schema V5 (After adding indentLevel to ContentBlock)

enum SchemaV5: VersionedSchema {
    static var versionIdentifier = Schema.Version(5, 0, 0)

    static var models: [any PersistentModel.Type] {
        [ProjectV5.self, Issue.self, Item.self, TagV5.self, SpaceV5.self, Resource.self, ProjectUpdate.self, Milestone.self, ContentBlock.self]
    }

    @Model
    final class SpaceV5 {
        var id: UUID
        var name: String
        var spaceDescription: String?
        var icon: String
        var color: String
        var createdAt: Date
        // No sort field in V5

        @Relationship(deleteRule: .nullify, inverse: \ProjectV5.space)
        var projects: [ProjectV5] = []

        @Relationship(deleteRule: .nullify, inverse: \TagV5.space)
        var tags: [TagV5] = []

        init(name: String, spaceDescription: String? = nil, icon: String = "person.3.fill", color: String = "#007AFF") {
            self.id = UUID()
            self.name = name
            self.spaceDescription = spaceDescription
            self.icon = icon
            self.color = color
            self.createdAt = Date()
        }
    }

    @Model
    final class ProjectV5 {
        var id: UUID
        var name: String
        var icon: String
        var color: String
        var status: Status
        var projectDescription: String?
        var createdAt: Date
        var updatedAt: Date

        @Relationship(deleteRule: .cascade, inverse: \Issue.project)
        var issues: [Issue] = []

        @Relationship(deleteRule: .cascade, inverse: \Resource.project)
        var resources: [Resource] = []

        @Relationship(deleteRule: .cascade, inverse: \ProjectUpdate.project)
        var updates: [ProjectUpdate] = []

        @Relationship(deleteRule: .cascade, inverse: \Milestone.project)
        var milestones: [Milestone] = []

        @Relationship(deleteRule: .cascade, inverse: \ContentBlock.project)
        var contentBlocks: [ContentBlock] = []

        var space: SpaceV5?

        init(name: String, icon: String = "folder.fill", color: String = "#007AFF", status: Status = .inProgress, space: SpaceV5? = nil) {
            self.id = UUID()
            self.name = name
            self.icon = icon
            self.color = color
            self.status = status
            self.createdAt = Date()
            self.updatedAt = Date()
            self.space = space
        }
    }

    @Model
    final class TagV5 {
        var id: UUID
        var name: String
        var color: String
        var createdAt: Date

        @Relationship(deleteRule: .nullify, inverse: \Issue.tags)
        var issues: [Issue] = []

        var space: SpaceV5?

        init(name: String, color: String = "#007AFF", space: SpaceV5? = nil) {
            self.id = UUID()
            self.name = name
            self.color = color
            self.createdAt = Date()
            self.space = space
        }
    }
}

// MARK: - Schema V6 (After adding sort field to Space)

enum SchemaV6: VersionedSchema {
    static var versionIdentifier = Schema.Version(6, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Project.self, Issue.self, Item.self, Tag.self, Space.self, Resource.self, ProjectUpdate.self, Milestone.self, ContentBlock.self]
    }
}

// MARK: - Migration Plan

enum WaypointMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self, SchemaV3.self, SchemaV4.self, SchemaV5.self, SchemaV6.self]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )

    /*
    // Custom migration - commented out due to compilation issues
    static let migrateV1toV2OLD = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: { context in
            // Fetch all V1 data
            let projectsDescriptor = FetchDescriptor<SchemaV1.ProjectV1>()
            let v1Projects = try context.fetch(projectsDescriptor)

            let issuesDescriptor = FetchDescriptor<SchemaV1.IssueV1>()
            let v1Issues = try context.fetch(issuesDescriptor)

            print("📦 Starting migration of \(v1Projects.count) projects and \(v1Issues.count) issues from V1 to V2")

            // Store project data before deletion
            var projectData: [(id: UUID, name: String, icon: String, color: String, createdAt: Date, updatedAt: Date, spaceID: UUID?)] = []
            for oldProject in v1Projects {
                projectData.append((
                    id: oldProject.id,
                    name: oldProject.name,
                    icon: oldProject.icon,
                    color: oldProject.color,
                    createdAt: oldProject.createdAt,
                    updatedAt: oldProject.updatedAt,
                    spaceID: oldProject.space?.id
                ))
            }

            // Store issue data before deletion
            var issueData: [(id: UUID, title: String, description: String?, status: Status, priority: IssuePriority, createdAt: Date, updatedAt: Date, dueDate: Date?, projectID: UUID?)] = []
            for oldIssue in v1Issues {
                issueData.append((
                    id: oldIssue.id,
                    title: oldIssue.title,
                    description: oldIssue.issueDescription,
                    status: oldIssue.status,
                    priority: oldIssue.priority,
                    createdAt: oldIssue.createdAt,
                    updatedAt: oldIssue.updatedAt,
                    dueDate: oldIssue.dueDate,
                    projectID: oldIssue.project?.id
                ))
            }

            // Delete old entities
            for oldProject in v1Projects {
                context.delete(oldProject)
            }
            for oldIssue in v1Issues {
                context.delete(oldIssue)
            }

            try context.save()

            // Create new V2 entities with the stored data
            // First, get spaces
            let spacesDescriptor = FetchDescriptor<Space>()
            let spaces = try context.fetch(spacesDescriptor)
            let spaceMap = Dictionary(uniqueKeysWithValues: spaces.map { ($0.id, $0) })

            // Create new projects with status field
            var projectMap: [UUID: SchemaV2.ProjectV2] = [:]
            for data in projectData {
                let newProject = SchemaV2.ProjectV2(
                    name: data.name,
                    icon: data.icon,
                    color: data.color,
                    status: .inProgress,  // Default status for migrated projects
                    space: data.spaceID != nil ? spaceMap[data.spaceID!] : nil
                )
                // Preserve original ID, dates
                newProject.id = data.id
                newProject.createdAt = data.createdAt
                newProject.updatedAt = data.updatedAt

                context.insert(newProject)
                projectMap[newProject.id] = newProject
                print("  ✓ Migrated project: \(newProject.name) → status: \(newProject.status.rawValue)")
            }

            // Create new issues
            for data in issueData {
                let newIssue = Issue(
                    title: data.title,
                    status: data.status,
                    priority: data.priority,
                    project: data.projectID != nil ? projectMap[data.projectID!] : nil
                )
                // Preserve original data
                newIssue.id = data.id
                newIssue.issueDescription = data.description
                newIssue.createdAt = data.createdAt
                newIssue.updatedAt = data.updatedAt
                newIssue.dueDate = data.dueDate

                context.insert(newIssue)
            }

            try context.save()
            print("✅ Migration complete: Created \(projectData.count) projects and \(issueData.count) issues")
        },
        didMigrate: nil
    )
    */

    static let migrateV2toV3 = MigrationStage.lightweight(
        fromVersion: SchemaV2.self,
        toVersion: SchemaV3.self
    )

    static let migrateV3toV4 = MigrationStage.lightweight(
        fromVersion: SchemaV3.self,
        toVersion: SchemaV4.self
    )

    static let migrateV4toV5 = MigrationStage.lightweight(
        fromVersion: SchemaV4.self,
        toVersion: SchemaV5.self
    )

    static let migrateV5toV6 = MigrationStage.custom(
        fromVersion: SchemaV5.self,
        toVersion: SchemaV6.self,
        willMigrate: { context in
            // Fetch all V5 data
            let spacesDescriptor = FetchDescriptor<SchemaV5.SpaceV5>(
                sortBy: [SortDescriptor(\.createdAt, order: .forward)]
            )
            let v5Spaces = try context.fetch(spacesDescriptor)

            let projectsDescriptor = FetchDescriptor<SchemaV5.ProjectV5>()
            let v5Projects = try context.fetch(projectsDescriptor)

            let tagsDescriptor = FetchDescriptor<SchemaV5.TagV5>()
            let v5Tags = try context.fetch(tagsDescriptor)

            print("📦 Migrating \(v5Spaces.count) spaces, \(v5Projects.count) projects, \(v5Tags.count) tags to V6")

            // Store space data
            var spacesData: [(id: UUID, name: String, description: String?, icon: String, color: String, createdAt: Date, sort: Int)] = []
            for (index, oldSpace) in v5Spaces.enumerated() {
                spacesData.append((
                    id: oldSpace.id,
                    name: oldSpace.name,
                    description: oldSpace.spaceDescription,
                    icon: oldSpace.icon,
                    color: oldSpace.color,
                    createdAt: oldSpace.createdAt,
                    sort: index  // Assign sort based on creation order
                ))
            }

            // Store project data
            var projectsData: [(id: UUID, name: String, icon: String, color: String, status: Status, description: String?, createdAt: Date, updatedAt: Date, spaceID: UUID?)] = []
            for oldProject in v5Projects {
                projectsData.append((
                    id: oldProject.id,
                    name: oldProject.name,
                    icon: oldProject.icon,
                    color: oldProject.color,
                    status: oldProject.status,
                    description: oldProject.projectDescription,
                    createdAt: oldProject.createdAt,
                    updatedAt: oldProject.updatedAt,
                    spaceID: oldProject.space?.id
                ))
            }

            // Store tag data
            var tagsData: [(id: UUID, name: String, color: String, createdAt: Date, spaceID: UUID?)] = []
            for oldTag in v5Tags {
                tagsData.append((
                    id: oldTag.id,
                    name: oldTag.name,
                    color: oldTag.color,
                    createdAt: oldTag.createdAt,
                    spaceID: oldTag.space?.id
                ))
            }

            // Delete old entities
            for oldSpace in v5Spaces { context.delete(oldSpace) }
            for oldProject in v5Projects { context.delete(oldProject) }
            for oldTag in v5Tags { context.delete(oldTag) }

            try context.save()

            // Create new V6 spaces with sort field
            var spaceMap: [UUID: Space] = [:]
            for data in spacesData {
                let newSpace = Space(
                    name: data.name,
                    spaceDescription: data.description,
                    icon: data.icon,
                    color: data.color,
                    sort: data.sort
                )
                newSpace.id = data.id
                newSpace.createdAt = data.createdAt

                context.insert(newSpace)
                spaceMap[newSpace.id] = newSpace
                print("  ✓ Migrated space: \(newSpace.name) → sort: \(newSpace.sort)")
            }

            // Create new V6 projects
            for data in projectsData {
                let newProject = Project(
                    name: data.name,
                    icon: data.icon,
                    color: data.color,
                    status: data.status,
                    space: data.spaceID != nil ? spaceMap[data.spaceID!] : nil
                )
                newProject.id = data.id
                newProject.projectDescription = data.description
                newProject.createdAt = data.createdAt
                newProject.updatedAt = data.updatedAt

                context.insert(newProject)
            }

            // Create new V6 tags
            for data in tagsData {
                let newTag = Tag(
                    name: data.name,
                    color: data.color,
                    space: data.spaceID != nil ? spaceMap[data.spaceID!] : nil
                )
                newTag.id = data.id
                newTag.createdAt = data.createdAt

                context.insert(newTag)
            }

            try context.save()
            print("✅ Migration complete: \(spacesData.count) spaces, \(projectsData.count) projects, \(tagsData.count) tags")
        },
        didMigrate: nil
    )

    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3, migrateV3toV4, migrateV4toV5, migrateV5toV6]
    }
}
