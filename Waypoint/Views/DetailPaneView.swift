//
//  DetailPaneView.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/11/25.
//

import SwiftUI

struct DetailPaneView: View {
	@Binding var isInspectorVisible: Bool

	var body: some View {
		ZStack(alignment: .trailing) {
			DetailView(isInspectorVisible: $isInspectorVisible)
				.background(.bar)
				.clipShape(RoundedRectangle(cornerRadius: 12))
				.shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 0)

			// Inspector panel - slides in from the right
			if isInspectorVisible {
				InspectorView(isVisible: $isInspectorVisible)
					.frame(width: 280)
					.transition(.move(edge: .trailing).combined(with: .opacity))
			}
		}
		.padding(.vertical, 12)
		.padding(.trailing, 12)
	}
}
