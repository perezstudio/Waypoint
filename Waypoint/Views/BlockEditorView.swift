//
//  BlockEditorView.swift
//  Waypoint
//
//  Created by Claude on 11/14/25.
//

import SwiftUI
import SwiftData

struct BlockEditorView: View {
    @Bindable var block: ContentBlock
    @FocusState.Binding var focusedBlockId: UUID?
    let onTypeChange: (BlockType) -> Void
    let onSlashCommand: () -> Void
    let onNewLine: () -> Void
    let onBackspaceEmpty: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Block type indicator
            blockTypeIndicator

            // Content editor
            contentEditor
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var blockTypeIndicator: some View {
        Image(systemName: block.type.icon)
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(width: 20)
            .opacity(focusedBlockId == block.id ? 1.0 : 0.3)
    }

    @ViewBuilder
    private var contentEditor: some View {
        TextField("", text: $block.content, axis: .vertical)
            .textFieldStyle(.plain)
            .font(fontForBlockType)
            .foregroundStyle(colorForBlockType)
            .focused($focusedBlockId, equals: block.id)
            .onSubmit {
                // Enter key creates new line
                onNewLine()
            }
            .onChange(of: block.content) { oldValue, newValue in
                handleContentChange(oldValue: oldValue, newValue: newValue)
            }
            .onKeyPress(.delete) {
                // Backspace on empty block
                if block.content.isEmpty {
                    onBackspaceEmpty()
                    return .handled
                }
                return .ignored
            }
            .onKeyPress(.upArrow) {
                onMoveUp()
                return .handled
            }
            .onKeyPress(.downArrow) {
                onMoveDown()
                return .handled
            }
    }

    private var fontForBlockType: Font {
        switch block.type {
        case .heading1:
            return .system(size: 28, weight: .bold)
        case .heading2:
            return .system(size: 22, weight: .semibold)
        case .heading3:
            return .system(size: 18, weight: .semibold)
        case .code:
            return .system(.body, design: .monospaced)
        case .paragraph, .bulletList, .numberedList, .image:
            return .body
        }
    }

    private var colorForBlockType: Color {
        switch block.type {
        case .heading1, .heading2, .heading3:
            return .primary
        case .code:
            return .secondary
        default:
            return .primary
        }
    }

    private func handleContentChange(oldValue: String, newValue: String) {
        // Update timestamp
        block.updatedAt = Date()

        // Check for slash command
        if newValue == "/" {
            onSlashCommand()
            return
        }

        // Check for markdown patterns at the start of the line
        if newValue.hasPrefix("# ") && block.type != .heading1 {
            block.content = String(newValue.dropFirst(2))
            onTypeChange(.heading1)
        } else if newValue.hasPrefix("## ") && block.type != .heading2 {
            block.content = String(newValue.dropFirst(3))
            onTypeChange(.heading2)
        } else if newValue.hasPrefix("### ") && block.type != .heading3 {
            block.content = String(newValue.dropFirst(4))
            onTypeChange(.heading3)
        } else if (newValue.hasPrefix("- ") || newValue.hasPrefix("* ")) && block.type != .bulletList {
            block.content = String(newValue.dropFirst(2))
            onTypeChange(.bulletList)
        } else if newValue.hasPrefix("1. ") && block.type != .numberedList {
            block.content = String(newValue.dropFirst(3))
            onTypeChange(.numberedList)
        } else if newValue.hasPrefix("```") && block.type != .code {
            block.content = String(newValue.dropFirst(3))
            onTypeChange(.code)
        }
    }
}
