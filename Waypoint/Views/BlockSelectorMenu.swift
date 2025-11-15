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
                    isPresented = false
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
        .onKeyPress(.upArrow) {
            if selectedIndex > 0 {
                selectedIndex -= 1
            }
            return .handled
        }
        .onKeyPress(.downArrow) {
            if selectedIndex < filteredBlockTypes.count - 1 {
                selectedIndex += 1
            }
            return .handled
        }
        .onKeyPress(.return) {
            if selectedIndex < filteredBlockTypes.count {
                onSelect(filteredBlockTypes[selectedIndex])
                isPresented = false
            }
            return .handled
        }
        .onKeyPress(.escape) {
            isPresented = false
            return .handled
        }
        .onChange(of: searchText) { oldValue, newValue in
            selectedIndex = 0
        }
        .onChange(of: filteredBlockTypes) { oldValue, newValue in
            if selectedIndex >= newValue.count {
                selectedIndex = max(0, newValue.count - 1)
            }
        }
    }
}
