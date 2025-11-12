//
//  HorizontalSidebarContainer.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/12/25.
//

import SwiftUI
import SwiftData

struct HorizontalSidebarContainer: View {
	@Query private var spaces: [Space]
	@State private var scrollPosition: Int? = 0

	var body: some View {
		ScrollView(.horizontal, showsIndicators: false) {
			HStack(spacing: 0) {
				// "All" Column (space: nil shows all projects and labels)
				SpaceColumn(space: nil)
					.id(0)
					.containerRelativeFrame(.horizontal)

				// Individual Space Columns
				ForEach(Array(spaces.enumerated()), id: \.element.id) { index, space in
					SpaceColumn(space: space)
						.id(index + 1)
						.containerRelativeFrame(.horizontal)
				}
			}
			.scrollTargetLayout()
		}
		.scrollTargetBehavior(.paging)
		.scrollPosition(id: $scrollPosition)
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
}

#Preview {
	HorizontalSidebarContainer()
		.modelContainer(for: [Space.self, Project.self, Tag.self], inMemory: true)
		.environment(ProjectStore())
}
