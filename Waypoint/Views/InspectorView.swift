//
//  InspectorView.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/11/25.
//

import SwiftUI
import SwiftData

struct InspectorView: View {
	@Binding var isVisible: Bool

	var body: some View {
		VStack(alignment: .leading, spacing: 0) {
			// Inspector header
			HStack {
				Text("Inspector")
					.font(.headline)

				Spacer()

				IconButton(
					icon: "xmark.circle.fill",
					action: {
						withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
							isVisible = false
						}
					},
					tooltip: "Close Inspector"
				)
			}
			.padding(16)

			Divider()

			// Inspector content
			ScrollView {
				VStack(alignment: .leading, spacing: 20) {
					// Properties section
					VStack(alignment: .leading, spacing: 12) {
						Text("Properties")
							.font(.caption)
							.foregroundStyle(.secondary)
							.textCase(.uppercase)

						VStack(alignment: .leading, spacing: 8) {
							PropertyRow(label: "Status", value: "In Progress")
							PropertyRow(label: "Priority", value: "High")
							PropertyRow(label: "Due Date", value: "Nov 15, 2025")
						}
					}

					Divider()

					// Details section
					VStack(alignment: .leading, spacing: 12) {
						Text("Details")
							.font(.caption)
							.foregroundStyle(.secondary)
							.textCase(.uppercase)

						Text("Additional details and information will appear here.")
							.font(.subheadline)
							.foregroundStyle(.secondary)
					}

					Spacer()
				}
				.padding(16)
			}
		}
		.background(.ultraThinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 8))
		.overlay(
			RoundedRectangle(cornerRadius: 8)
				.strokeBorder(.separator.opacity(0.5), lineWidth: 0.5)
		)
		.padding(.vertical, 16)
		.padding(.trailing, 16)
		.shadow(color: .black.opacity(0.15), radius: 8, x: -2, y: 0)
	}
}

// Property row component
struct PropertyRow: View {
	let label: String
	let value: String

	var body: some View {
		HStack {
			Text(label)
				.font(.subheadline)
				.foregroundStyle(.secondary)

			Spacer()

			Text(value)
				.font(.subheadline)
				.fontWeight(.medium)
		}
		.padding(.vertical, 4)
	}
}

#Preview {
	InspectorView(isVisible: .constant(true))
		.frame(width: 280, height: 600)
}
