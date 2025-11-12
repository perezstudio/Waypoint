//
//  SplitView.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/11/25.
//

import SwiftUI
import AppKit

struct SplitView<Sidebar: View, Detail: View>: NSViewControllerRepresentable {
    let sidebar: Sidebar
    let detail: Detail
    @Binding var isSidebarCollapsed: Bool

    func makeNSViewController(context: Context) -> WaypointSplitViewController {
        let splitViewController = WaypointSplitViewController()

        // Create hosting controllers for SwiftUI views
        let sidebarHosting = NSHostingController(rootView: sidebar)
        sidebarHosting.sizingOptions = [.intrinsicContentSize]
        sidebarHosting.safeAreaRegions = []  // Remove all safe areas

        let detailHosting = NSHostingController(rootView: detail)
        detailHosting.sizingOptions = [.intrinsicContentSize]
        detailHosting.safeAreaRegions = []  // Remove all safe areas

        // Assign to split view controller
        splitViewController.sidebarViewController = sidebarHosting
        splitViewController.detailViewController = detailHosting
        splitViewController.isSidebarCollapsed = $isSidebarCollapsed

        // Store reference in coordinator
        context.coordinator.splitViewController = splitViewController

        return splitViewController
    }

    func updateNSViewController(_ nsViewController: WaypointSplitViewController, context: Context) {
        // Update sidebar collapsed state if changed externally
        if let sidebarItem = nsViewController.splitViewItems.first,
           sidebarItem.isCollapsed != isSidebarCollapsed {
            nsViewController.setSidebarCollapsed(isSidebarCollapsed, animated: true)
        }

        // Update the SwiftUI views
        if let sidebarHosting = nsViewController.sidebarViewController as? NSHostingController<Sidebar> {
            sidebarHosting.rootView = sidebar
        }
        if let detailHosting = nsViewController.detailViewController as? NSHostingController<Detail> {
            detailHosting.rootView = detail
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isSidebarCollapsed: $isSidebarCollapsed)
    }

    class Coordinator: NSObject {
        var splitViewController: WaypointSplitViewController?
        @Binding var isSidebarCollapsed: Bool

        init(isSidebarCollapsed: Binding<Bool>) {
            self._isSidebarCollapsed = isSidebarCollapsed
        }
    }
}
