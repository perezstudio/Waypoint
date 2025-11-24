//
//  IconPickerGrid.swift
//  Waypoint
//
//  Created by Claude Code
//

import SwiftUI

struct IconPickerGrid: View {
	@Binding var selectedIcon: String
	let icons: [String]
	var allowNone: Bool = false  // For tags that support nil icon
	@Binding var highlightedIndex: Int
	let iconsPerRow: Int
	let onIconSelected: ((String) -> Void)?

	init(
		selectedIcon: Binding<String>,
		icons: [String],
		allowNone: Bool = false,
		highlightedIndex: Binding<Int>,
		iconsPerRow: Int,
		onIconSelected: ((String) -> Void)? = nil
	) {
		self._selectedIcon = selectedIcon
		self.icons = icons
		self.allowNone = allowNone
		self._highlightedIndex = highlightedIndex
		self.iconsPerRow = iconsPerRow
		self.onIconSelected = onIconSelected
	}

	// Convert to optional array if allowNone is true
	private var displayIcons: [String?] {
		if allowNone {
			return [nil] + icons.map { $0 as String? }
		} else {
			return icons.map { $0 as String? }
		}
	}

	var body: some View {
		ScrollView(.horizontal, showsIndicators: false) {
			VStack(alignment: .leading, spacing: 8) {
				// Calculate rows dynamically
				ForEach(0..<rowCount, id: \.self) { rowIndex in
					HStack(spacing: 8) {
						ForEach(iconsInRow(rowIndex), id: \.offset) { index, icon in
							IconGridButton(
								icon: icon,
								isSelected: (icon == nil && selectedIcon.isEmpty) || (icon == selectedIcon),
								isHighlighted: highlightedIndex == index,
								action: {
									let newIcon = icon ?? ""
									selectedIcon = newIcon
									onIconSelected?(newIcon)
								}
							)
			.id(index)
						}
					}
				}
			}
			.frame(maxWidth: .infinity, alignment: .leading)
			.padding(.vertical, 4)
		}
	}

	private var rowCount: Int {
		(displayIcons.count + iconsPerRow - 1) / iconsPerRow
	}

	private func iconsInRow(_ row: Int) -> [(offset: Int, element: String?)] {
		let start = row * iconsPerRow
		let end = min(start + iconsPerRow, displayIcons.count)
		return Array(displayIcons[start..<end].enumerated().map { (start + $0.offset, $0.element) })
	}
}

private struct IconGridButton: View {
	let icon: String?
	let isSelected: Bool
	let isHighlighted: Bool
	let action: () -> Void

	var body: some View {
		Button(action: action) {
			ZStack {
				RoundedRectangle(cornerRadius: 8)
					.fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))

				Group {
					if let icon = icon {
						Image(systemName: icon)
							.font(.title3)
							.foregroundStyle(isSelected ? .white : .primary)
					} else {
						// "No icon" option for tags
						Image(systemName: "slash.circle")
							.font(.title3)
							.foregroundStyle(isSelected ? .white : .secondary)
					}
				}

				if isHighlighted {
					RoundedRectangle(cornerRadius: 8)
						.strokeBorder(Color.accentColor, lineWidth: 3)
				}
			}
			.frame(width: 44, height: 44)
			.scaleEffect(isHighlighted ? 1.05 : 1.0)
		}
		.buttonStyle(.plain)
	}
}

#Preview {
	@Previewable @State var selectedIcon = "folder.fill"
	@Previewable @State var highlightedIndex = 0

	IconPickerGrid(
		selectedIcon: $selectedIcon,
		icons: AppIcon.projectIcons,
		allowNone: false,
		highlightedIndex: $highlightedIndex,
		iconsPerRow: 12
	)
	.padding()
}
