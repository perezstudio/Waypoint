//
//  ProjectOverviewComponents.swift
//  Waypoint
//
//  Created by Claude on 11/14/25.
//

import SwiftUI
import SwiftData

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionIcon: String = "plus.circle"

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()

            if let action = action {
                Button(action: action) {
                    Image(systemName: actionIcon)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Project Property Row

struct ProjectPropertyRow: View {
    let label: String
    let value: String
    var color: Color?

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            if let color = color {
                HStack(spacing: 4) {
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                    Text(value)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(color)
                }
            } else {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
    }
}

// MARK: - Resource Row

struct ResourceRow: View {
    let resource: Resource
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: resource.type == .link ? "link" : "doc")
                .foregroundStyle(.blue)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(resource.title)
                    .font(.subheadline)
                Text(resource.url)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: { openResource() }) {
                Image(systemName: "arrow.up.right.square")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contextMenu {
            Button(action: { openResource() }) {
                Label("Open", systemImage: "arrow.up.right.square")
            }
            Button(role: .destructive, action: { deleteResource() }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func openResource() {
        if let url = URL(string: resource.url) {
            NSWorkspace.shared.open(url)
        }
    }

    private func deleteResource() {
        modelContext.delete(resource)
        try? modelContext.save()
    }
}

// MARK: - Milestone Row

struct MilestoneRow: View {
    let milestone: Milestone
    let onToggle: (Bool) -> Void
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack(spacing: 12) {
            Button(action: { onToggle(!milestone.isCompleted) }) {
                Image(systemName: milestone.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(milestone.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(milestone.title)
                    .font(.subheadline)
                    .strikethrough(milestone.isCompleted)
                    .foregroundStyle(milestone.isCompleted ? .secondary : .primary)

                if let description = milestone.milestoneDescription, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if let dueDate = milestone.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(dueDate, style: .date)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contextMenu {
            Button(role: .destructive, action: { deleteMilestone() }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func deleteMilestone() {
        modelContext.delete(milestone)
        try? modelContext.save()
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var buttonTitle: String?
    var buttonAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            if let buttonTitle = buttonTitle, let buttonAction = buttonAction {
                Button(action: buttonAction) {
                    HStack {
                        Image(systemName: "plus")
                        Text(buttonTitle)
                    }
                }
                .buttonStyle(.bordered)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}
