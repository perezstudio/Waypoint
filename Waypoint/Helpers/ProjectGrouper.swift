//
//  ProjectGrouper.swift
//  Waypoint
//
//  Created by Claude on 11/13/25.
//

import Foundation

struct ProjectGroup: Identifiable {
    let id: String
    let title: String
    let projects: [Project]
    let order: Int
}

struct ProjectGrouper {
    static func group(_ projects: [Project], by grouping: ProjectGrouping) -> [ProjectGroup] {
        switch grouping {
        case .status:
            return groupByStatus(projects)
        case .space:
            return groupBySpace(projects)
        case .issueCount:
            return groupByIssueCount(projects)
        case .createdDate:
            return groupByCreatedDate(projects)
        case .none:
            return groupByNone(projects)
        }
    }

    private static func groupByStatus(_ projects: [Project]) -> [ProjectGroup] {
        // Create ALL status groups, even if empty (matching IssueGrouper behavior)
        let statusOrder: [Status] = [.todo, .inProgress, .review, .done]
        var groups: [ProjectGroup] = []

        for (index, status) in statusOrder.enumerated() {
            let statusProjects = projects.filter { $0.status == status }
            let title: String = {
                switch status {
                case .todo: return "To Do"
                case .inProgress: return "In Progress"
                case .review: return "Review"
                case .done: return "Done"
                }
            }()
            groups.append(ProjectGroup(
                id: status.rawValue,
                title: title,
                projects: statusProjects,
                order: index
            ))
        }

        return groups
    }

    private static func groupBySpace(_ projects: [Project]) -> [ProjectGroup] {
        // Group projects by their space
        let grouped = Dictionary(grouping: projects) { project -> String in
            project.space?.name ?? "No Space"
        }

        return grouped.map { (spaceName, projects) in
            ProjectGroup(
                id: spaceName.lowercased().replacingOccurrences(of: " ", with: "_"),
                title: spaceName,
                projects: projects,
                order: spaceName == "No Space" ? Int.max : 0
            )
        }.sorted { group1, group2 in
            if group1.order != group2.order {
                return group1.order < group2.order
            }
            return group1.title < group2.title
        }
    }

    private static func groupByIssueCount(_ projects: [Project]) -> [ProjectGroup] {
        // Group projects by number of issues
        let grouped = Dictionary(grouping: projects) { project -> String in
            let count = project.issues.count
            if count == 0 {
                return "No Issues"
            } else if count <= 5 {
                return "1-5 Issues"
            } else if count <= 10 {
                return "6-10 Issues"
            } else {
                return "10+ Issues"
            }
        }

        let orderMap: [String: Int] = [
            "No Issues": 0,
            "1-5 Issues": 1,
            "6-10 Issues": 2,
            "10+ Issues": 3
        ]

        return grouped.map { (countRange, projects) in
            ProjectGroup(
                id: countRange.lowercased().replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "-", with: "_"),
                title: countRange,
                projects: projects,
                order: orderMap[countRange] ?? 0
            )
        }.sorted { $0.order < $1.order }
    }

    private static func groupByCreatedDate(_ projects: [Project]) -> [ProjectGroup] {
        let calendar = Calendar.current
        let now = Date()

        // Group projects by creation date
        let grouped = Dictionary(grouping: projects) { project -> String in
            let components = calendar.dateComponents([.day], from: project.createdAt, to: now)
            let days = components.day ?? 0

            if days <= 7 {
                return "This Week"
            } else if days <= 30 {
                return "This Month"
            } else {
                return "Older"
            }
        }

        let orderMap: [String: Int] = [
            "This Week": 0,
            "This Month": 1,
            "Older": 2
        ]

        return grouped.map { (dateRange, projects) in
            ProjectGroup(
                id: dateRange.lowercased().replacingOccurrences(of: " ", with: "_"),
                title: dateRange,
                projects: projects,
                order: orderMap[dateRange] ?? 0
            )
        }.sorted { $0.order < $1.order }
    }

    private static func groupByNone(_ projects: [Project]) -> [ProjectGroup] {
        // Return all projects in a single group
        return [
            ProjectGroup(
                id: "all",
                title: "All Projects",
                projects: projects,
                order: 0
            )
        ]
    }
}
