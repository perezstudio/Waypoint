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
    @Binding var focusAtEndBlockId: UUID?
    let onTypeChange: (BlockType) -> Void
    let onSlashCommand: () -> Void
    let onNewLine: () -> Void
    let onBackspaceEmpty: () -> Void

    @State private var shouldMoveCursorToEnd = false

    var body: some View {
        contentEditor
            .padding(.vertical, 4)
    }

    @ViewBuilder
    private var contentEditor: some View {
        HStack(alignment: .top, spacing: 6) {
            // Add bullet or number prefix for list types
            if let prefix = blockPrefix {
                Text(prefix)
                    .font(fontForBlockType)
                    .foregroundStyle(.secondary)
            }

            TextField("", text: $block.content, prompt: placeholderText, axis: .vertical)
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

                    // If we added a cursor positioning character, remove it
                    if shouldMoveCursorToEnd && newValue.hasSuffix("\u{200B}") {
                        block.content = String(newValue.dropLast())
                        shouldMoveCursorToEnd = false
                    }
                }
                .onChange(of: focusAtEndBlockId) { oldValue, newValue in
                    // Check if this block should move cursor to end
                    if newValue == block.id {
                        shouldMoveCursorToEnd = true
                        // Append zero-width space to move cursor to end
                        block.content += "\u{200B}"
                        focusAtEndBlockId = nil
                    }
                }
                .onKeyPress { keyPress in
                    // Check for backspace/delete key on empty block
                    if (keyPress.characters == "\u{7F}" || keyPress.characters == "\u{08}") && block.content.isEmpty {
                        onBackspaceEmpty()
                        return .handled
                    }
                    return .ignored
                }
        }
    }

    private var blockPrefix: String? {
        switch block.type {
        case .bulletList:
            return "•"
        case .numberedList:
            // Get the index of this block among numbered list blocks
            return "\(block.order + 1)."
        default:
            return nil
        }
    }

    private var placeholderText: Text? {
        // Only show placeholder when this block is focused
        if focusedBlockId == block.id {
            return Text("Type / for commands...").foregroundStyle(.tertiary)
        }
        return nil
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
