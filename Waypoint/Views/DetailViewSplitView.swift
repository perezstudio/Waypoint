//
//  DetailViewSplitView.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/13/25.
//

import SwiftUI
import AppKit

struct DetailViewSplitView<Content: View, Inspector: View>: NSViewControllerRepresentable {
	let content: Content
	let inspector: Inspector
	@Binding var isInspectorVisible: Bool

	func makeNSViewController(context: Context) -> DetailViewSplitViewController {
		let splitViewController = DetailViewSplitViewController()

		// Create hosting controllers for SwiftUI views
		let contentHosting = NSHostingController(rootView: content)
		contentHosting.safeAreaRegions = []  // Remove all safe areas

		let inspectorHosting = NSHostingController(rootView: inspector)
		inspectorHosting.safeAreaRegions = []  // Remove all safe areas

		// Assign to split view controller
		splitViewController.contentViewController = contentHosting
		splitViewController.inspectorViewController = inspectorHosting
		splitViewController.isInspectorVisible = $isInspectorVisible

		// Store reference in coordinator
		context.coordinator.splitViewController = splitViewController

		return splitViewController
	}

	func updateNSViewController(_ nsViewController: DetailViewSplitViewController, context: Context) {
		// Don't interfere if already animating
		guard !nsViewController.isAnimating else { return }

		// Update inspector visibility if changed externally
		let totalWidth = nsViewController.splitView.frame.width
		let contentWidth = nsViewController.splitView.subviews.first?.frame.width ?? 0
		let inspectorWidth = totalWidth - contentWidth
		let isCurrentlyVisible = inspectorWidth > 10 // Use same threshold as controller

		if isCurrentlyVisible != isInspectorVisible {
			// Call the controller's method to handle visibility change
			nsViewController.setInspectorVisible(isInspectorVisible, animated: true)
		}

		// Update the SwiftUI views
		if let contentHosting = nsViewController.contentViewController as? NSHostingController<Content> {
			contentHosting.rootView = content
		}
		if let inspectorHosting = nsViewController.inspectorViewController as? NSHostingController<Inspector> {
			inspectorHosting.rootView = inspector
		}
	}

	func makeCoordinator() -> Coordinator {
		Coordinator(isInspectorVisible: $isInspectorVisible)
	}

	class Coordinator: NSObject {
		var splitViewController: DetailViewSplitViewController?
		@Binding var isInspectorVisible: Bool

		init(isInspectorVisible: Binding<Bool>) {
			self._isInspectorVisible = isInspectorVisible
		}
	}
}
