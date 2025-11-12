//
//  AppColor.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/12/25.
//

import SwiftUI

enum AppColor: String, CaseIterable {
	case blue = "#007AFF"
	case orange = "#FF9500"
	case pink = "#FF2D55"
	case purple = "#AF52DE"
	case indigo = "#5856D6"
	case cyan = "#32ADE6"
	case teal = "#00C7BE"
	case green = "#34C759"
	case red = "#FF3B30"
	case yellow = "#FFCC00"
	case brown = "#A2845E"
	case gray = "#8E8E93"

	// Returns SwiftUI Color for UI rendering
	var color: Color {
		Color(hex: rawValue) ?? .blue
	}

	// Returns hex string for SwiftData storage
	var hexString: String {
		rawValue
	}

	// Initialize from hex string (for loading from SwiftData)
	init?(hexString: String) {
		self.init(rawValue: hexString)
	}

	// Static method to get color from hex string
	static func color(from hexString: String) -> Color {
		if let appColor = AppColor(hexString: hexString) {
			return appColor.color
		}
		// Fallback: parse hex directly
		return Color(hex: hexString) ?? .blue
	}
}

// Keep the Color hex extension internal for AppColor use
extension Color {
	init?(hex: String) {
		let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
		guard hex.count == 6 else { return nil }

		var rgb: UInt64 = 0
		Scanner(string: hex).scanHexInt64(&rgb)

		let r = Double((rgb & 0xFF0000) >> 16) / 255.0
		let g = Double((rgb & 0x00FF00) >> 8) / 255.0
		let b = Double(rgb & 0x0000FF) / 255.0

		self.init(red: r, green: g, blue: b)
	}
}
