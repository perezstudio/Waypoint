//
//  BlockTextView.swift
//  Waypoint
//
//  Created by Claude on 11/14/25.
//

import SwiftUI
import AppKit

struct BlockTextView: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var font: NSFont
    var textColor: NSColor
    var requestFocus: Bool  // Changed from isFocused
    var moveCursorToEnd: Bool
    var targetCursorPosition: Int?  // For maintaining cursor column during navigation
    var onBecameFocused: () -> Void
    var onMoveUp: (Int) -> Void  // Now passes cursor position
    var onMoveDown: (Int) -> Void  // Now passes cursor position
    var onMoveLeft: () -> Void  // Move to end of previous block
    var onMoveRight: () -> Void  // Move to start of next block
    var onSubmit: () -> Void
    var onBackspaceEmpty: () -> Void
    var onIndent: () -> Void  // Handle Tab key for indenting
    var onOutdent: () -> Void  // Handle Shift-Tab key for outdenting
    var onTextChange: (String) -> Void

    func makeNSView(context: Context) -> BlockNSTextView {
        print("🏗️ BlockTextView.makeNSView - Creating NEW text view")
        let textView = BlockNSTextView()

        // Configure the text view
        textView.delegate = context.coordinator
        textView.font = font
        textView.textColor = textColor
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.isRichText = false
        textView.importsGraphics = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.textContainerInset = NSSize(width: 0, height: 4)
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

        // Set callbacks
        textView.onBecomeFirstResponder = onBecameFocused
        textView.onMoveUp = onMoveUp
        textView.onMoveDown = onMoveDown
        textView.onMoveLeft = onMoveLeft
        textView.onMoveRight = onMoveRight
        textView.onSubmit = onSubmit
        textView.onBackspaceEmpty = onBackspaceEmpty
        textView.onIndent = onIndent
        textView.onOutdent = onOutdent

        return textView
    }

    func updateNSView(_ textView: BlockNSTextView, context: Context) {
        print("🔄 BlockTextView.updateNSView - requestFocus: \(requestFocus), moveCursorToEnd: \(moveCursorToEnd)")

        // Update text if needed
        if textView.string != text {
            let currentSelectedRange = textView.selectedRange()
            textView.string = text
            // Restore selection if valid
            if currentSelectedRange.location <= text.count {
                textView.setSelectedRange(currentSelectedRange)
            }
        }

        // Update font and color
        textView.font = font
        textView.textColor = textColor

        // Update callbacks
        textView.onBecomeFirstResponder = onBecameFocused
        textView.onMoveUp = onMoveUp
        textView.onMoveDown = onMoveDown
        textView.onMoveLeft = onMoveLeft
        textView.onMoveRight = onMoveRight
        textView.onSubmit = onSubmit
        textView.onBackspaceEmpty = onBackspaceEmpty
        textView.onIndent = onIndent
        textView.onOutdent = onOutdent

        // Direct first responder management - only set cursor if NOT already first responder
        if requestFocus {
            // Check if we're already the first responder
            let isAlreadyFirstResponder = textView.window?.firstResponder == textView
            print("🎯 Focus requested! isAlreadyFirstResponder: \(isAlreadyFirstResponder)")

            if !isAlreadyFirstResponder {
                // We need to become first responder
                print("🎯 Attempting to make first responder...")

                // Try immediate focus
                if let window = textView.window {
                    let didBecome = window.makeFirstResponder(textView)
                    print("🎯 makeFirstResponder result: \(didBecome)")

                    if didBecome {
                        // Determine cursor position
                        let cursorLocation: Int
                        if let targetPosition = targetCursorPosition {
                            // Use target position (column from previous block), capped at text length
                            cursorLocation = min(targetPosition, textView.string.count)
                            print("📍 Cursor moved to target position (location: \(cursorLocation), target: \(targetPosition))")
                        } else if moveCursorToEnd {
                            cursorLocation = textView.string.count
                            print("📍 Cursor moved to end (location: \(cursorLocation))")
                        } else {
                            cursorLocation = 0
                            print("📍 Cursor moved to beginning")
                        }
                        textView.setSelectedRange(NSRange(location: cursorLocation, length: 0))
                    }
                } else {
                    print("❌ Text view has no window, trying async...")
                    // No window yet, try async
                    DispatchQueue.main.async {
                        if let window = textView.window {
                            let didBecome = window.makeFirstResponder(textView)
                            print("🎯 makeFirstResponder result (async): \(didBecome)")
                            if didBecome {
                                let cursorLocation: Int
                                if let targetPosition = targetCursorPosition {
                                    cursorLocation = min(targetPosition, textView.string.count)
                                } else if moveCursorToEnd {
                                    cursorLocation = textView.string.count
                                } else {
                                    cursorLocation = 0
                                }
                                textView.setSelectedRange(NSRange(location: cursorLocation, length: 0))
                            }
                        }
                    }
                }
            } else {
                // Already first responder, only reposition if explicitly requested
                if let targetPosition = targetCursorPosition {
                    let cursorLocation = min(targetPosition, textView.string.count)
                    textView.setSelectedRange(NSRange(location: cursorLocation, length: 0))
                    print("📍 Already focused - cursor moved to target position (location: \(cursorLocation), target: \(targetPosition))")
                } else if moveCursorToEnd {
                    let endLocation = textView.string.count
                    textView.setSelectedRange(NSRange(location: endLocation, length: 0))
                    print("📍 Already focused - cursor moved to end (location: \(endLocation))")
                }
                // Don't move cursor if no explicit positioning requested
                print("✅ Already first responder")
            }
        }

        // Update coordinator callback
        context.coordinator.onTextChange = onTextChange
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onTextChange: onTextChange)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String
        var onTextChange: (String) -> Void

        init(text: Binding<String>, onTextChange: @escaping (String) -> Void) {
            self._text = text
            self.onTextChange = onTextChange
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            let newText = textView.string
            if newText != text {
                text = newText
                onTextChange(newText)
            }
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            guard let blockTextView = textView as? BlockNSTextView else { return false }
            print("🎹 Coordinator.textView doCommandBy: \(commandSelector)")

            // Handle Enter key
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                print("✅ DELEGATE: Enter key - calling onSubmit")
                blockTextView.onSubmit?()
                return true // Prevent default behavior
            }

            // Handle Delete/Backspace key
            if commandSelector == #selector(NSResponder.deleteBackward(_:)) {
                if textView.string.isEmpty {
                    print("✅ DELEGATE: Backspace on empty - calling onBackspaceEmpty")
                    blockTextView.onBackspaceEmpty?()
                    return true
                }
                return false // Allow default backspace
            }

            // Handle Tab key
            if commandSelector == #selector(NSResponder.insertTab(_:)) {
                print("⇥ DELEGATE: Tab key - calling onIndent")
                blockTextView.onIndent?()
                return true
            }

            // Handle Shift-Tab key
            if commandSelector == #selector(NSResponder.insertBacktab(_:)) {
                print("⇤ DELEGATE: Shift-Tab key - calling onOutdent")
                blockTextView.onOutdent?()
                return true
            }

            // Handle Left arrow
            if commandSelector == #selector(NSResponder.moveLeft(_:)) || commandSelector == #selector(NSResponder.moveBackward(_:)) {
                let cursorPosition = textView.selectedRange().location
                print("◀️ DELEGATE: Left arrow - cursor at: \(cursorPosition)")
                if cursorPosition == 0 {
                    print("✅ DELEGATE: At start - calling onMoveLeft")
                    blockTextView.onMoveLeft?()
                    return true
                }
                return false // Allow default left movement
            }

            // Handle Right arrow
            if commandSelector == #selector(NSResponder.moveRight(_:)) || commandSelector == #selector(NSResponder.moveForward(_:)) {
                let cursorPosition = textView.selectedRange().location
                print("▶️ DELEGATE: Right arrow - cursor at: \(cursorPosition), length: \(textView.string.count)")
                if cursorPosition == textView.string.count {
                    print("✅ DELEGATE: At end - calling onMoveRight")
                    blockTextView.onMoveRight?()
                    return true
                }
                return false // Allow default right movement
            }

            // Handle Up arrow
            if commandSelector == #selector(NSResponder.moveUp(_:)) {
                if blockTextView.isOnFirstLine() {
                    print("✅ DELEGATE: Up arrow on first line - calling onMoveUp")
                    let cursorPosition = textView.selectedRange().location
                    print("📍 DELEGATE: Current cursor position: \(cursorPosition)")
                    blockTextView.onMoveUp?(cursorPosition)
                    return true
                }
                return false // Allow default up movement
            }

            // Handle Down arrow
            if commandSelector == #selector(NSResponder.moveDown(_:)) {
                if blockTextView.isOnLastLine() {
                    print("✅ DELEGATE: Down arrow on last line - calling onMoveDown")
                    let cursorPosition = textView.selectedRange().location
                    print("📍 DELEGATE: Current cursor position: \(cursorPosition)")
                    blockTextView.onMoveDown?(cursorPosition)
                    return true
                }
                return false // Allow default down movement
            }

            return false // Allow default handling for all other commands
        }
    }
}
