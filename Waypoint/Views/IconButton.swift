//
//  IconButton.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/11/25.
//

import SwiftUI

struct IconButton: View {
	let icon: String
	let action: () -> Void
	var isActive: Bool = false
	var size: CGFloat = 28
	var cornerRadius: CGFloat = 6
	var tooltip: String? = nil

	var body: some View {
		Button(action: action) {
			Image(systemName: icon)
				.font(.system(size: 14))
				.foregroundStyle(.secondary)
		}
		.buttonStyle(IconButtonStyle(isActive: isActive, size: size, cornerRadius: cornerRadius))
		.help(tooltip ?? "")
	}
}
