//
//  IconButtonStyle.swift
//  Waypoint
//
//  Created by Kevin Perez on 11/11/25.
//

import SwiftUI

struct IconButtonStyle: ButtonStyle {
    var isActive: Bool = false
    var size: CGFloat = 28
    var cornerRadius: CGFloat = 6

    func makeBody(configuration: Configuration) -> some View {
        Row(configuration: configuration, isActive: isActive, size: size, cornerRadius: cornerRadius)
    }

    private struct Row: View {
        let configuration: Configuration
        let isActive: Bool
        let size: CGFloat
        let cornerRadius: CGFloat
        @State private var isHovering: Bool = false

        var body: some View {
            configuration.label
                .frame(width: size, height: size)
                .background {
                    if isActive || isHovering {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.quaternary)
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color.secondary.opacity(0.15))
                            .opacity(0)
                    }
                }
                .contentShape(Rectangle())
                .onHover { inside in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isHovering = inside
                    }
                }
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
                .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        }
    }
}
