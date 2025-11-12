//
//  CreationMenuPopover.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/12/25.
//

import SwiftUI

enum CreationOption: CaseIterable {
    case project
    case issue
    case label
    case space

    var title: String {
        switch self {
        case .project: return "New Project"
        case .issue: return "New Issue"
        case .label: return "New Label"
        case .space: return "New Space"
        }
    }

    var icon: String {
        switch self {
        case .project: return "folder.badge.plus"
        case .issue: return "doc.badge.plus"
        case .label: return "tag"
        case .space: return "person.3.fill"
        }
    }

    var keyboardShortcut: String? {
        switch self {
        case .project: return "1"
        case .issue: return "2"
        case .label: return "3"
        case .space: return "4"
        }
    }
}

struct CreationMenuPopover: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (CreationOption) -> Void

    @State private var hoveredOption: CreationOption?
    @State private var selectedIndex: Int = 0
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 4) {
            ForEach(Array(CreationOption.allCases.enumerated()), id: \.element) { index, option in
                CreationMenuItem(
                    option: option,
                    isHovered: hoveredOption == option,
                    isFocused: selectedIndex == index
                ) {
                    onSelect(option)
                    dismiss()
                }
                .onHover { isHovering in
                    if isHovering {
                        hoveredOption = option
                        selectedIndex = index
                    } else if hoveredOption == option {
                        hoveredOption = nil
                    }
                }
            }
        }
        .padding(8)
        .frame(width: 220)
        .focusable()
        .focused($isFocused)
        .focusEffectDisabled()
        .onAppear {
            // Auto-focus the menu
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
        .onKeyPress(.upArrow) {
            moveFocus(direction: .up)
            return .handled
        }
        .onKeyPress(.downArrow) {
            moveFocus(direction: .down)
            return .handled
        }
        .onKeyPress(.return) {
            let options = CreationOption.allCases
            if selectedIndex >= 0 && selectedIndex < options.count {
                onSelect(options[selectedIndex])
                dismiss()
            }
            return .handled
        }
        .onKeyPress(.escape) {
            dismiss()
            return .handled
        }
        .onKeyPress(characters: .decimalDigits) { press in
            let options = CreationOption.allCases
            switch press.characters {
            case "1":
                selectedIndex = 0
                onSelect(options[0])
                dismiss()
                return .handled
            case "2":
                selectedIndex = 1
                onSelect(options[1])
                dismiss()
                return .handled
            case "3":
                selectedIndex = 2
                onSelect(options[2])
                dismiss()
                return .handled
            case "4":
                selectedIndex = 3
                onSelect(options[3])
                dismiss()
                return .handled
            default:
                return .ignored
            }
        }
    }

    private func moveFocus(direction: FocusDirection) {
        let options = CreationOption.allCases

        switch direction {
        case .up:
            selectedIndex = selectedIndex > 0 ? selectedIndex - 1 : options.count - 1
        case .down:
            selectedIndex = selectedIndex < options.count - 1 ? selectedIndex + 1 : 0
        }
    }

    enum FocusDirection {
        case up, down
    }
}

struct CreationMenuItem: View {
    let option: CreationOption
    let isHovered: Bool
    let isFocused: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: option.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(width: 16)

                Text(option.title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Spacer()

                if let shortcut = option.keyboardShortcut {
                    Text(shortcut)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.tertiary.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill((isHovered || isFocused) ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CreationMenuPopover { option in
        print("Selected: \(option)")
    }
}
