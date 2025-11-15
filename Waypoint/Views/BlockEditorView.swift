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
    @Binding var focusedBlockId: UUID?  // Changed from @FocusState.Binding to @Binding
    @Binding var focusAtEndBlockId: UUID?
    @Binding var targetCursorPosition: Int?
    let listNumber: Int?
    let onTypeChange: (BlockType) -> Void
    let onSlashCommand: () -> Void
    let onNewLine: () -> Void
    let onBackspaceEmpty: () -> Void
    let onMoveUp: (Int) -> Void  // Now passes cursor position
    let onMoveDown: (Int) -> Void  // Now passes cursor position
    let onMoveLeft: () -> Void  // Move to end of previous block
    let onMoveRight: () -> Void  // Move to start of next block
    let onIndent: () -> Void  // Handle Tab key for indenting
    let onOutdent: () -> Void  // Handle Shift-Tab key for outdenting

    var body: some View {
        contentEditor
            .padding(.vertical, 4)
            .padding(.leading, CGFloat(block.indentLevel) * 20)
    }

    @ViewBuilder
    private var contentEditor: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            // Add bullet or number prefix for list types
            if let prefix = blockPrefix {
                Text(prefix)
                    .font(fontForBlockType)
                    .foregroundStyle(.secondary)
            }

            BlockTextView(
                text: $block.content,
                placeholder: placeholderString,
                font: nsFontForBlockType,
                textColor: nsColorForBlockType,
                requestFocus: focusedBlockId == block.id,
                moveCursorToEnd: focusAtEndBlockId == block.id,
                targetCursorPosition: targetCursorPosition,
                onBecameFocused: {
                    focusedBlockId = block.id
                },
                onMoveUp: onMoveUp,
                onMoveDown: onMoveDown,
                onMoveLeft: onMoveLeft,
                onMoveRight: onMoveRight,
                onSubmit: onNewLine,
                onBackspaceEmpty: onBackspaceEmpty,
                onIndent: onIndent,
                onOutdent: onOutdent,
                onTextChange: { newValue in
                    handleContentChange(oldValue: block.content, newValue: newValue)
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .onChange(of: focusAtEndBlockId) { oldValue, newValue in
                // Reset the flag after it's been processed
                if newValue == block.id {
                    // The BlockTextView will handle moving cursor to end
                    // Reset the state after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        focusAtEndBlockId = nil
                    }
                }
            }
        }
    }

    private var blockPrefix: String? {
        switch block.type {
        case .bulletList:
            return getBulletSymbol(for: block.indentLevel)
        case .numberedList:
            // Use the calculated list number with appropriate formatting
            if let number = listNumber {
                return getNumberFormat(number: number, indentLevel: block.indentLevel)
            }
            return getNumberFormat(number: 1, indentLevel: block.indentLevel)
        default:
            return nil
        }
    }

    private func getBulletSymbol(for indentLevel: Int) -> String {
        let symbols = ["•", "◦", "▪"]
        let index = indentLevel % symbols.count
        return symbols[index]
    }

    private func getNumberFormat(number: Int, indentLevel: Int) -> String {
        switch indentLevel {
        case 0:
            // Level 0: decimal (1, 2, 3...)
            return "\(number)."
        case 1:
            // Level 1: lowercase letters (a, b, c...)
            return "\(numberToLetter(number))."
        case 2:
            // Level 2: roman numerals (i, ii, iii...)
            return "\(numberToRoman(number))."
        default:
            // Level 3+: alternate between letters and roman numerals
            if indentLevel % 2 == 1 {
                return "\(numberToLetter(number))."
            } else {
                return "\(numberToRoman(number))."
            }
        }
    }

    private func numberToLetter(_ number: Int) -> String {
        guard number > 0 else { return "a" }
        let letters = "abcdefghijklmnopqrstuvwxyz"
        let index = (number - 1) % letters.count
        return String(letters[letters.index(letters.startIndex, offsetBy: index)])
    }

    private func numberToRoman(_ number: Int) -> String {
        guard number > 0 else { return "i" }
        let romanNumerals: [(Int, String)] = [
            (1000, "m"), (900, "cm"), (500, "d"), (400, "cd"),
            (100, "c"), (90, "xc"), (50, "l"), (40, "xl"),
            (10, "x"), (9, "ix"), (5, "v"), (4, "iv"), (1, "i")
        ]

        var result = ""
        var num = number

        for (value, numeral) in romanNumerals {
            while num >= value {
                result += numeral
                num -= value
            }
        }

        return result
    }

    private var placeholderText: Text? {
        // Only show placeholder when this block is focused
        if focusedBlockId == block.id {
            return Text("Type / for commands...").foregroundStyle(.tertiary)
        }
        return nil
    }

    private var placeholderString: String {
        // Only show placeholder when this block is focused
        if focusedBlockId == block.id {
            return "Type / for commands..."
        }
        return ""
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

    private var nsFontForBlockType: NSFont {
        switch block.type {
        case .heading1:
            return NSFont.systemFont(ofSize: 28, weight: .bold)
        case .heading2:
            return NSFont.systemFont(ofSize: 22, weight: .semibold)
        case .heading3:
            return NSFont.systemFont(ofSize: 18, weight: .semibold)
        case .code:
            return NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        case .paragraph, .bulletList, .numberedList, .image:
            return NSFont.systemFont(ofSize: NSFont.systemFontSize)
        }
    }

    private var nsColorForBlockType: NSColor {
        switch block.type {
        case .heading1, .heading2, .heading3:
            return .labelColor
        case .code:
            return .secondaryLabelColor
        default:
            return .labelColor
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
