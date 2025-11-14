//
//  ViewSettings.swift
//  Waypoint
//

import Foundation
import SwiftUI

// MARK: - Enums

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

enum ControlDisplayMode: String, CaseIterable, Codable {
    case iconOnly = "Icon Only"
    case iconAndText = "Icon & Text"
    case textOnly = "Text Only"
}

enum ProjectGrouping: String, CaseIterable, Codable {
    case status = "Status"
    case space = "Space"
    case issueCount = "Issue Count"
    case createdDate = "Created Date"
    case none = "None"

    var icon: String {
        switch self {
        case .status: return "checkmark.circle"
        case .space: return "square.stack.3d.up"
        case .issueCount: return "number.circle"
        case .createdDate: return "calendar"
        case .none: return "list.bullet"
        }
    }
}

enum ProjectSorting: String, CaseIterable, Codable {
    case name = "Name"
    case createdAt = "Created"
    case issueCount = "Issue Count"

    var icon: String {
        switch self {
        case .name: return "textformat"
        case .createdAt: return "clock"
        case .issueCount: return "number.circle"
        }
    }
}

// MARK: - ViewSettings

struct ViewSettings: Codable {
    var viewMode: IssuesViewMode
    var groupBy: IssueGrouping
    var sortBy: IssueSorting
    var sortDirection: SortDirection

    static let defaults = ViewSettings(
        viewMode: .list,
        groupBy: .status,
        sortBy: .priority,
        sortDirection: .descending
    )
}

struct ProjectViewSettings: Codable {
    var viewMode: IssuesViewMode
    var groupBy: ProjectGrouping
    var sortBy: ProjectSorting
    var sortDirection: SortDirection

    static let defaults = ProjectViewSettings(
        viewMode: .list,
        groupBy: .status,
        sortBy: .name,
        sortDirection: .ascending
    )
}

// MARK: - ViewSettingsStore

@Observable
class ViewSettingsStore {
    private let defaults = UserDefaults.standard

    // Global control display mode
    var controlDisplayMode: ControlDisplayMode {
        didSet {
            if let data = try? JSONEncoder().encode(controlDisplayMode) {
                defaults.set(data, forKey: "controlDisplayMode")
            }
        }
    }

    // Store settings per system view
    var inboxSettings: ViewSettings {
        didSet { saveSettings(inboxSettings, forKey: "viewSettings.inbox") }
    }

    var todaySettings: ViewSettings {
        didSet { saveSettings(todaySettings, forKey: "viewSettings.today") }
    }

    var upcomingSettings: ViewSettings {
        didSet { saveSettings(upcomingSettings, forKey: "viewSettings.upcoming") }
    }

    var completedSettings: ViewSettings {
        didSet { saveSettings(completedSettings, forKey: "viewSettings.completed") }
    }

    var projectsSettings: ProjectViewSettings {
        didSet { saveProjectSettings(projectsSettings, forKey: "viewSettings.projects") }
    }

    init() {
        // Load control display mode
        if let data = UserDefaults.standard.data(forKey: "controlDisplayMode"),
           let mode = try? JSONDecoder().decode(ControlDisplayMode.self, from: data) {
            self.controlDisplayMode = mode
        } else {
            self.controlDisplayMode = .iconAndText
        }

        self.inboxSettings = Self.loadSettings(forKey: "viewSettings.inbox")
        self.todaySettings = Self.loadSettings(forKey: "viewSettings.today")
        self.upcomingSettings = Self.loadSettings(forKey: "viewSettings.upcoming")
        self.completedSettings = Self.loadSettings(forKey: "viewSettings.completed")
        self.projectsSettings = Self.loadProjectSettings(forKey: "viewSettings.projects")
    }

    func getSettings(for systemView: SystemView) -> ViewSettings {
        switch systemView {
        case .inbox: return inboxSettings
        case .today: return todaySettings
        case .upcoming: return upcomingSettings
        case .completed: return completedSettings
        case .projects: return .defaults
        }
    }

    func updateSettings(_ settings: ViewSettings, for systemView: SystemView) {
        switch systemView {
        case .inbox: inboxSettings = settings
        case .today: todaySettings = settings
        case .upcoming: upcomingSettings = settings
        case .completed: completedSettings = settings
        case .projects: break
        }
    }

    private static func loadSettings(forKey key: String) -> ViewSettings {
        guard let data = UserDefaults.standard.data(forKey: key),
              let settings = try? JSONDecoder().decode(ViewSettings.self, from: data) else {
            return .defaults
        }
        return settings
    }

    private func saveSettings(_ settings: ViewSettings, forKey key: String) {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: key)
        }
    }

    private static func loadProjectSettings(forKey key: String) -> ProjectViewSettings {
        guard let data = UserDefaults.standard.data(forKey: key),
              let settings = try? JSONDecoder().decode(ProjectViewSettings.self, from: data) else {
            return .defaults
        }
        return settings
    }

    private func saveProjectSettings(_ settings: ProjectViewSettings, forKey key: String) {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: key)
        }
    }
}
