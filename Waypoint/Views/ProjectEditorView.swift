//
//  ProjectEditorView.swift
//  Waypoint
//
//  Created by Claude on 11/14/25.
//

import SwiftUI
import SwiftData

struct ProjectEditorView: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var modelContext
    @FocusState private var focusedBlockId: UUID?
    @State private var showBlockSelector = false
    @State private var blockSelectorSearchText = ""
    @State private var pendingBlockId: UUID?

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
        .frame(minHeight: 200)
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
        VStack(alignment: .leading, spacing: 2) {
            ForEach(sortedBlocks) { block in
                BlockEditorView(
                    block: block,
                    focusedBlockId: $focusedBlockId,
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
                    onMoveUp: {
                        handleMoveUp(from: block)
                    },
                    onMoveDown: {
                        handleMoveDown(from: block)
                    }
                )
                .id(block.id)
                .popover(isPresented: Binding(
                    get: { showBlockSelector && focusedBlockId == block.id },
                    set: { newValue in
                        if !newValue {
                            showBlockSelector = false
                            blockSelectorSearchText = ""
                        }
                    }
                )) {
                    BlockSelectorPopover(
                        isPresented: $showBlockSelector,
                        searchText: $blockSelectorSearchText,
                        onSelect: { selectedType in
                            handleBlockTypeSelection(for: block, type: selectedType)
                        }
                    )
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
        showBlockSelector = true
        blockSelectorSearchText = ""
    }

    private func handleBlockTypeSelection(for block: ContentBlock, type: BlockType) {
        block.type = type
        block.updatedAt = Date()
        try? modelContext.save()
        showBlockSelector = false
        blockSelectorSearchText = ""
        // Keep focus on the block
        focusedBlockId = block.id
    }

    private func handleNewLine(after block: ContentBlock) {
        // Create new paragraph block below current block
        let newOrder = block.order + 1

        // Increment order of all blocks after this one
        for nextBlock in sortedBlocks where nextBlock.order >= newOrder {
            nextBlock.order += 1
        }

        let newBlock = ContentBlock(type: .paragraph, content: "", order: newOrder, project: project)
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

        // Find previous block to focus
        if let currentIndex = sortedBlocks.firstIndex(where: { $0.id == block.id }),
           currentIndex > 0 {
            let previousBlock = sortedBlocks[currentIndex - 1]
            focusedBlockId = previousBlock.id
        }

        // Delete the block
        modelContext.delete(block)
        try? modelContext.save()

        // Reorder remaining blocks
        reorderBlocks()
    }

    private func handleMoveUp(from block: ContentBlock) {
        guard let currentIndex = sortedBlocks.firstIndex(where: { $0.id == block.id }),
              currentIndex > 0 else {
            return
        }

        let previousBlock = sortedBlocks[currentIndex - 1]
        focusedBlockId = previousBlock.id
    }

    private func handleMoveDown(from block: ContentBlock) {
        guard let currentIndex = sortedBlocks.firstIndex(where: { $0.id == block.id }),
              currentIndex < sortedBlocks.count - 1 else {
            return
        }

        let nextBlock = sortedBlocks[currentIndex + 1]
        focusedBlockId = nextBlock.id
    }

    private func reorderBlocks() {
        let blocks = sortedBlocks
        for (index, block) in blocks.enumerated() {
            block.order = index
        }
        try? modelContext.save()
    }
}
