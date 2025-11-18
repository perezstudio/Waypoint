//
//  HorizontalSidebarContainer.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/12/25.
//

import SwiftUI
import SwiftData

struct HorizontalSidebarContainer: View {
	@Environment(ProjectStore.self) private var projectStore
	@Query(sort: \Space.sort, order: .forward) private var spaces: [Space]
	@State private var scrollPosition: Int? = 0

	var body: some View {
		ScrollView(.horizontal, showsIndicators: false) {
			HStack(spacing: 0) {
				// Individual Space Columns
				ForEach(Array(spaces.enumerated()), id: \.element.id) { index, space in
					SpaceColumn(space: space)
						.id(index)
						.containerRelativeFrame(.horizontal)
				}
			}
			.scrollTargetLayout()
		}
		.scrollTargetBehavior(.paging)
		.scrollPosition(id: $scrollPosition)
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.onAppear {
			// Set initial current space
			if let firstSpace = spaces.first {
				projectStore.currentSpace = firstSpace
			}
		}
		.onChange(of: scrollPosition) { oldValue, newValue in
			// Update current space when scroll position changes
			if let position = newValue, position < spaces.count {
				projectStore.currentSpace = spaces[position]
			}
		}
		.onChange(of: projectStore.currentSpace) { oldValue, newValue in
			// Scroll to the newly set current space (e.g., after creating a new space)
			if let currentSpace = newValue,
			   let index = spaces.firstIndex(where: { $0.id == currentSpace.id }) {
				scrollPosition = index
			}
		}
	}
}

#Preview {
	HorizontalSidebarContainer()
		.modelContainer(for: [Space.self, Project.self, Tag.self], inMemory: true)
		.environment(ProjectStore())
}
