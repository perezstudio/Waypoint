//
//  WaypointSplitViewController.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/11/25.
//

import AppKit
import SwiftUI

class WaypointSplitViewController: NSSplitViewController {

    var sidebarViewController: NSViewController!
    var detailViewController: NSViewController!

    var isSidebarCollapsed: Binding<Bool>?

    override func loadView() {
        // Create and assign custom split view BEFORE calling super
        let customSplitView = TransparentDividerSplitView()
        customSplitView.isVertical = true  // Horizontal layout with vertical divider
        customSplitView.dividerStyle = .thin
        customSplitView.autosaveName = "WaypointMainSplitView"
        splitView = customSplitView

        // Now call super which will use our custom split view
        super.loadView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Sidebar split view item
        let sidebarItem = NSSplitViewItem(viewController: sidebarViewController)
        sidebarItem.canCollapse = true
        sidebarItem.holdingPriority = .defaultHigh + 1
        sidebarItem.minimumThickness = 200
        sidebarItem.maximumThickness = 800

        // Detail split view item
        let detailItem = NSSplitViewItem(viewController: detailViewController)
        detailItem.canCollapse = false

        // Add items
        addSplitViewItem(sidebarItem)
        addSplitViewItem(detailItem)
    }

    func toggleSidebar(animated: Bool = true) {
        guard let sidebarItem = splitViewItems.first else { return }

        if animated {
            sidebarItem.animator().isCollapsed.toggle()
        } else {
            sidebarItem.isCollapsed.toggle()
        }

        // Update binding
        isSidebarCollapsed?.wrappedValue = sidebarItem.isCollapsed
    }

    func setSidebarCollapsed(_ collapsed: Bool, animated: Bool = true) {
        guard let sidebarItem = splitViewItems.first else { return }

        if animated {
            sidebarItem.animator().isCollapsed = collapsed
        } else {
            sidebarItem.isCollapsed = collapsed
        }

        // Update binding
        isSidebarCollapsed?.wrappedValue = collapsed
    }
}

// MARK: - Custom Split View with Transparent Divider
class TransparentDividerSplitView: NSSplitView {
    override var dividerColor: NSColor {
        return .clear
    }

    override var dividerThickness: CGFloat {
        return 1.0  // Keep it interactive but invisible
    }

    override func drawDivider(in rect: NSRect) {
        // Don't draw anything - this makes it transparent
    }
}
