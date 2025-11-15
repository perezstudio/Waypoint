//
//  ProjectEditorView.swift
//  Waypoint
//
//  Created by Claude on 11/14/25.
//

import SwiftUI
import SwiftData

// Preference key for tracking block position
struct BlockPositionPreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

struct ProjectEditorView: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var modelContext
    @State private var focusedBlockId: UUID?  // Changed from @FocusState to @State
    @State private var showBlockSelector = false
    @State private var blockSelectorSearchText = ""
    @State private var pendingBlockId: UUID?
    @State private var blockSelectorPosition: CGRect = .zero
    @State private var focusAtEndBlockId: UUID?
    @State private var targetCursorPosition: Int?  // For maintaining cursor column during navigation

    private var sortedBlocks: [ContentBlock] {
        project.contentBlocks.sorted { $0.order < $1.order }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if sortedBlocks.isEmpty {
                emptyStateView
            } else {
                blocksView
            }
        }
        .frame(minHeight: 200, maxHeight: .infinity, alignment: .top)
        .onAppear {
            // Create initial block if empty
            if sortedBlocks.isEmpty {
                createInitialBlock()
            }
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Click to add content or type / for commands")
                .font(.body)
                .foregroundStyle(.secondary)
                .onTapGesture {
                    createInitialBlock()
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }

    @ViewBuilder
    private var blocksView: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(sortedBlocks) { block in
                    BlockEditorView(
                        block: block,
                        focusedBlockId: $focusedBlockId,
                        focusAtEndBlockId: $focusAtEndBlockId,
                        targetCursorPosition: $targetCursorPosition,
                        listNumber: calculateListNumber(for: block),
                        onTypeChange: { newType in
                            handleTypeChange(for: block, newType: newType)
                        },
                        onSlashCommand: {
                            handleSlashCommand(for: block)
                        },
                        onNewLine: {
                            handleNewLine(after: block)
                        },
                        onBackspaceEmpty: {
                            handleBackspaceEmpty(on: block)
                        },
                        onMoveUp: { cursorPosition in
                            handleMoveUp(from: block, cursorPosition: cursorPosition)
                        },
                        onMoveDown: { cursorPosition in
                            handleMoveDown(from: block, cursorPosition: cursorPosition)
                        },
                        onMoveLeft: {
                            handleMoveLeft(from: block)
                        },
                        onMoveRight: {
                            handleMoveRight(from: block)
                        },
                        onIndent: {
                            handleIndent(on: block)
                        },
                        onOutdent: {
                            handleOutdent(on: block)
                        }
                    )
                    .id(block.id)
                    .background(
                        GeometryReader { geometry in
                            Color.clear.preference(
                                key: BlockPositionPreferenceKey.self,
                                value: showBlockSelector && pendingBlockId == block.id ? geometry.frame(in: .named("blockContainer")) : .zero
                            )
                        }
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)

            // Block selector overlay
            if showBlockSelector, let pendingId = pendingBlockId,
               let block = sortedBlocks.first(where: { $0.id == pendingId }) {
                BlockSelectorPopover(
                    isPresented: $showBlockSelector,
                    searchText: $blockSelectorSearchText,
                    onSelect: { selectedType in
                        handleBlockTypeSelection(for: block, type: selectedType)
                    }
                )
                .offset(x: 30, y: blockSelectorPosition.minY + 30)
            }
        }
        .coordinateSpace(name: "blockContainer")
        .onPreferenceChange(BlockPositionPreferenceKey.self) { value in
            blockSelectorPosition = value
        }
        .onChange(of: showBlockSelector) { oldValue, newValue in
            // When menu is dismissed, restore focus to the block
            if !newValue && oldValue {
                if let pendingId = pendingBlockId {
                    focusedBlockId = pendingId
                    pendingBlockId = nil
                }
            }
        }
    }

    // MARK: - Block Management

    private func createInitialBlock() {
        let newBlock = ContentBlock(type: .paragraph, content: "", order: 0, project: project)
        modelContext.insert(newBlock)
        try? modelContext.save()
        focusedBlockId = newBlock.id
    }

    private func handleTypeChange(for block: ContentBlock, newType: BlockType) {
        block.type = newType
        block.updatedAt = Date()
        try? modelContext.save()
    }

    private func handleSlashCommand(for block: ContentBlock) {
        // Clear the "/" character
        block.content = ""
        // Store which block opened the menu
        pendingBlockId = block.id
        // Clear focus from text field so menu can receive input
        focusedBlockId = nil
        showBlockSelector = true
        blockSelectorSearchText = ""
    }

    private func handleBlockTypeSelection(for block: ContentBlock, type: BlockType) {
        block.type = type
        block.updatedAt = Date()
        try? modelContext.save()
        showBlockSelector = false
        blockSelectorSearchText = ""
        pendingBlockId = nil
        // Restore focus to the block
        focusedBlockId = block.id
    }

    private func handleNewLine(after block: ContentBlock) {
        // If current block is an empty list, outdent it instead of creating a new block
        if (block.type == .bulletList || block.type == .numberedList) && block.content.isEmpty {
            if block.indentLevel > 0 {
                // Outdent the current block
                block.indentLevel -= 1
                block.updatedAt = Date()
                try? modelContext.save()
                print("📝 Outdented empty list block to level \(block.indentLevel)")
            } else {
                // At level 0, convert to paragraph
                block.type = .paragraph
                block.indentLevel = 0
                block.updatedAt = Date()
                try? modelContext.save()
                print("📝 Converted empty list block to paragraph")
            }
            return
        }

        // Determine the type and indent level for the new block
        // If current block is a list, continue with the same list type and indent level
        let newBlockType: BlockType
        let newIndentLevel: Int
        if block.type == .bulletList || block.type == .numberedList {
            newBlockType = block.type
            newIndentLevel = block.indentLevel  // Preserve indent level
        } else {
            newBlockType = .paragraph
            newIndentLevel = 0
        }

        let newOrder = block.order + 1

        // Increment order of all blocks after this one
        for nextBlock in sortedBlocks where nextBlock.order >= newOrder {
            nextBlock.order += 1
        }

        let newBlock = ContentBlock(type: newBlockType, content: "", order: newOrder, indentLevel: newIndentLevel, project: project)
        modelContext.insert(newBlock)
        try? modelContext.save()

        // Focus the new block
        focusedBlockId = newBlock.id
    }

    private func handleBackspaceEmpty(on block: ContentBlock) {
        guard sortedBlocks.count > 1 else {
            // Don't delete the last block, just ensure it's a paragraph
            if block.type != .paragraph {
                block.type = .paragraph
                try? modelContext.save()
            }
            return
        }

        guard let currentIndex = sortedBlocks.firstIndex(where: { $0.id == block.id }) else {
            return
        }

        // Find previous block to focus at end
        if currentIndex > 0 {
            let previousBlock = sortedBlocks[currentIndex - 1]

            // Delete the block first
            modelContext.delete(block)
            try? modelContext.save()

            // Reorder remaining blocks
            reorderBlocks()

            // Focus previous block at the end
            focusedBlockId = previousBlock.id
            focusAtEndBlockId = previousBlock.id
        } else {
            // If deleting the first block, just focus the next one
            modelContext.delete(block)
            try? modelContext.save()
            reorderBlocks()

            if let firstBlock = sortedBlocks.first {
                focusedBlockId = firstBlock.id
            }
        }
    }

    private func reorderBlocks() {
        let blocks = sortedBlocks
        for (index, block) in blocks.enumerated() {
            block.order = index
        }
        try? modelContext.save()
    }

    private func handleMoveUp(from block: ContentBlock, cursorPosition: Int) {
        guard let currentIndex = sortedBlocks.firstIndex(where: { $0.id == block.id }),
              currentIndex > 0 else {
            return
        }

        let previousBlock = sortedBlocks[currentIndex - 1]
        // Set target cursor position to maintain column
        targetCursorPosition = cursorPosition
        // Focus previous block
        focusedBlockId = previousBlock.id

        // Reset the target position after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            targetCursorPosition = nil
        }
    }

    private func handleMoveDown(from block: ContentBlock, cursorPosition: Int) {
        guard let currentIndex = sortedBlocks.firstIndex(where: { $0.id == block.id }),
              currentIndex < sortedBlocks.count - 1 else {
            return
        }

        let nextBlock = sortedBlocks[currentIndex + 1]
        // Set target cursor position to maintain column
        targetCursorPosition = cursorPosition
        // Focus next block
        focusedBlockId = nextBlock.id

        // Reset the target position after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            targetCursorPosition = nil
        }
    }

    private func handleMoveLeft(from block: ContentBlock) {
        guard let currentIndex = sortedBlocks.firstIndex(where: { $0.id == block.id }),
              currentIndex > 0 else {
            return
        }

        let previousBlock = sortedBlocks[currentIndex - 1]
        // Move to end of previous block
        focusedBlockId = previousBlock.id
        focusAtEndBlockId = previousBlock.id

        // Reset focusAtEndBlockId after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusAtEndBlockId = nil
        }
    }

    private func handleMoveRight(from block: ContentBlock) {
        guard let currentIndex = sortedBlocks.firstIndex(where: { $0.id == block.id }),
              currentIndex < sortedBlocks.count - 1 else {
            return
        }

        let nextBlock = sortedBlocks[currentIndex + 1]
        // Move to start of next block (don't set focusAtEndBlockId or targetCursorPosition)
        focusedBlockId = nextBlock.id
    }

    private func handleIndent(on block: ContentBlock) {
        // Only indent bullet and numbered lists
        guard block.type == .bulletList || block.type == .numberedList else {
            return
        }

        // Cap at a reasonable max indent level
        guard block.indentLevel < 5 else {
            return
        }

        block.indentLevel += 1
        block.updatedAt = Date()
        try? modelContext.save()
        print("📝 Indented block to level \(block.indentLevel)")
    }

    private func handleOutdent(on block: ContentBlock) {
        // Only outdent bullet and numbered lists
        guard block.type == .bulletList || block.type == .numberedList else {
            return
        }

        if block.indentLevel > 0 {
            // Decrease indent level
            block.indentLevel -= 1
            block.updatedAt = Date()
            try? modelContext.save()
            print("📝 Outdented block to level \(block.indentLevel)")
        } else {
            // At level 0, convert to paragraph
            block.type = .paragraph
            block.indentLevel = 0
            block.updatedAt = Date()
            try? modelContext.save()
            print("📝 Converted list block to paragraph")
        }
    }

    private func calculateListNumber(for block: ContentBlock) -> Int? {
        // Only calculate for numbered lists
        guard block.type == .numberedList else {
            return nil
        }

        // Find the current block's index
        guard let currentIndex = sortedBlocks.firstIndex(where: { $0.id == block.id }) else {
            return 1
        }

        // If it's the first block, return 1
        if currentIndex == 0 {
            return 1
        }

        // Search backwards for the most recent numbered list at the same indent level
        for i in stride(from: currentIndex - 1, through: 0, by: -1) {
            let previousBlock = sortedBlocks[i]

            // Found a numbered list at the same indent level
            if previousBlock.type == .numberedList && previousBlock.indentLevel == block.indentLevel {
                // Recursively calculate that block's number and add 1
                if let previousNumber = calculateListNumber(for: previousBlock) {
                    return previousNumber + 1
                }
            }

            // If we encounter a block at a lower indent level, stop searching
            // (we've gone back to a parent level, so this should start at 1)
            if previousBlock.indentLevel < block.indentLevel {
                break
            }
        }

        // No previous numbered list at the same level found, start at 1
        return 1
    }
}
