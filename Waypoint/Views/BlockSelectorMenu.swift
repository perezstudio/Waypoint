//
//  BlockSelectorMenu.swift
//  Waypoint
//
//  Created by Claude on 11/14/25.
//

import SwiftUI

struct BlockSelectorMenu: View {
    let onSelect: (BlockType) -> Void
    let onDismiss: () -> Void
    @State private var selectedIndex = 0
    @State private var searchText = ""

    private let allBlockTypes: [BlockType] = [
        .heading1, .heading2, .heading3,
        .paragraph, .bulletList, .numberedList,
        .code, .image
    ]

    private var filteredBlockTypes: [BlockType] {
        if searchText.isEmpty {
            return allBlockTypes
        }
        return allBlockTypes.filter { blockType in
            blockType.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(filteredBlockTypes.enumerated()), id: \.element) { index, blockType in
                Button(action: {
                    onSelect(blockType)
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: blockType.icon)
                            .frame(width: 20)
                            .foregroundStyle(.blue)

                        Text(blockType.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.primary)

                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(selectedIndex == index ? Color.accentColor.opacity(0.1) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .frame(width: 280)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .onAppear {
            selectedIndex = 0
        }
    }
}

struct BlockSelectorPopover: View {
    @Binding var isPresented: Bool
    @Binding var searchText: String
    let onSelect: (BlockType) -> Void
    @State private var selectedIndex = 0
    @FocusState private var isFocused: Bool

    private let allBlockTypes: [BlockType] = [
        .heading1, .heading2, .heading3,
        .paragraph, .bulletList, .numberedList,
        .code, .image
    ]

    private var filteredBlockTypes: [BlockType] {
        if searchText.isEmpty {
            return allBlockTypes
        }
        return allBlockTypes.filter { blockType in
            blockType.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        menuContent
            .focusable()
            .focused($isFocused)
            .focusEffectDisabled()
            .onKeyPress(.upArrow) { handleUpArrow() }
            .onKeyPress(.downArrow) { handleDownArrow() }
            .onKeyPress(.return) { handleReturn() }
            .onKeyPress(.escape) { handleEscape() }
            .onKeyPress(keys: ["1", "2", "3", "4", "5", "6", "7", "8", "9"]) { handleNumberKey($0) }
            .onChange(of: searchText) { oldValue, newValue in
                selectedIndex = 0
            }
            .onChange(of: filteredBlockTypes) { oldValue, newValue in
                if selectedIndex >= newValue.count {
                    selectedIndex = max(0, newValue.count - 1)
                }
            }
            .onAppear {
                selectedIndex = 0
                isFocused = true
            }
    }

    private var menuContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(filteredBlockTypes.enumerated()), id: \.element) { index, blockType in
                blockTypeRow(index: index, blockType: blockType)
            }
        }
        .padding(8)
        .frame(width: 300)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    private func blockTypeRow(index: Int, blockType: BlockType) -> some View {
        Button(action: {
            onSelect(blockType)
            isPresented = false
        }) {
            HStack(spacing: 12) {
                Text("\(index + 1)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 16)

                Image(systemName: blockType.icon)
                    .frame(width: 20)
                    .foregroundStyle(.blue)

                Text(blockType.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(selectedIndex == index ? Color.accentColor.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    private func handleUpArrow() -> KeyPress.Result {
        if selectedIndex > 0 {
            selectedIndex -= 1
        }
        return .handled
    }

    private func handleDownArrow() -> KeyPress.Result {
        if selectedIndex < filteredBlockTypes.count - 1 {
            selectedIndex += 1
        }
        return .handled
    }

    private func handleReturn() -> KeyPress.Result {
        if selectedIndex < filteredBlockTypes.count {
            onSelect(filteredBlockTypes[selectedIndex])
            isPresented = false
        }
        return .handled
    }

    private func handleEscape() -> KeyPress.Result {
        isPresented = false
        return .handled
    }

    private func handleNumberKey(_ keyPress: KeyPress) -> KeyPress.Result {
        // Map key to number (1-9)
        let keyToNumber: [KeyEquivalent: Int] = [
            "1": 1, "2": 2, "3": 3, "4": 4, "5": 5,
            "6": 6, "7": 7, "8": 8, "9": 9
        ]

        if let number = keyToNumber[keyPress.key],
           number <= filteredBlockTypes.count {
            onSelect(filteredBlockTypes[number - 1])
            isPresented = false
            return .handled
        }
        return .ignored
    }
}
