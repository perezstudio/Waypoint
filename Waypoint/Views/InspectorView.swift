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
			HStack(alignment: .center) {
				Text("Inspector")
					.font(.title2)
					.fontWeight(.semibold)

				Spacer()
			}
			.padding(.horizontal, 20)
			.padding(.vertical, 16)
			.frame(maxHeight: 60)
			.clipped()

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
		.frame(maxWidth: .infinity, maxHeight: .infinity)
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
