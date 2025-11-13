//
//  DetailViewSplitViewController.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/13/25.
//

import AppKit
import SwiftUI

class DetailViewSplitViewController: NSSplitViewController {

	var contentViewController: NSViewController!
	var inspectorViewController: NSViewController!

	var isInspectorVisible: Binding<Bool>?
	var savedInspectorWidth: CGFloat = 280
	var isAnimating: Bool = false

	override func loadView() {
		// Create and assign custom split view BEFORE calling super
		let customSplitView = DetailInspectorSplitView()
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

		// Content split view item (left side) - flexible
		let contentItem = NSSplitViewItem(viewController: contentViewController)
		contentItem.canCollapse = false

		// Inspector split view item (right side) - resizable with constraints
		let inspectorItem = NSSplitViewItem(viewController: inspectorViewController)
		// Don't set minimumThickness here - handle it in constrainSplitPosition instead
		// This allows the inspector to collapse fully when dragged
		inspectorItem.maximumThickness = 400
		inspectorItem.canCollapse = true
		inspectorItem.collapseBehavior = .preferResizingSiblingsWithFixedSplitView

		// Add items
		addSplitViewItem(contentItem)
		addSplitViewItem(inspectorItem)

		// Set initial inspector width based on visibility
		// Use a longer delay to ensure frame is properly calculated
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
			guard let self = self else { return }
			let totalWidth = self.splitView.frame.width

			if self.isInspectorVisible?.wrappedValue == true {
				// Show inspector at saved width
				self.splitView.setPosition(totalWidth - self.savedInspectorWidth, ofDividerAt: 0)
			} else {
				// Start fully collapsed - inspector has 0 width
				self.splitView.setPosition(totalWidth, ofDividerAt: 0)
			}
		}
	}

	func setInspectorVisible(_ visible: Bool, animated: Bool = true) {
		isAnimating = true

		let totalWidth = splitView.frame.width
		let currentDividerPosition = splitView.subviews.first?.frame.width ?? 0
		let currentInspectorWidth = totalWidth - currentDividerPosition
		let isCurrentlyVisible = currentInspectorWidth > 10 // Use 10 as threshold instead of 1

		if visible && !isCurrentlyVisible {
			// Show inspector
			// Ensure saved width is valid
			if savedInspectorWidth < 200 || savedInspectorWidth > 400 {
				savedInspectorWidth = 280 // Reset to default
			}

			let newPosition = totalWidth - savedInspectorWidth
			if animated {
				NSAnimationContext.runAnimationGroup({ context in
					context.duration = 0.25
					context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
					self.splitView.animator().setPosition(newPosition, ofDividerAt: 0)
				}, completionHandler: { [weak self] in
					self?.isAnimating = false
				})
			} else {
				splitView.setPosition(newPosition, ofDividerAt: 0)
				isAnimating = false
			}
		} else if !visible && isCurrentlyVisible {
			// Hide inspector - save current width first
			if currentInspectorWidth > 10 {
				savedInspectorWidth = currentInspectorWidth
			}
			if animated {
				NSAnimationContext.runAnimationGroup({ context in
					context.duration = 0.25
					context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
					self.splitView.animator().setPosition(totalWidth, ofDividerAt: 0)
				}, completionHandler: { [weak self] in
					self?.isAnimating = false
				})
			} else {
				splitView.setPosition(totalWidth, ofDividerAt: 0)
				isAnimating = false
			}
		} else {
			isAnimating = false
		}

		// Update binding asynchronously to avoid modifying state during view update
		DispatchQueue.main.async { [weak self] in
			self?.isInspectorVisible?.wrappedValue = visible
		}
	}

	// MARK: - NSSplitViewDelegate Methods
	override func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
		// Only allow inspector (second subview) to collapse
		return subview == splitView.subviews.last
	}

	override func splitView(_ splitView: NSSplitView, shouldCollapseSubview subview: NSView, forDoubleClickOnDividerAt dividerIndex: Int) -> Bool {
		// Don't collapse on double-click
		return false
	}

	override func splitView(_ splitView: NSSplitView, constrainSplitPosition proposedPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
		// This is the autolayout-compatible version for constraining position
		let totalWidth = splitView.bounds.width
		let maxInspectorWidth: CGFloat = 400
		let minInspectorWidth: CGFloat = 200
		let collapseThreshold: CGFloat = 100 // If dragged within 100px of edge, allow collapse

		// Calculate the min position (when inspector is at max width)
		let minPosition = totalWidth - maxInspectorWidth

		// Calculate the max position for minimum width
		let maxPositionForMinWidth = totalWidth - minInspectorWidth

		// Calculate the collapse threshold position
		let collapseThresholdPosition = totalWidth - collapseThreshold

		// Constrain the proposed position
		if proposedPosition < minPosition {
			// Don't allow inspector to be larger than max width
			return minPosition
		} else if proposedPosition >= collapseThresholdPosition {
			// User is dragging close to the edge - allow full collapse
			return totalWidth
		} else if proposedPosition > maxPositionForMinWidth {
			// User is between min width and collapse threshold
			// Snap to min width to prevent awkward in-between sizes
			return maxPositionForMinWidth
		}

		return proposedPosition
	}

	override func splitViewDidResizeSubviews(_ notification: Notification) {
		// Don't interfere during programmatic animations
		guard !isAnimating else { return }

		// Save inspector width when user manually resizes
		let totalWidth = splitView.frame.width
		let contentWidth = splitView.subviews.first?.frame.width ?? 0
		let inspectorWidth = totalWidth - contentWidth

		if inspectorWidth > 50 {
			// Inspector is visible and has meaningful width - save it
			savedInspectorWidth = inspectorWidth

			// Update binding to reflect actual state asynchronously
			if isInspectorVisible?.wrappedValue != true {
				DispatchQueue.main.async { [weak self] in
					self?.isInspectorVisible?.wrappedValue = true
				}
			}
		} else if inspectorWidth <= 10 {
			// Inspector is fully collapsed
			// Ensure we have a valid saved width before marking as closed
			if savedInspectorWidth < 200 {
				savedInspectorWidth = 280 // Reset to default if invalid
			}

			if isInspectorVisible?.wrappedValue == true {
				DispatchQueue.main.async { [weak self] in
					self?.isInspectorVisible?.wrappedValue = false
				}
			}
		}
		// Note: If inspector width is between 10 and 50, we're in transition - don't update state
	}
}

// MARK: - Custom Split View with Visible Divider
class DetailInspectorSplitView: NSSplitView {
	override var dividerColor: NSColor {
		return NSColor.separatorColor
	}

	override var dividerThickness: CGFloat {
		return 1.0
	}

	override func drawDivider(in rect: NSRect) {
		dividerColor.setFill()
		rect.fill()
	}
}
