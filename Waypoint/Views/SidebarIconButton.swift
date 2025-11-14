//
//  SidebarIconButton.swift
//  Waypoint
//
//  Created by Claude on 11/13/25.
//

import SwiftUI

struct SidebarIconButton: View {
	let icon: String
	let action: () -> Void
	var isActive: Bool = false
	var size: CGFloat = 38
	var tooltip: String? = nil

	@State private var isHovered: Bool = false

	var body: some View {
		Button(action: action) {
			Image(systemName: icon)
				.font(.system(size: 16))
				.foregroundStyle(.white.opacity(0.6))
				.frame(width: size, height: size)
				.background {
					RoundedRectangle(cornerRadius: 8, style: .continuous)
						.fill(Color.secondary.opacity(0.15))
						.opacity(isActive || isHovered ? 1 : 0)
				}
				.contentShape(Rectangle())
		}
		.buttonStyle(.plain)
		.onHover { hovering in
			withAnimation(.easeInOut(duration: 0.15)) {
				isHovered = hovering
			}
		}
		.help(tooltip ?? "")
	}
}

#Preview {
	VStack(spacing: 16) {
		SidebarIconButton(icon: "sidebar.left", action: {}, tooltip: "Toggle Sidebar")
		SidebarIconButton(icon: "gear", action: {}, tooltip: "Settings")
		SidebarIconButton(icon: "plus", action: {}, isActive: true, tooltip: "Add")
	}
	.padding()
	.frame(width: 200)
	.background(.black.opacity(0.8))
}
