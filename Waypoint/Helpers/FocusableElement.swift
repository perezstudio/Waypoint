//
//  FocusableElement.swift
//  Waypoint
//
//  Created by Claude on 11/13/25.
//

import Foundation

/// Represents an element that can receive keyboard focus in issue and project views
enum FocusableElement: Hashable, Equatable {
	case issue(UUID)              // Focus on a specific issue card
	case project(UUID)            // Focus on a specific project card
	case addButton(String)         // Focus on an "Add Issue/Project" button (identified by group ID)

	// Helper to extract issue ID if this is an issue element
	var issueID: UUID? {
		if case .issue(let id) = self {
			return id
		}
		return nil
	}

	// Helper to extract project ID if this is a project element
	var projectID: UUID? {
		if case .project(let id) = self {
			return id
		}
		return nil
	}

	// Helper to extract group ID if this is an add button
	var groupID: String? {
		if case .addButton(let id) = self {
			return id
		}
		return nil
	}
}
