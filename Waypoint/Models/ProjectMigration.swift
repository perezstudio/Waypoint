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
        [Project.self, Issue.self, Item.self, Tag.self, Space.self]
    }
}

// MARK: - Migration Plan

enum WaypointMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    static let migrateV1toV2 = MigrationStage.custom(
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
            var projectMap: [UUID: Project] = [:]
            for data in projectData {
                let newProject = Project(
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
}
