//
//  IssueSettingsPopover.swift
//  Waypoint
//
//  Created by Claude on 11/18/25.
//

import SwiftUI

struct IssueSettingsPopover: View {
	@Binding var settings: ViewSettings

	var body: some View {
		VStack(alignment: .leading, spacing: 20) {
			// View Mode section
			VStack(alignment: .leading, spacing: 8) {
				Text("View Mode")
					.font(.headline)
					.foregroundStyle(.primary)

				Picker("", selection: $settings.viewMode) {
					ForEach(IssuesViewMode.allCases, id: \.self) { mode in
						Text(mode.rawValue).tag(mode)
					}
				}
				.pickerStyle(.segmented)
				.labelsHidden()
			}

			Divider()

			// Group By section
			VStack(alignment: .leading, spacing: 8) {
				Text("Group By")
					.font(.headline)
					.foregroundStyle(.primary)

				Picker("", selection: $settings.groupBy) {
					ForEach(IssueGrouping.allCases, id: \.self) { grouping in
						Label(grouping.rawValue, systemImage: grouping.icon)
							.tag(grouping)
					}
				}
				.pickerStyle(.menu)
				.labelsHidden()
				.frame(maxWidth: .infinity, alignment: .leading)
			}

			Divider()

			// Sort By section
			VStack(alignment: .leading, spacing: 8) {
				Text("Sort By")
					.font(.headline)
					.foregroundStyle(.primary)

				HStack(spacing: 8) {
					Picker("", selection: $settings.sortBy) {
						ForEach(IssueSorting.allCases, id: \.self) { sorting in
							Label(sorting.rawValue, systemImage: sorting.icon)
								.tag(sorting)
						}
					}
					.pickerStyle(.menu)
					.labelsHidden()
					.frame(maxWidth: .infinity)

					Picker("", selection: $settings.sortDirection) {
						ForEach(SortDirection.allCases, id: \.self) { direction in
							Label(direction.rawValue, systemImage: direction.icon)
								.tag(direction)
						}
					}
					.pickerStyle(.menu)
					.labelsHidden()
					.frame(width: 120)
				}
			}
		}
		.padding(20)
		.frame(width: 280)
	}
}

#Preview {
	IssueSettingsPopover(
		settings: .constant(ViewSettings(
			viewMode: .list,
			groupBy: .status,
			sortBy: .priority,
			sortDirection: .descending
		))
	)
}
