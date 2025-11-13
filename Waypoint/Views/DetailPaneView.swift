//
//  DetailPaneView.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/11/25.
//

import SwiftUI

struct DetailPaneView: View {
	@Binding var isInspectorVisible: Bool
	@Binding var isSidebarCollapsed: Bool

	var body: some View {
		GeometryReader { geometry in
			DetailView(isInspectorVisible: $isInspectorVisible, isSidebarCollapsed: $isSidebarCollapsed)
				.background(.bar)
				.clipShape(RoundedRectangle(cornerRadius: 12))
				.shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 0)
				.frame(width: geometry.size.width - 12, height: geometry.size.height - 24)
				.position(x: (geometry.size.width - 12) / 2, y: geometry.size.height / 2)
		}
	}
}
