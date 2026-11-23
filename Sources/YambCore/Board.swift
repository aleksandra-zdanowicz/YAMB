/// The four columns of the scoresheet.
public enum Column: Int, CaseIterable, Codable, Hashable, Sendable {
    case down, free, up, announce

    public var title: String {
        switch self {
        case .down: return "↓"
        case .free: return "Free"
        case .up: return "↑"
        case .announce: return "Ann"
        }
    }
}

/// The twelve scoring rows, in sheet order (top to bottom).
public enum Row: Int, CaseIterable, Codable, Hashable, Sendable {
    case ones = 1, twos, threes, fours, fives, sixes
    case max, min
    case quint, full, poker, yamb

    /// For rows 1–6: the die face they count. Otherwise nil.
    public var face: Int? { rawValue <= 6 ? rawValue : nil }

    public var title: String {
        switch self {
        case .ones, .twos, .threes, .fours, .fives, .sixes: return "\(rawValue)"
        case .max: return "Max"
        case .min: return "Min"
        case .quint: return "Quint"
        case .full: return "Full"
        case .poker: return "Poker"
        case .yamb: return "Yamb"
        }
    }

    public static let upper: [Row] = [.ones, .twos, .threes, .fours, .fives, .sixes]
    public static let middle: [Row] = [.max, .min]
    public static let lower: [Row] = [.quint, .full, .poker, .yamb]
}

/// A position on the sheet.
public struct Cell: Hashable, Codable, Sendable {
    public let column: Column
    public let row: Row
    public init(_ column: Column, _ row: Row) {
        self.column = column
        self.row = row
    }
}

/// What has been written in a cell.
public enum Entry: Hashable, Codable, Sendable {
    case score(Int)
    case crossed // "X" — counts as 0

    public var points: Int {
        if case .score(let v) = self { return v }
        return 0
    }
}
