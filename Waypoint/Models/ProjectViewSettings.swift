//
//  ProjectViewSettings.swift
//  Waypoint
//
//  Created by Claude on 11/18/25.
//

import Foundation
import SwiftData

@Model
final class ProjectIssuesViewSettings {
	var id: UUID
	var viewMode: IssuesViewMode
	var groupBy: IssueGrouping
	var sortBy: IssueSorting
	var sortDirection: SortDirection

	var project: Project?

	init(
		viewMode: IssuesViewMode = .list,
		groupBy: IssueGrouping = .status,
		sortBy: IssueSorting = .priority,
		sortDirection: SortDirection = .descending,
		project: Project? = nil
	) {
		self.id = UUID()
		self.viewMode = viewMode
		self.groupBy = groupBy
		self.sortBy = sortBy
		self.sortDirection = sortDirection
		self.project = project
	}
}
