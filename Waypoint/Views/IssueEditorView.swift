//
//  IssueEditorView.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/19/25.
//

import SwiftUI
import SwiftData

struct IssueEditorView: View {
    @Bindable var issue: Issue
    @Environment(\.modelContext) private var modelContext
    @State private var focusedBlockId: UUID?
    @State private var showBlockSelector = false
    @State private var blockSelectorSearchText = ""
    @State private var pendingBlockId: UUID?
    @State private var blockSelectorPosition: CGRect = .zero
    @State private var focusAtEndBlockId: UUID?
    @State private var targetCursorPosition: Int?
    @State private var hasMigrated = false

    private var sortedBlocks: [ContentBlock] {
        issue.contentBlocks.sorted { $0.order < $1.order }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if sortedBlocks.isEmpty {
                emptyStateView
            } else {
                blocksView
            }
        }
        .frame(minHeight: 150, maxHeight: .infinity, alignment: .top)
        .onAppear {
            // Migrate existing description to blocks if needed
            if !hasMigrated {
                migrateDescriptionToBlocks()
                hasMigrated = true
            }

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
        .padding(12)
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
            if !newValue && oldValue {
                if let pendingId = pendingBlockId {
                    focusedBlockId = pendingId
                    pendingBlockId = nil
                }
            }
        }
    }

    // MARK: - Migration

    private func migrateDescriptionToBlocks() {
        // If contentBlocks is empty but issueDescription has content, migrate it
        guard sortedBlocks.isEmpty,
              let description = issue.issueDescription,
              !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        // Create a paragraph block with the existing description
        let block = ContentBlock(
            type: .paragraph,
            content: description.trimmingCharacters(in: .whitespacesAndNewlines),
            order: 0,
            issue: issue
        )
        modelContext.insert(block)
        try? modelContext.save()
    }

    // MARK: - Block Management

    private func createInitialBlock() {
        let newBlock = ContentBlock(type: .paragraph, content: "", order: 0, issue: issue)
        modelContext.insert(newBlock)
        try? modelContext.save()
        focusedBlockId = newBlock.id
    }

    private func handleTypeChange(for block: ContentBlock, newType: BlockType) {
        block.type = newType
        block.updatedAt = Date()
        issue.updatedAt = Date()
        try? modelContext.save()
    }

    private func handleSlashCommand(for block: ContentBlock) {
        block.content = ""
        pendingBlockId = block.id
        focusedBlockId = nil
        showBlockSelector = true
        blockSelectorSearchText = ""
    }

    private func handleBlockTypeSelection(for block: ContentBlock, type: BlockType) {
        block.type = type
        block.updatedAt = Date()
        issue.updatedAt = Date()
        try? modelContext.save()
        showBlockSelector = false
        blockSelectorSearchText = ""
        pendingBlockId = nil
        focusedBlockId = block.id
    }

    private func handleNewLine(after block: ContentBlock) {
        if (block.type == .bulletList || block.type == .numberedList) && block.content.isEmpty {
            if block.indentLevel > 0 {
                block.indentLevel -= 1
                block.updatedAt = Date()
                issue.updatedAt = Date()
                try? modelContext.save()
            } else {
                block.type = .paragraph
                block.indentLevel = 0
                block.updatedAt = Date()
                issue.updatedAt = Date()
                try? modelContext.save()
            }
            return
        }

        let newBlockType: BlockType
        let newIndentLevel: Int
        if block.type == .bulletList || block.type == .numberedList {
            newBlockType = block.type
            newIndentLevel = block.indentLevel
        } else {
            newBlockType = .paragraph
            newIndentLevel = 0
        }

        let newOrder = block.order + 1

        for nextBlock in sortedBlocks where nextBlock.order >= newOrder {
            nextBlock.order += 1
        }

        let newBlock = ContentBlock(type: newBlockType, content: "", order: newOrder, indentLevel: newIndentLevel, issue: issue)
        modelContext.insert(newBlock)
        issue.updatedAt = Date()
        try? modelContext.save()

        focusedBlockId = newBlock.id
    }

    private func handleBackspaceEmpty(on block: ContentBlock) {
        guard sortedBlocks.count > 1 else {
            if block.type != .paragraph {
                block.type = .paragraph
                issue.updatedAt = Date()
                try? modelContext.save()
            }
            return
        }

        guard let currentIndex = sortedBlocks.firstIndex(where: { $0.id == block.id }) else {
            return
        }

        if currentIndex > 0 {
            let previousBlock = sortedBlocks[currentIndex - 1]
            modelContext.delete(block)
            issue.updatedAt = Date()
            try? modelContext.save()
            reorderBlocks()
            focusedBlockId = previousBlock.id
            focusAtEndBlockId = previousBlock.id
        } else {
            modelContext.delete(block)
            issue.updatedAt = Date()
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
        targetCursorPosition = cursorPosition
        focusedBlockId = previousBlock.id

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
        targetCursorPosition = cursorPosition
        focusedBlockId = nextBlock.id

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
        focusedBlockId = previousBlock.id
        focusAtEndBlockId = previousBlock.id

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
        focusedBlockId = nextBlock.id
    }

    private func handleIndent(on block: ContentBlock) {
        guard block.type == .bulletList || block.type == .numberedList else {
            return
        }

        guard block.indentLevel < 5 else {
            return
        }

        block.indentLevel += 1
        block.updatedAt = Date()
        issue.updatedAt = Date()
        try? modelContext.save()
    }

    private func handleOutdent(on block: ContentBlock) {
        guard block.type == .bulletList || block.type == .numberedList else {
            return
        }

        if block.indentLevel > 0 {
            block.indentLevel -= 1
            block.updatedAt = Date()
            issue.updatedAt = Date()
            try? modelContext.save()
        } else {
            block.type = .paragraph
            block.indentLevel = 0
            block.updatedAt = Date()
            issue.updatedAt = Date()
            try? modelContext.save()
        }
    }

    private func calculateListNumber(for block: ContentBlock) -> Int? {
        guard block.type == .numberedList else {
            return nil
        }

        guard let currentIndex = sortedBlocks.firstIndex(where: { $0.id == block.id }) else {
            return 1
        }

        if currentIndex == 0 {
            return 1
        }

        for i in stride(from: currentIndex - 1, through: 0, by: -1) {
            let previousBlock = sortedBlocks[i]

            if previousBlock.type == .numberedList && previousBlock.indentLevel == block.indentLevel {
                if let previousNumber = calculateListNumber(for: previousBlock) {
                    return previousNumber + 1
                }
            }

            if previousBlock.indentLevel < block.indentLevel {
                break
            }
        }

        return 1
    }
}
