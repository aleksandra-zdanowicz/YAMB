/// A single player's game with app-rolled dice: their sheet plus the turn in progress.
public struct PlayerGame: Codable, Equatable, Sendable {
    public private(set) var sheet = Sheet()
    public private(set) var turn = Turn()

    public init() {}

    public var isFinished: Bool { sheet.isComplete }

    /// What writing in a cell would give right now.
    public struct Option: Equatable, Sendable {
        public let cell: Cell
        /// nil = the dice don't qualify, the cell can only be crossed out.
        public let score: Int?
    }

    /// Every cell the player may write in now, with its preview score.
    public var options: [Option] {
        guard turn.hasRolled else { return [] }
        return sheet.allowedCells(announced: turn.announced).map { cell in
            Option(cell: cell, score: Scoring.bestScore(cell.row, dice: turn.dice, rollNumber: turn.rollCount))
        }
    }

    public mutating func roll(all: Bool) throws { try turn.roll(all: all) }

    public mutating func roll<R: RandomNumberGenerator>(all: Bool, using rng: inout R) throws {
        try turn.roll(all: all, using: &rng)
    }

    public mutating func toggleHold(_ index: Int) { turn.toggleHold(index) }

    public mutating func announce(_ row: Row) throws { try turn.announce(row, on: sheet) }

    /// Ends the turn by writing in a cell.
    /// - Parameter crossOut: write X even if the dice would score (not allowed for Max/Min).
    /// Writes the best score from the dice, or X when they don't qualify. Starts a new turn.
    @discardableResult
    public mutating func write(_ cell: Cell, crossOut: Bool = false) throws -> Entry {
        guard turn.hasRolled else { throw Turn.TurnError.notRolledYet }
        let score = Scoring.bestScore(cell.row, dice: turn.dice, rollNumber: turn.rollCount)
        let entry: Entry = (crossOut ? nil : score).map(Entry.score) ?? .crossed
        try sheet.write(entry, at: cell, announced: turn.announced)
        turn = Turn()
        return entry
    }

    /// Restores a game (saved games, a remote player's game, tests).
    public init(sheet: Sheet, turn: Turn = Turn()) {
        self.sheet = sheet
        self.turn = turn
    }
}
