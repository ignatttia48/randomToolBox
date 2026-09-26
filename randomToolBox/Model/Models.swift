//
//  Models.swift
//  randomToolBox
//

import Foundation
import SwiftData

enum Tool: String, Codable, Hashable, CaseIterable {
    case wheel
    case coin
    case shuffle
    case lottery
}

@Model
final class OptionList {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \OptionItem.list)
    var items: [OptionItem] = []

    init(name: String, createdAt: Date = .now) {
        self.id = UUID()
        self.name = name
        self.createdAt = createdAt
    }

    var sortedItems: [OptionItem] {
        items.sorted { $0.sortIndex < $1.sortIndex }
    }
}

@Model
final class OptionItem {
    var label: String
    var weight: Int
    var isEliminated: Bool
    var sortIndex: Int
    var list: OptionList?

    init(label: String, weight: Int = 1, isEliminated: Bool = false, sortIndex: Int = 0) {
        self.label = label
        self.weight = weight
        self.isEliminated = isEliminated
        self.sortIndex = sortIndex
    }
}

@Model
final class DrawRecord {
    var tool: Tool
    var date: Date
    var listName: String?
    var resultText: String

    init(tool: Tool, date: Date = .now, listName: String? = nil, resultText: String) {
        self.tool = tool
        self.date = date
        self.listName = listName
        self.resultText = resultText
    }
}
