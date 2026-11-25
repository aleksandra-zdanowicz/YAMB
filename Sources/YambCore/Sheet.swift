/// One player's scoresheet: which cells are filled, which may be filled next, and the totals.
public struct Sheet: Codable, Equatable, Sendable {
    public private(set) var entries: [Cell: Entry] = [:]

    public init() {}

    public subscript(_ column: Column, _ row: Row) -> Entry? {
        entries[Cell(column, row)]
    }

    public var isComplete: Bool { entries.count == Column.allCases.count * Row.allCases.count }

    // MARK: - Order rules

    /// The next row that may be filled in an ordered column (↓ or ↑), or nil if the column is full.
    public func nextRow(in column: Column) -> Row? {
        switch column {
        case .down: return Row.allCases.first { self[column, $0] == nil }
        case .up: return Row.allCases.reversed().first { self[column, $0] == nil }
        case .free, .announce: return nil
        }
    }

    /// Cells that may be written this turn.
    /// - Parameter announced: the row announced this turn, if any. Then only that Announce cell is allowed.
    public func allowedCells(announced: Row?) -> [Cell] {
        if let row = announced {
            return self[.announce, row] == nil ? [Cell(.announce, row)] : []
        }
        var cells: [Cell] = []
        if let r = nextRow(in: .down) { cells.append(Cell(.down, r)) }
        cells += Row.allCases.filter { self[.free, $0] == nil }.map { Cell(.free, $0) }
        if let r = nextRow(in: .up) { cells.append(Cell(.up, r)) }
        return cells
    }

    /// Cells that may be filled in sheet-only mode (real dice): the same order rules,
    /// but empty Announce cells are always open, since the players handle announcing at the table.
    public var sheetOnlyAllowedCells: [Cell] {
        allowedCells(announced: nil) + announceableRows.map { Cell(.announce, $0) }
    }

    /// Rows that can still be announced (empty cells in the Announce column).
    public var announceableRows: [Row] {
        Row.allCases.filter { self[.announce, $0] == nil }
    }

    // MARK: - Writing

    public enum WriteError: Error, Equatable {
        case notAllowed(Cell)
        case cannotCrossOut(Row)
    }

    /// Max and Min always score (they're just the dice sum), so they can never be crossed out.
    public static func canCrossOut(_ row: Row) -> Bool { row != .max && row != .min }

    /// Writes an entry, enforcing the order rules.
    public mutating func write(_ entry: Entry, at cell: Cell, announced: Row?) throws {
        guard allowedCells(announced: announced).contains(cell) else { throw WriteError.notAllowed(cell) }
        if entry == .crossed && !Self.canCrossOut(cell.row) { throw WriteError.cannotCrossOut(cell.row) }
        entries[cell] = entry
    }

    /// Writes without checking order — for editing/correcting in sheet-only mode.
    public mutating func set(_ entry: Entry?, at cell: Cell) {
        entries[cell] = entry
    }

    // MARK: - Totals

    /// 1–6 total for a column, plus 30 once it reaches 60.
    public func upperSum(_ column: Column) -> Int {
        let raw = Row.upper.reduce(0) { $0 + (self[column, $1]?.points ?? 0) }
        return raw >= Scoring.upperBonusThreshold ? raw + Scoring.upperBonus : raw
    }

    /// (Max − Min) × the column's "1" value. Can be negative, which lowers the total.
    /// nil until 1, Max and Min are all filled.
    public func middleSum(_ column: Column) -> Int? {
        guard let ones = self[column, .ones], let max = self[column, .max], let min = self[column, .min] else {
            return nil
        }
        return (max.points - min.points) * ones.points
    }

    /// Quint + Full + Poker + Yamb for a column.
    public func lowerSum(_ column: Column) -> Int {
        Row.lower.reduce(0) { $0 + (self[column, $1]?.points ?? 0) }
    }

    public var upperTotal: Int { Column.allCases.reduce(0) { $0 + upperSum($1) } }
    public var middleTotal: Int { Column.allCases.reduce(0) { $0 + (middleSum($1) ?? 0) } }
    public var lowerTotal: Int { Column.allCases.reduce(0) { $0 + lowerSum($1) } }
    public var total: Int { upperTotal + middleTotal + lowerTotal }
}
