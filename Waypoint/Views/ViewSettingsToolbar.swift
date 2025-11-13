//
//  ViewSettingsToolbar.swift
//  Waypoint
//

import SwiftUI

struct ViewSettingsToolbar: View {
    @Binding var settings: ViewSettings
    let systemView: SystemView

    var body: some View {
        HStack(spacing: 16) {
            // View mode toggle (List/Board)
            Picker("View Mode", selection: $settings.viewMode) {
                ForEach(IssuesViewMode.allCases, id: \.self) { mode in
                    Image(systemName: mode == .board ? "square.grid.2x2" : "list.bullet")
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 100)

            Divider()
                .frame(height: 20)

            // Group by selector
            Menu {
                ForEach(IssueGrouping.allCases, id: \.self) { grouping in
                    Button(action: { settings.groupBy = grouping }) {
                        HStack {
                            Image(systemName: grouping.icon)
                            Text(grouping.rawValue)
                            if settings.groupBy == grouping {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: settings.groupBy.icon)
                        .font(.caption)
                    Text("Group: \(settings.groupBy.rawValue)")
                        .font(.caption)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.bar)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)

            // Sort by selector
            Menu {
                ForEach(IssueSorting.allCases, id: \.self) { sorting in
                    Button(action: { settings.sortBy = sorting }) {
                        HStack {
                            Image(systemName: sorting.icon)
                            Text(sorting.rawValue)
                            if settings.sortBy == sorting {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: settings.sortBy.icon)
                        .font(.caption)
                    Text("Sort: \(settings.sortBy.rawValue)")
                        .font(.caption)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.bar)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)

            // Sort direction toggle
            Button(action: {
                settings.sortDirection = settings.sortDirection == .ascending ? .descending : .ascending
            }) {
                HStack(spacing: 4) {
                    Image(systemName: settings.sortDirection.icon)
                        .font(.caption)
                    Text(settings.sortDirection.rawValue)
                        .font(.caption)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.bar)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.background)
    }
}

#Preview {
    @Previewable @State var settings = ViewSettings.defaults

    VStack {
        ViewSettingsToolbar(settings: $settings, systemView: .inbox)
        Spacer()
    }
    .frame(width: 800, height: 200)
}
