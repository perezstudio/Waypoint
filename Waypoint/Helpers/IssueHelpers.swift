//
//  IssueHelpers.swift
//  Waypoint
//

import Foundation

// MARK: - IssueGroup

struct IssueGroup: Identifiable {
    let id: String
    let title: String
    let issues: [Issue]
    let order: Int // For maintaining consistent ordering

    init(id: String, title: String, issues: [Issue], order: Int = 0) {
        self.id = id
        self.title = title
        self.issues = issues
        self.order = order
    }
}

// MARK: - IssueGrouper

struct IssueGrouper {
    static func group(_ issues: [Issue], by grouping: IssueGrouping) -> [IssueGroup] {
        switch grouping {
        case .status:
            return groupByStatus(issues)
        case .priority:
            return groupByPriority(issues)
        case .project:
            return groupByProject(issues)
        case .dueDate:
            return groupByDueDate(issues)
        case .tags:
            return groupByTags(issues)
        case .none:
            return [IssueGroup(id: "all", title: "All Issues", issues: issues)]
        }
    }

    private static func groupByStatus(_ issues: [Issue]) -> [IssueGroup] {
        let statusOrder: [IssueStatus] = [.todo, .inProgress, .review, .done]
        var groups: [IssueGroup] = []

        for (index, status) in statusOrder.enumerated() {
            let statusIssues = issues.filter { $0.status == status }
            let title: String = {
                switch status {
                case .todo: return "To Do"
                case .inProgress: return "In Progress"
                case .review: return "Review"
                case .done: return "Done"
                }
            }()
            groups.append(IssueGroup(
                id: status.rawValue,
                title: title,
                issues: statusIssues,
                order: index
            ))
        }

        return groups
    }

    private static func groupByPriority(_ issues: [Issue]) -> [IssueGroup] {
        let priorityOrder: [IssuePriority] = [.urgent, .high, .medium, .low]
        var groups: [IssueGroup] = []

        for (index, priority) in priorityOrder.enumerated() {
            let priorityIssues = issues.filter { $0.priority == priority }
            let title: String = {
                switch priority {
                case .urgent: return "Urgent"
                case .high: return "High"
                case .medium: return "Medium"
                case .low: return "Low"
                }
            }()
            groups.append(IssueGroup(
                id: priority.rawValue,
                title: title,
                issues: priorityIssues,
                order: index
            ))
        }

        return groups
    }

    private static func groupByProject(_ issues: [Issue]) -> [IssueGroup] {
        let grouped = Dictionary(grouping: issues) { issue -> String in
            issue.project?.id.uuidString ?? "no-project"
        }

        var groups: [IssueGroup] = []
        var order = 0

        // First add "No Project" group if it exists
        if let noProjectIssues = grouped["no-project"] {
            groups.append(IssueGroup(
                id: "no-project",
                title: "No Project",
                issues: noProjectIssues,
                order: order
            ))
            order += 1
        }

        // Then add all other projects sorted by name
        let projectGroups = grouped
            .filter { $0.key != "no-project" }
            .compactMap { (key, issues) -> IssueGroup? in
                guard let projectName = issues.first?.project?.name else { return nil }
                return IssueGroup(
                    id: key,
                    title: projectName,
                    issues: issues,
                    order: 0 // Will be reassigned
                )
            }
            .sorted { $0.title < $1.title }

        for group in projectGroups {
            groups.append(IssueGroup(
                id: group.id,
                title: group.title,
                issues: group.issues,
                order: order
            ))
            order += 1
        }

        return groups
    }

