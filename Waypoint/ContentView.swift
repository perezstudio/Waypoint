//
//  ContentView.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/11/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
	@State private var isInspectorVisible: Bool = false
	@State private var isSidebarCollapsed: Bool = false

    var body: some View {
		SplitView(
			sidebar: SidebarView(isSidebarCollapsed: $isSidebarCollapsed),
			detail: DetailPaneView(isInspectorVisible: $isInspectorVisible),
			isSidebarCollapsed: $isSidebarCollapsed
		)
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.ignoresSafeArea()
		.configureWindow { window in
			// Remove toolbar completely
			window.toolbar = nil

			// Configure title bar for edge-to-edge content
			window.titlebarAppearsTransparent = true
			window.titleVisibility = .hidden
			window.titlebarSeparatorStyle = .none

			// Full size content view
			window.styleMask.insert(.fullSizeContentView)

			// Make traffic lights visible
			window.standardWindowButton(.closeButton)?.isHidden = false
			window.standardWindowButton(.miniaturizeButton)?.isHidden = false
			window.standardWindowButton(.zoomButton)?.isHidden = false

			// Position traffic lights - leave them in default position for now
			// We'll adjust this based on sidebar state later
		}
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
