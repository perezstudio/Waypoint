//
//  ContentBlock.swift
//  Waypoint
//
//  Created by Claude on 11/14/25.
//

import Foundation
import SwiftData

enum BlockType: String, Codable {
    case heading1 = "heading1"
    case heading2 = "heading2"
    case heading3 = "heading3"
    case paragraph = "paragraph"
    case bulletList = "bulletList"
    case numberedList = "numberedList"
    case code = "code"
    case image = "image"

    var displayName: String {
        switch self {
        case .heading1: return "Heading 1"
        case .heading2: return "Heading 2"
        case .heading3: return "Heading 3"
        case .paragraph: return "Text"
        case .bulletList: return "Bulleted List"
        case .numberedList: return "Numbered List"
        case .code: return "Code"
        case .image: return "Image"
        }
    }

    var icon: String {
        switch self {
        case .heading1: return "textformat.size.larger"
        case .heading2: return "textformat.size"
        case .heading3: return "textformat.size.smaller"
        case .paragraph: return "text.alignleft"
        case .bulletList: return "list.bullet"
        case .numberedList: return "list.number"
        case .code: return "curlybraces"
        case .image: return "photo"
        }
    }
}

@Model
final class ContentBlock {
    var id: UUID
    var type: BlockType
    var content: String
    var order: Int
    var indentLevel: Int
    var createdAt: Date
    var updatedAt: Date

    var project: Project?
    var issue: Issue?

    init(type: BlockType = .paragraph, content: String = "", order: Int = 0, indentLevel: Int = 0, project: Project? = nil, issue: Issue? = nil) {
        self.id = UUID()
        self.type = type
        self.content = content
        self.order = order
        self.indentLevel = indentLevel
        self.createdAt = Date()
        self.updatedAt = Date()
        self.project = project
        self.issue = issue
    }
}