    private static func groupByDueDate(_ issues: [Issue]) -> [IssueGroup] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: today)!

        var overdue: [Issue] = []
        var todayIssues: [Issue] = []
        var tomorrowIssues: [Issue] = []
        var thisWeek: [Issue] = []
        var later: [Issue] = []
        var noDueDate: [Issue] = []

        for issue in issues {
            guard let dueDate = issue.dueDate else {
                noDueDate.append(issue)
                continue
            }

            let dueDateStart = calendar.startOfDay(for: dueDate)

            if dueDateStart < today {
                overdue.append(issue)
            } else if dueDateStart == today {
                todayIssues.append(issue)
            } else if dueDateStart == calendar.startOfDay(for: tomorrow) {
                tomorrowIssues.append(issue)
            } else if dueDateStart < nextWeek {
                thisWeek.append(issue)
            } else {
                later.append(issue)
            }
        }

        var groups: [IssueGroup] = []
        var order = 0

        if !overdue.isEmpty {
            groups.append(IssueGroup(id: "overdue", title: "Overdue", issues: overdue, order: order))
            order += 1
        }
        if !todayIssues.isEmpty {
            groups.append(IssueGroup(id: "today", title: "Today", issues: todayIssues, order: order))
            order += 1
        }
        if !tomorrowIssues.isEmpty {
            groups.append(IssueGroup(id: "tomorrow", title: "Tomorrow", issues: tomorrowIssues, order: order))
            order += 1
        }
        if !thisWeek.isEmpty {
            groups.append(IssueGroup(id: "this-week", title: "This Week", issues: thisWeek, order: order))
            order += 1
        }
        if !later.isEmpty {
            groups.append(IssueGroup(id: "later", title: "Later", issues: later, order: order))
            order += 1
        }
        if !noDueDate.isEmpty {
            groups.append(IssueGroup(id: "no-due-date", title: "No Due Date", issues: noDueDate, order: order))
        }

        return groups
    }

    private static func groupByTags(_ issues: [Issue]) -> [IssueGroup] {
        var tagGroups: [String: [Issue]] = [:]
        var noTagsIssues: [Issue] = []

        for issue in issues {
            if issue.tags.isEmpty {
                noTagsIssues.append(issue)
            } else {
                for tag in issue.tags {
                    let tagId = tag.id.uuidString
                    tagGroups[tagId, default: []].append(issue)
                }
            }
        }

        var groups: [IssueGroup] = []
        var order = 0

        // Add tagged groups sorted by tag name
        let sortedTagGroups = tagGroups.sorted { group1, group2 in
            let tag1Name = group1.value.first?.tags.first(where: { $0.id.uuidString == group1.key })?.name ?? ""
            let tag2Name = group2.value.first?.tags.first(where: { $0.id.uuidString == group2.key })?.name ?? ""
            return tag1Name < tag2Name
        }

        for (tagId, tagIssues) in sortedTagGroups {
            if let tagName = tagIssues.first?.tags.first(where: { $0.id.uuidString == tagId })?.name {
                groups.append(IssueGroup(
                    id: tagId,
                    title: tagName,
                    issues: tagIssues,
                    order: order
                ))
                order += 1
            }
        }

        // Add "No Tags" group if exists
        if !noTagsIssues.isEmpty {
            groups.append(IssueGroup(
                id: "no-tags",
                title: "No Tags",
                issues: noTagsIssues,
                order: order
            ))
        }

        return groups
    }
}

// MARK: - IssueSorter

struct IssueSorter {
    static func sort(_ issues: [Issue], by sorting: IssueSorting, direction: SortDirection) -> [Issue] {
        let sorted: [Issue]

        switch sorting {
        case .dueDate:
            sorted = issues.sorted { issue1, issue2 in
                // Issues without due dates go to the end
                guard let date1 = issue1.dueDate else { return false }
                guard let date2 = issue2.dueDate else { return true }
                return date1 < date2
            }
        case .priority:
            let priorityOrder: [IssuePriority] = [.urgent, .high, .medium, .low]
            sorted = issues.sorted { issue1, issue2 in
                let index1 = priorityOrder.firstIndex(of: issue1.priority) ?? priorityOrder.count
                let index2 = priorityOrder.firstIndex(of: issue2.priority) ?? priorityOrder.count
                return index1 < index2
            }
        case .status:
            let statusOrder: [IssueStatus] = [.todo, .inProgress, .review, .done]
            sorted = issues.sorted { issue1, issue2 in
                let index1 = statusOrder.firstIndex(of: issue1.status) ?? statusOrder.count
                let index2 = statusOrder.firstIndex(of: issue2.status) ?? statusOrder.count
                return index1 < index2
            }
        case .createdAt:
            sorted = issues.sorted { $0.createdAt < $1.createdAt }
        case .title:
            sorted = issues.sorted { $0.title.lowercased() < $1.title.lowercased() }
        }

        return direction == .ascending ? sorted : sorted.reversed()
    }
}
