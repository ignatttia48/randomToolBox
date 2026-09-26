//
//  SpinEngine.swift
//  randomToolBox
//
//  Drives the wheel's rotation frame-by-frame instead of relying on
//  withAnimation, so the pointer position, tick haptics, and the final
//  winner are all derived from the same angle at every instant.
//

import Foundation

@Observable
final class SpinEngine {
    private(set) var rotation: Double = 0
    private(set) var tickCount: Int = 0
    private(set) var resultToken: Int = 0
    private(set) var isSpinning: Bool = false
    private(set) var winningIndex: Int?

    private let minimumExtraDegrees: Double = 4 * 360

    /// Spins the wheel and settles on a weighted-random winner among `weights`.
    /// Returns the winning index, or `nil` if every weight is zero (nothing to pick).
    @discardableResult
    func spin(weights: [Int], duration: Double) async -> Int? {
        guard let winner = RandomEngine.weightedPick(weights) else { return nil }
        let boundaries = Self.boundaries(for: weights)
        let winnerAngleInSector = Double.random(in: boundaries[winner]..<boundaries[winner + 1])
        let base = (360 - winnerAngleInSector).truncatingRemainder(dividingBy: 360)

        let normalizedCurrent = rotation.truncatingRemainder(dividingBy: 360)
        let currentBase = rotation - normalizedCurrent
        var target = currentBase + base
        while target <= rotation + minimumExtraDegrees {
            target += 360
        }

        isSpinning = true
        let start = rotation
        let startTime = Date()
        var lastSectorIndex = Self.sectorIndex(atRotation: rotation, boundaries: boundaries)

        while true {
            let elapsed = Date().timeIntervalSince(startTime)
            let t = min(elapsed / duration, 1)
            let eased = 1 - pow(1 - t, 3)
            rotation = start + (target - start) * eased

            let currentIndex = Self.sectorIndex(atRotation: rotation, boundaries: boundaries)
            if currentIndex != lastSectorIndex {
                tickCount += 1
                lastSectorIndex = currentIndex
            }

            if t >= 1 { break }
            try? await Task.sleep(nanoseconds: 16_000_000)
        }

        rotation = target
        winningIndex = winner
        resultToken += 1
        isSpinning = false
        return winner
    }

    func reset() {
        rotation = 0
        tickCount = 0
        winningIndex = nil
    }

    /// Cumulative angle boundaries (0...360) for each weight, proportional to its share of the total.
    static func boundaries(for weights: [Int]) -> [Double] {
        let total = weights.reduce(0) { $0 + max($1, 0) }
        guard total > 0 else { return [0, 360] }
        var result: [Double] = [0]
        var accumulated = 0.0
        for weight in weights {
            accumulated += Double(max(weight, 0)) / Double(total) * 360
            result.append(accumulated)
        }
        return result
    }

    /// Which sector sits under the fixed pointer (12 o'clock) after rotating the wheel by `rotation` degrees.
    static func sectorIndex(atRotation rotation: Double, boundaries: [Double]) -> Int {
        let normalized = rotation.truncatingRemainder(dividingBy: 360)
        let positive = normalized < 0 ? normalized + 360 : normalized
        let angle = (360 - positive).truncatingRemainder(dividingBy: 360)
        for index in 0..<(boundaries.count - 1) {
            if angle >= boundaries[index] && angle < boundaries[index + 1] {
                return index
            }
        }
        return max(boundaries.count - 2, 0)
    }
}
