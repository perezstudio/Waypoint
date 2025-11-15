//
//  BlockNSTextView.swift
//  Waypoint
//
//  Created by Claude on 11/14/25.
//

import AppKit

class BlockNSTextView: NSTextView {
    // Callbacks for keyboard navigation
    var onMoveUp: ((Int) -> Void)?  // Now passes cursor position
    var onMoveDown: ((Int) -> Void)?  // Now passes cursor position
    var onMoveLeft: (() -> Void)?  // Move to end of previous block
    var onMoveRight: (() -> Void)?  // Move to start of next block
    var onSubmit: (() -> Void)?
    var onBackspaceEmpty: (() -> Void)?
    var onIndent: (() -> Void)?  // Handle Tab key for indenting
    var onOutdent: (() -> Void)?  // Handle Shift-Tab key for outdenting
    var onBecomeFirstResponder: (() -> Void)?

    override var acceptsFirstResponder: Bool {
        return true
    }

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result {
            onBecomeFirstResponder?()
        }
        return result
    }

    override func mouseDown(with event: NSEvent) {
        // Ensure we become first responder on click
        window?.makeFirstResponder(self)
        super.mouseDown(with: event)
    }

    override var intrinsicContentSize: NSSize {
        guard let layoutManager = layoutManager,
              let textContainer = textContainer else {
            return NSSize(width: NSView.noIntrinsicMetric, height: 30)
        }

        // Force layout
        layoutManager.ensureLayout(for: textContainer)

        // Get the used rect for the text container
        let usedRect = layoutManager.usedRect(for: textContainer)

        // Calculate height with text container inset
        let height = ceil(usedRect.height + textContainerInset.height * 2)

        // Ensure minimum height based on font
        let minHeight = (font?.pointSize ?? 13) * 1.5

        return NSSize(
            width: NSView.noIntrinsicMetric,
            height: max(height, minHeight)
        )
    }

    override func doCommand(by selector: Selector) {
        print("🔧 BlockNSTextView.doCommand called with selector: \(selector)")

        // Handle Enter key
        if selector == #selector(NSResponder.insertNewline(_:)) {
            print("✅ Enter key detected - calling onSubmit")
            onSubmit?()
            return
        }

        // Handle Delete/Backspace key
        if selector == #selector(NSResponder.deleteBackward(_:)) {
            if string.isEmpty {
                print("✅ Backspace on empty - calling onBackspaceEmpty")
                onBackspaceEmpty?()
                return
            }
        }

        // Handle Tab key
        if selector == #selector(NSResponder.insertTab(_:)) {
            print("⇥ Tab key - calling onIndent")
            onIndent?()
            return
        }

        // Handle Shift-Tab key
        if selector == #selector(NSResponder.insertBacktab(_:)) {
            print("⇤ Shift-Tab key - calling onOutdent")
            onOutdent?()
            return
        }

        // Handle Left arrow
        if selector == #selector(NSResponder.moveLeft(_:)) || selector == #selector(NSResponder.moveBackward(_:)) {
            let cursorPosition = selectedRange().location
            print("◀️ Left arrow - cursor at: \(cursorPosition)")
            if cursorPosition == 0 {
                print("✅ At start - moving to end of previous block")
                onMoveLeft?()
                return
            }
        }

        // Handle Right arrow
        if selector == #selector(NSResponder.moveRight(_:)) || selector == #selector(NSResponder.moveForward(_:)) {
            let cursorPosition = selectedRange().location
            print("▶️ Right arrow - cursor at: \(cursorPosition), length: \(string.count)")
            if cursorPosition == string.count {
                print("✅ At end - moving to start of next block")
                onMoveRight?()
                return
            }
        }

        // Handle Up arrow
        if selector == #selector(NSResponder.moveUp(_:)) {
            print("🔼 Up arrow - isOnFirstLine: \(isOnFirstLine())")
            if isOnFirstLine() {
                print("✅ Moving up to previous block")
                let cursorPosition = selectedRange().location
                print("📍 Current cursor position: \(cursorPosition)")
                onMoveUp?(cursorPosition)
                return
            }
        }

        // Handle Down arrow
        if selector == #selector(NSResponder.moveDown(_:)) {
            print("🔽 Down arrow - isOnLastLine: \(isOnLastLine())")
            if isOnLastLine() {
                print("✅ Moving down to next block")
                let cursorPosition = selectedRange().location
                print("📍 Current cursor position: \(cursorPosition)")
                onMoveDown?(cursorPosition)
                return
            }
        }

        // Let default handling occur
        super.doCommand(by: selector)
    }

    override func didChangeText() {
        super.didChangeText()

        // Invalidate intrinsic content size when text changes
        invalidateIntrinsicContentSize()
    }

    func isOnFirstLine() -> Bool {
        // Empty text is on first line
        if string.isEmpty {
            return true
        }

        guard let layoutManager = layoutManager,
              let _ = textContainer else {
            return true
        }

        let selectedRange = selectedRange()

        // No glyphs means first line
        if layoutManager.numberOfGlyphs == 0 {
            return true
        }

        // Bounds check
        guard selectedRange.location <= string.count else {
            return true
        }

        // If cursor is at the very end of the text, use the last character's position
        let characterIndex = selectedRange.location == string.count && string.count > 0
            ? string.count - 1
            : selectedRange.location

        let glyphIndex = layoutManager.glyphIndexForCharacter(at: characterIndex)
        var lineRange = NSRange()
        layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: &lineRange, withoutAdditionalLayout: true)

        return lineRange.location == 0
    }

    func isOnLastLine() -> Bool {
        // Empty text is on last line
        if string.isEmpty {
            return true
        }

        guard let layoutManager = layoutManager,
              let _ = textContainer else {
            return true
        }

        let selectedRange = selectedRange()

        // If no glyphs, we're on the last line
        let lastGlyphIndex = layoutManager.numberOfGlyphs - 1
        if lastGlyphIndex < 0 {
            return true
        }

        // Bounds check
        guard selectedRange.location <= string.count else {
            return true
        }

        // If cursor is at the very end of the text, use the last character's position
        let characterIndex = selectedRange.location == string.count && string.count > 0
            ? string.count - 1
            : selectedRange.location

        let glyphIndex = layoutManager.glyphIndexForCharacter(at: characterIndex)
        var lineRange = NSRange()
        layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: &lineRange, withoutAdditionalLayout: true)

        var lastLineRange = NSRange()
        layoutManager.lineFragmentRect(forGlyphAt: lastGlyphIndex, effectiveRange: &lastLineRange, withoutAdditionalLayout: true)

        return lineRange.location == lastLineRange.location
    }
}
