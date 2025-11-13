//
//  FocusableElement.swift
//  Waypoint
//
//  Created by Claude on 11/13/25.
//

import Foundation

/// Represents an element that can receive keyboard focus in issue views
enum FocusableElement: Hashable, Equatable {
	case issue(UUID)              // Focus on a specific issue card
	case addButton(String)         // Focus on an "Add Issue" button (identified by group ID)

	// Helper to extract issue ID if this is an issue element
	var issueID: UUID? {
		if case .issue(let id) = self {
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
