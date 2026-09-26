//
//  RandomEngine.swift
//  randomToolBox
//

import Foundation

enum RandomEngine {
    /// Picks an index from `weights` proportionally to each weight. Weights <= 0 are treated as 0 and never picked.
    static func weightedPick(_ weights: [Int], using generator: inout some RandomNumberGenerator) -> Int? {
        let total = weights.reduce(0) { $0 + max($1, 0) }
        guard total > 0 else { return nil }
        var target = Int.random(in: 0..<total, using: &generator)
        for (index, weight) in weights.enumerated() {
            let clamped = max(weight, 0)
            if target < clamped {
                return index
            }
            target -= clamped
        }
        return weights.indices.last
    }

    static func weightedPick(_ weights: [Int]) -> Int? {
        var generator = SystemRandomNumberGenerator()
        return weightedPick(weights, using: &generator)
    }

    static func shuffled<T>(_ items: [T], using generator: inout some RandomNumberGenerator) -> [T] {
        items.shuffled(using: &generator)
    }

    static func shuffled<T>(_ items: [T]) -> [T] {
        items.shuffled()
    }
}
