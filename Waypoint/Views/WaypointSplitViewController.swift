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
    var savedSidebarWidth: CGFloat = 350

    override func loadView() {
        // Create and assign custom split view BEFORE calling super
        let customSplitView = TransparentDividerSplitView()
        customSplitView.isVertical = true  // Horizontal layout with vertical divider
        customSplitView.dividerStyle = .thin
        splitView = customSplitView

        // Now call super which will use our custom split view
        super.loadView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set delegate to control collapse behavior
        splitView.delegate = self

        // Sidebar split view item
        let sidebarItem = NSSplitViewItem(viewController: sidebarViewController)
        sidebarItem.minimumThickness = 200
        sidebarItem.maximumThickness = 800
        sidebarItem.canCollapse = true  // Allow collapse
        sidebarItem.collapseBehavior = .preferResizingSiblingsWithFixedSplitView

        // Detail split view item
        let detailItem = NSSplitViewItem(viewController: detailViewController)
        detailItem.canCollapse = false

        // Add items
        addSplitViewItem(sidebarItem)
        addSplitViewItem(detailItem)

        // Set initial sidebar width after adding to split view
        DispatchQueue.main.async { [weak self] in
            self?.splitView.setPosition(350, ofDividerAt: 0)
        }
    }

    func toggleSidebar(animated: Bool = true) {
        let currentWidth = splitView.subviews.first?.frame.width ?? 0
        let isCurrentlyCollapsed = currentWidth < 1

        if isCurrentlyCollapsed {
            // Expand to saved width
            if animated {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.25
                    splitView.animator().setPosition(savedSidebarWidth, ofDividerAt: 0)
                }
            } else {
                splitView.setPosition(savedSidebarWidth, ofDividerAt: 0)
            }
            DispatchQueue.main.async { [weak self] in
                self?.isSidebarCollapsed?.wrappedValue = false
            }
        } else {
            // Save current width and collapse to 0
            savedSidebarWidth = currentWidth
            if animated {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.25
                    splitView.animator().setPosition(0, ofDividerAt: 0)
                }
            } else {
                splitView.setPosition(0, ofDividerAt: 0)
            }
            DispatchQueue.main.async { [weak self] in
                self?.isSidebarCollapsed?.wrappedValue = true
            }
        }
    }

    func setSidebarCollapsed(_ collapsed: Bool, animated: Bool = true) {
        let currentWidth = splitView.subviews.first?.frame.width ?? 0
        let isCurrentlyCollapsed = currentWidth < 1

        if collapsed && !isCurrentlyCollapsed {
            // Collapse
            savedSidebarWidth = currentWidth
            if animated {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.25
                    splitView.animator().setPosition(0, ofDividerAt: 0)
                }
            } else {
                splitView.setPosition(0, ofDividerAt: 0)
            }
        } else if !collapsed && isCurrentlyCollapsed {
            // Expand
            if animated {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.25
                    splitView.animator().setPosition(savedSidebarWidth, ofDividerAt: 0)
                }
            } else {
                splitView.setPosition(savedSidebarWidth, ofDividerAt: 0)
            }
        }

        // Update binding asynchronously to avoid modifying state during view update
        DispatchQueue.main.async { [weak self] in
            self?.isSidebarCollapsed?.wrappedValue = collapsed
        }
    }

    // MARK: - NSSplitViewDelegate Methods
    override func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        // Only allow sidebar (first subview) to collapse
        return subview == splitView.subviews.first
    }

    override func splitView(_ splitView: NSSplitView, shouldCollapseSubview subview: NSView, forDoubleClickOnDividerAt dividerIndex: Int) -> Bool {
        // Don't collapse on double-click
        return false
    }

    override func splitViewDidResizeSubviews(_ notification: Notification) {
        // Save sidebar width when user manually resizes
        if let sidebarWidth = splitView.subviews.first?.frame.width, sidebarWidth > 1 {
            savedSidebarWidth = sidebarWidth

            // Update binding to reflect actual state asynchronously
            let isCollapsed = sidebarWidth < 1
            if isSidebarCollapsed?.wrappedValue != isCollapsed {
                DispatchQueue.main.async { [weak self] in
                    self?.isSidebarCollapsed?.wrappedValue = isCollapsed
                }
            }
        }
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
