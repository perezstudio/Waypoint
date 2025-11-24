//
//  AppIcon.swift
//  Waypoint
//
//  Created by Claude Code
//

import Foundation

enum AppIcon {
    // Define icon categories
    enum Category {
        case space
        case project
        case tag
        case all
    }

    // Centralized icon catalog for spaces
    static let spaceIcons: [String] = [
        "person.3.fill", "person.2.fill", "person.fill",
        "figure.2", "figure.walk", "figure.wave",
        "person.crop.circle.fill", "person.crop.square.fill",
        "hand.raised.fill", "hand.thumbsup.fill", "hands.sparkles.fill",
        "heart.fill", "star.fill", "flag.fill",
        "shield.fill", "crown.fill", "medal.fill"
    ]

    // Centralized icon catalog for projects
    static let projectIcons: [String] = [
        "folder.fill", "star.fill", "heart.fill", "flag.fill",
        "bolt.fill", "lightbulb.fill", "gear", "hammer.fill",
        "wrench.fill", "paintbrush.fill", "photo.fill", "video.fill",
        "music.note", "book.fill", "graduationcap.fill", "briefcase.fill",
        "cart.fill", "creditcard.fill", "chart.bar.fill", "chart.xyaxis.line",
        "safari.fill", "iphone", "laptopcomputer", "desktopcomputer"
    ]

    // Centralized icon catalog for tags
    static let tagIcons: [String] = [
        "tag", "tag.fill", "bookmark", "bookmark.fill",
        "star", "star.fill", "flag", "flag.fill",
        "circle", "circle.fill", "square", "square.fill",
        "heart", "heart.fill", "exclamationmark", "exclamationmark.circle.fill"
    ]

    // Get icons for specific category
    static func icons(for category: Category) -> [String] {
        switch category {
        case .space:
            return spaceIcons
        case .project:
            return projectIcons
        case .tag:
            return tagIcons
        case .all:
            // Return unique icons from all categories, sorted
            return Array(Set(spaceIcons + projectIcons + tagIcons)).sorted()
        }
    }
}
