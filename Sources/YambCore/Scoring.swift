/// Pure scoring functions. See RULES.md.
public enum Scoring {
    public static let upperBonusThreshold = 60
    public static let upperBonus = 30
    public static let fullBonus = 30
    public static let pokerBonus = 40
    public static let yambBonus = 50

    /// Quint points by the roll it was completed on (1, 2 or 3).
    public static func quintPoints(rollNumber: Int) -> Int {
        switch rollNumber {
        case 1: return 66
        case 2: return 56
        default: return 46
        }
    }

    /// Score of exactly 5 dice in a row.
    /// Returns nil when the dice don't qualify for the row (the cell can only be crossed out).
    public static func score(_ row: Row, fiveDice dice: [Int], rollNumber: Int) -> Int? {
        precondition(dice.count == 5, "scoring always uses exactly 5 dice")
        let counts = faceCounts(dice)
        let total = dice.reduce(0, +)

        switch row {
        case .ones, .twos, .threes, .fours, .fives, .sixes:
            let face = row.face!
            return face * counts[face]

        case .max, .min:
            return total

        case .quint:
            let sorted = dice.sorted()
            return (sorted == [1, 2, 3, 4, 5] || sorted == [2, 3, 4, 5, 6])
                ? quintPoints(rollNumber: rollNumber) : nil

        case .full:
            // 3 + 2 of two different faces; five of a kind does not count.
            let nonZero = counts.filter { $0 > 0 }.sorted()
            return nonZero == [2, 3] ? total + fullBonus : nil

        case .poker:
            // At least four of a kind; only the four matching dice count.
            guard let face = (1...6).first(where: { counts[$0] >= 4 }) else { return nil }
            return face * 4 + pokerBonus

        case .yamb:
            guard let face = (1...6).first(where: { counts[$0] == 5 }) else { return nil }
            return face * 5 + yambBonus
        }
    }

    /// Best score for a row from 5 or 6 dice, picking the best 5.
    /// "Best" means highest, except for Min where lower is better.
    /// Returns nil when no choice of 5 dice qualifies.
    public static func bestScore(_ row: Row, dice: [Int], rollNumber: Int) -> Int? {
        let options = fiveDiceChoices(dice).compactMap { score(row, fiveDice: $0, rollNumber: rollNumber) }
        return row == .min ? options.min() : options.max()
    }

    /// The 5 dice that give `bestScore` (useful for highlighting in the UI).
    public static func bestFive(_ row: Row, dice: [Int], rollNumber: Int) -> [Int]? {
        let scored = fiveDiceChoices(dice).compactMap { five -> ([Int], Int)? in
            score(row, fiveDice: five, rollNumber: rollNumber).map { (five, $0) }
        }
        let pick = row == .min ? scored.min { $0.1 < $1.1 } : scored.max { $0.1 < $1.1 }
        return pick?.0
    }

    /// Every score a row can actually get (X not included), sorted low to high.
    /// Used by sheet-only mode so only valid scores can be entered.
    public static func possibleScores(_ row: Row) -> [Int] {
        possibleScoreTable[row] ?? []
    }

    private static let possibleScoreTable: [Row: [Int]] = {
        var table: [Row: Set<Int>] = [:]
        var dice = [1, 1, 1, 1, 1]
        func visit(_ i: Int) {
            if i == 5 {
                for row in Row.allCases {
                    for roll in 1...3 {
                        if let s = score(row, fiveDice: dice, rollNumber: roll) { table[row, default: []].insert(s) }
                    }
                }
                return
            }
            for face in 1...6 {
                dice[i] = face
                visit(i + 1)
            }
        }
        visit(0)
        return table.mapValues { $0.sorted() }
    }()

    // MARK: - Helpers

    /// counts[f] = how many dice show face f (index 0 unused).
    static func faceCounts(_ dice: [Int]) -> [Int] {
        var counts = Array(repeating: 0, count: 7)
        for d in dice { counts[d] += 1 }
        return counts
    }

    static func fiveDiceChoices(_ dice: [Int]) -> [[Int]] {
        precondition(dice.count == 5 || dice.count == 6, "need 5 or 6 dice")
        precondition(dice.allSatisfy { (1...6).contains($0) }, "dice must show 1–6")
        if dice.count == 5 { return [dice] }
        return dice.indices.map { skip in
            dice.enumerated().filter { $0.offset != skip }.map(\.element)
        }
    }
}
