//
//  ProjectCard.swift
//  Waypoint
//
//  Created by Claude on 11/13/25.
//

import SwiftUI

struct ProjectCard: View {
    let project: Project
    let onSelect: () -> Void
    @FocusState.Binding var focusedElement: FocusableElement?
    @Environment(ProjectStore.self) private var projectStore

    private var isFocused: Bool {
        if case .project(let id) = focusedElement {
            return id == project.id
        }
        return false
    }

    private var projectColor: Color {
        AppColor.color(from: project.color)
    }

    private var statusText: String {
        switch project.status {
        case .todo: return "To Do"
        case .inProgress: return "In Progress"
        case .review: return "Review"
        case .done: return "Done"
        }
    }

    private var statusColor: Color {
        switch project.status {
        case .todo: return .gray
        case .inProgress: return .orange
        case .review: return .purple
        case .done: return .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icon and title
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: project.icon)
                    .font(.title3)
                    .foregroundStyle(projectColor)

                Text(project.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Spacer()
            }

            // Status badge
            HStack(spacing: 4) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)

                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(statusColor)
            }

            // Issue count
            HStack(spacing: 4) {
                Image(systemName: "list.bullet.circle")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text("\(project.issues.count) \(project.issues.count == 1 ? "issue" : "issues")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Space name if exists
            if let space = project.space {
                HStack(spacing: 4) {
                    Image(systemName: space.icon)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Text(space.name)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isFocused ? Color.accentColor.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isFocused ? Color.accentColor : projectColor.opacity(0.3), lineWidth: isFocused ? 2 : 1)
        )
        .focusable()
        .focused($focusedElement, equals: .project(project.id))
        .onTapGesture {
            onSelect()
            focusedElement = .project(project.id)
        }
    }
}

#Preview {
    @Previewable @FocusState var focusedElement: FocusableElement?
    @Previewable @State var projectStore = ProjectStore()

    let sampleSpace = Space(name: "Engineering", spaceDescription: "Engineering team", icon: "hammer.fill", color: "#007AFF")
    let sampleProject = Project(name: "Website Redesign", icon: "safari.fill", color: "#007AFF", space: sampleSpace)

    VStack(spacing: 16) {
        ProjectCard(project: sampleProject, onSelect: {}, focusedElement: $focusedElement)
        ProjectCard(project: sampleProject, onSelect: {}, focusedElement: $focusedElement)
            .onAppear {
                focusedElement = .project(sampleProject.id)
            }
    }
    .padding()
    .frame(width: 300)
    .environment(projectStore)
}
