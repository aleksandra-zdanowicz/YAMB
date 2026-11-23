/// One player's turn: up to 3 rolls of 6 dice, holding dice, and an optional announcement.
public struct Turn: Codable, Equatable, Sendable {
    public static let diceCount = 6
    public static let maxRolls = 3

    public private(set) var dice: [Int] = Array(repeating: 1, count: diceCount)
    public private(set) var held: Set<Int> = []
    public private(set) var rollCount = 0
    public private(set) var announced: Row?

    public init() {}

    /// Restores a turn in a given state (saved games, a remote player's turn, tests).
    public init(dice: [Int], rollCount: Int, held: Set<Int> = [], announced: Row? = nil) {
        precondition(dice.count == Self.diceCount && dice.allSatisfy { (1...6).contains($0) })
        precondition((0...Self.maxRolls).contains(rollCount))
        self.dice = dice
        self.rollCount = rollCount
        self.held = held
        self.announced = announced
    }

    public var hasRolled: Bool { rollCount > 0 }
    public var canRoll: Bool { rollCount < Self.maxRolls }

    public enum TurnError: Error, Equatable {
        case noRollsLeft, notRolledYet, announceOnlyAfterFirstRoll, alreadyAnnounced, cellTaken
    }

    /// Rolls the dice. The first roll always rolls all 6.
    /// - Parameter all: true = "Roll all dice", false = "Roll unselected dice".
    public mutating func roll<R: RandomNumberGenerator>(all: Bool, using rng: inout R) throws {
        guard canRoll else { throw TurnError.noRollsLeft }
        let rollEverything = all || rollCount == 0
        if rollEverything { held = [] }
        for i in dice.indices where !held.contains(i) {
            dice[i] = Dice.roll(using: &rng)
        }
        rollCount += 1
    }

    public mutating func roll(all: Bool) throws {
        var rng = SystemRandomNumberGenerator()
        try roll(all: all, using: &rng)
    }

    /// Keep or release a die (by position 0–5).
    public mutating func toggleHold(_ index: Int) {
        guard hasRolled, dice.indices.contains(index) else { return }
        if held.contains(index) { held.remove(index) } else { held.insert(index) }
    }

    /// Announce a row. Only allowed right after the first roll.
    public mutating func announce(_ row: Row, on sheet: Sheet) throws {
        guard rollCount == 1 else { throw TurnError.announceOnlyAfterFirstRoll }
        guard announced == nil else { throw TurnError.alreadyAnnounced }
        guard sheet[.announce, row] == nil else { throw TurnError.cellTaken }
        announced = row
    }
}

/// Fair dice: `Int.random(in:using:)` draws uniformly (no modulo bias),
/// and the default generator is the system's cryptographically secure one.
public enum Dice {
    public static func roll<R: RandomNumberGenerator>(using rng: inout R) -> Int {
        Int.random(in: 1...6, using: &rng)
    }
}
