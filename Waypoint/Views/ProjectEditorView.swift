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
    @FocusState private var focusedBlockId: UUID?
    @State private var showBlockSelector = false
    @State private var blockSelectorSearchText = ""
    @State private var pendingBlockId: UUID?
    @State private var blockSelectorPosition: CGRect = .zero
    @State private var focusAtEndBlockId: UUID?

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

            Spacer()
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
}
