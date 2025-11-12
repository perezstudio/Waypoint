//
//  WindowAccessor.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/11/25.
//

import SwiftUI
import AppKit

struct WindowAccessor: NSViewRepresentable {
    let configure: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()

        DispatchQueue.main.async {
            if let window = view.window {
                configure(window)
                // Setup resize observer
                context.coordinator.setupObserver(for: window)
            }
        }

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let window = nsView.window {
            configure(window)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(configure: configure)
    }

    class Coordinator: NSObject {
        let configure: (NSWindow) -> Void
        var observer: NSObjectProtocol?

        init(configure: @escaping (NSWindow) -> Void) {
            self.configure = configure
        }

        func setupObserver(for window: NSWindow) {
            // Remove existing observer if any
            if let observer = observer {
                NotificationCenter.default.removeObserver(observer)
            }

            // Add observer for window resize
            observer = NotificationCenter.default.addObserver(
                forName: NSWindow.didResizeNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                self?.configure(window)
            }
        }

        deinit {
            if let observer = observer {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
}

extension View {
    func configureWindow(_ configure: @escaping (NSWindow) -> Void) -> some View {
        background(WindowAccessor(configure: configure))
    }
}

// Helper extension to position traffic light buttons
extension NSWindow {
    func setTrafficLightPosition(x: CGFloat, y: CGFloat) {
        // Position each button individually
        if let closeButton = standardWindowButton(.closeButton) {
            closeButton.setFrameOrigin(NSPoint(x: x, y: y))
        }
        if let miniaturizeButton = standardWindowButton(.miniaturizeButton) {
            miniaturizeButton.setFrameOrigin(NSPoint(x: x + 20, y: y))
        }
        if let zoomButton = standardWindowButton(.zoomButton) {
            zoomButton.setFrameOrigin(NSPoint(x: x + 40, y: y))
        }
    }
}
