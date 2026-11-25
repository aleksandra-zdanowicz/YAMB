// Rule checks for YambCore. Run with ./run-checks.sh
// (A plain executable instead of XCTest, so it runs without Xcode installed.)
import Foundation
import YambCore

var failures = 0
var passed = 0
var currentGroup = ""

func group(_ name: String, _ body: () throws -> Void) {
    currentGroup = name
    do { try body() } catch {
        failures += 1
        print("✗ [\(name)] threw \(error)")
    }
}

func check<T: Equatable>(_ actual: T, _ expected: T, _ label: String, line: Int = #line) {
    if actual == expected {
        passed += 1
    } else {
        failures += 1
        print("✗ [\(currentGroup)] \(label): got \(actual), expected \(expected)  (line \(line))")
    }
}

func checkThrows(_ label: String, line: Int = #line, _ body: () throws -> Void) {
    do {
        try body()
        failures += 1
        print("✗ [\(currentGroup)] \(label): expected an error  (line \(line))")
    } catch { passed += 1 }
}

func s(_ row: Row, _ dice: [Int], roll: Int = 1) -> Int? {
    Scoring.bestScore(row, dice: dice, rollNumber: roll)
}

// MARK: - Scoring

group("Numbers 1–6") {
    check(s(.fours, [4, 4, 4, 1, 2]), 12, "three 4s")
    check(s(.fours, [1, 2, 3, 5, 6]), 0, "no 4s scores 0, not X")
    check(s(.fours, [4, 4, 4, 4, 4, 4]), 20, "six 4s: only 5 dice count")
    check(s(.ones, [1, 1, 1, 1, 1, 6]), 5, "five 1s")
    check(s(.sixes, [6, 6, 1, 6, 2, 3]), 18, "picks the best 5 of 6")
}

group("Max / Min") {
    check(s(.max, [6, 6, 6, 5, 1, 5]), 28, "max drops the lowest die")
    check(s(.min, [1, 1, 2, 1, 1, 6]), 6, "min drops the highest die")
    check(s(.max, [6, 6, 6, 6, 6, 6]), 30, "max of all sixes")
}

group("Quint") {
    check(s(.quint, [1, 2, 3, 4, 5], roll: 1), 66, "1–5 on roll 1")
    check(s(.quint, [2, 3, 4, 5, 6], roll: 2), 56, "2–6 on roll 2")
    check(s(.quint, [6, 5, 4, 3, 2, 1], roll: 3), 46, "out of order, 6 dice, roll 3")
    check(s(.quint, [1, 2, 3, 4, 6, 6]), nil, "1-2-3-4-6 is not a quint")
    check(s(.quint, [3, 4, 5, 6, 3, 1]), nil, "no 5 in a row")
}

group("Full") {
    check(s(.full, [6, 6, 6, 5, 5]), 58, "6-6-6-5-5 = 28 + 30")
    check(s(.full, [2, 2, 2, 3, 3, 1]), 42, "2-2-2-3-3 = 12 + 30, extra die dropped")
    check(s(.full, [5, 5, 5, 5, 5]), nil, "yamb is NOT a full")
    check(s(.full, [5, 5, 5, 5, 5, 5]), nil, "six of a kind is NOT a full")
    check(s(.full, [4, 4, 4, 4, 1]), nil, "poker is not a full")
    check(s(.full, [6, 6, 6, 6, 5, 5]), 58, "4+2: picks 6-6-6-5-5")
}

group("Poker") {
    check(s(.poker, [4, 4, 4, 4, 2]), 56, "four 4s: 16 + 40, odd die ignored")
    check(s(.poker, [6, 6, 6, 6, 6]), 64, "yamb counts as poker: 24 + 40")
    check(s(.poker, [3, 3, 3, 2, 2, 1]), nil, "three of a kind is not poker")
}

group("Yamb") {
    check(s(.yamb, [5, 5, 5, 5, 5]), 75, "five 5s: 25 + 50")
    check(s(.yamb, [6, 6, 6, 6, 6, 1]), 80, "five 6s out of 6 dice")
    check(s(.yamb, [6, 6, 6, 6, 1, 1]), nil, "four of a kind is not yamb")
}

group("Possible scores (sheet-only picker)") {
    check(Scoring.possibleScores(.fours), [0, 4, 8, 12, 16, 20], "4s")
    check(Scoring.possibleScores(.max), Array(5...30), "max")
    check(Scoring.possibleScores(.quint), [46, 56, 66], "quint")
    check(Scoring.possibleScores(.poker), [44, 48, 52, 56, 60, 64], "poker")
    check(Scoring.possibleScores(.yamb), [55, 60, 65, 70, 75, 80], "yamb")
    let full = Scoring.possibleScores(.full)
    check(full.first, 37, "lowest full: 1-1-1-2-2")
    check(full.last, 58, "highest full: 6-6-6-5-5")
    check(full.contains(35), false, "five 1s is not a full")
}

group("Sheet-only allowed cells") {
    var sheet = Sheet()
    check(sheet.sheetOnlyAllowedCells.count, 1 + 12 + 1 + 12, "down + free + up + all announce")
    sheet.set(.score(75), at: Cell(.announce, .yamb))
    check(sheet.sheetOnlyAllowedCells.contains(Cell(.announce, .yamb)), false, "filled announce cell closed")
}

// MARK: - Sheet & totals

/// Basha's real sheet. X = crossed out.
func bashaSheet() -> Sheet {
    let X: Int? = nil
    let columns: [(Column, [Int?])] = [
        (.down, [5, 8, 3, 16, 15, 18, 27, 9, 66, 58, 56, X]),
        (.free, [3, 4, 9, 12, 15, 18, 27, 9, 56, 56, 52, 75]),
        (.up, [3, 0, 9, 12, 0, 12, 30, 10, 66, 45, 64, 75]),
        (.announce, [5, 8, 9, 16, 25, 24, 26, 6, 56, 46, 52, 75]),
    ]
    var sheet = Sheet()
    for (column, values) in columns {
        for (row, value) in zip(Row.allCases, values) {
            sheet.set(value.map(Entry.score) ?? .crossed, at: Cell(column, row))
        }
    }
    return sheet
}

group("Basha's sheet = 1541") {
    let sheet = bashaSheet()
    check(Column.allCases.map { sheet.upperSum($0) }, [95, 91, 36, 117], "1–6 sums with bonus")
    check(sheet.upperTotal, 339, "top total")
    check(Column.allCases.map { sheet.middleSum($0) }, [90, 54, 60, 100], "(max−min)×1s")
    check(sheet.middleTotal, 304, "middle total")
    check(Column.allCases.map { sheet.lowerSum($0) }, [180, 239, 250, 229], "bottom sums")
    check(sheet.lowerTotal, 898, "bottom total")
    check(sheet.total, 1541, "final score")
    check(sheet.isComplete, true, "sheet is full")
}

group("Totals edge cases") {
    var sheet = Sheet()
    for (row, v) in zip(Row.upper, [3, 6, 9, 12, 15, 14]) { sheet.set(.score(v), at: Cell(.free, row)) }
    check(sheet.upperSum(.free), 59, "59: no bonus")
    sheet.set(.score(15), at: Cell(.free, .sixes))
    check(sheet.upperSum(.free), 60 + 30, "exactly 60: bonus")

    check(sheet.middleSum(.free), nil, "middle not scored until max & min filled")
    sheet.set(.score(10), at: Cell(.free, .max))
    sheet.set(.score(20), at: Cell(.free, .min))
    check(sheet.middleSum(.free), -30, "max < min goes negative")
    check(sheet.middleTotal, -30, "negative section is subtracted from the total")
}

group("Max / Min can't be crossed out") {
    var sheet = Sheet()
    checkThrows("free max: no X") { try sheet.write(.crossed, at: Cell(.free, .max), announced: nil) }
    checkThrows("free min: no X") { try sheet.write(.crossed, at: Cell(.free, .min), announced: nil) }
    try sheet.write(.crossed, at: Cell(.free, .yamb), announced: nil)

    var game = PlayerGame(sheet: Sheet(), turn: Turn(dice: [1, 1, 2, 2, 3, 3], rollCount: 3))
    checkThrows("voluntary X on min refused") { try game.write(Cell(.free, .min), crossOut: true) }
    check(try game.write(Cell(.free, .max)), .score(11), "a bad max still scores")
}

// MARK: - Order rules

group("Down / Up / Free order") {
    var sheet = Sheet()
    check(sheet.nextRow(in: .down), .ones, "down starts at 1")
    check(sheet.nextRow(in: .up), .yamb, "up starts at yamb")
    check(sheet.allowedCells(announced: nil).count, 1 + 12 + 1, "down + all free + up")
    check(sheet.allowedCells(announced: nil).contains { $0.column == .announce }, false, "announce needs announcing")

    try sheet.write(.score(3), at: Cell(.down, .ones), announced: nil)
    check(sheet.nextRow(in: .down), .twos, "down moves on")
    checkThrows("can't skip in down") { try sheet.write(.score(9), at: Cell(.down, .threes), announced: nil) }
    checkThrows("can't skip in up") { try sheet.write(.score(18), at: Cell(.up, .sixes), announced: nil) }
    try sheet.write(.crossed, at: Cell(.up, .yamb), announced: nil)
    check(sheet.nextRow(in: .up), .poker, "crossing out also moves on")
    try sheet.write(.score(46), at: Cell(.free, .quint), announced: nil)
    checkThrows("free cell can't be used twice") { try sheet.write(.score(1), at: Cell(.free, .quint), announced: nil) }
}

// MARK: - Turns

group("Rolling and holding") {
    var rng = SystemRandomNumberGenerator()
    var turn = Turn()
    try turn.roll(all: false, using: &rng)
    check(turn.rollCount, 1, "first roll")
    turn.toggleHold(0)
    turn.toggleHold(3)
    let kept = [turn.dice[0], turn.dice[3]]
    try turn.roll(all: false, using: &rng)
    check([turn.dice[0], turn.dice[3]], kept, "held dice stay")
    check(turn.held, [0, 3], "holds persist")
    turn.toggleHold(0)
    check(turn.held, [3], "a held die can be released for roll 3")
    try turn.roll(all: true, using: &rng)
    check(turn.held, [], "roll all clears holds")
    check(turn.rollCount, 3, "three rolls")
    checkThrows("no 4th roll") { try turn.roll(all: false, using: &rng) }
}

group("Announce") {
    var game = PlayerGame()
    checkThrows("can't announce before rolling") { try game.announce(.yamb) }

    // Announced 4s, missed: partial score goes in.
    game = PlayerGame(sheet: Sheet(), turn: Turn(dice: [4, 1, 2, 3, 5, 6], rollCount: 1))
    try game.announce(.fours)
    check(game.options.map(\.cell), [Cell(.announce, .fours)], "announced: only that cell")
    check(game.options.first?.score, 4, "missed 4s still scores 4")
    checkThrows("can't write elsewhere") { try game.write(Cell(.free, .fours)) }
    check(try game.write(Cell(.announce, .fours)), .score(4), "written")

    // Announced full, missed: X.
    game = PlayerGame(sheet: game.sheet, turn: Turn(dice: [1, 2, 3, 4, 6, 6], rollCount: 3, announced: .full))
    check(try game.write(Cell(.announce, .full)), .crossed, "missed full = X")

    // Yamb on roll 1: announce and write straight away.
    game = PlayerGame(sheet: game.sheet, turn: Turn(dice: [6, 6, 6, 6, 6, 2], rollCount: 1))
    try game.announce(.yamb)
    check(try game.write(Cell(.announce, .yamb)), .score(80), "yamb announced on roll 1")

    // Too late to announce after roll 2.
    game = PlayerGame(sheet: game.sheet, turn: Turn(dice: [1, 2, 3, 4, 5, 6], rollCount: 2))
    checkThrows("announce only after roll 1") { try game.announce(.quint) }
    checkThrows("can't announce a filled cell") {
        var g = PlayerGame(sheet: game.sheet, turn: Turn(dice: [1, 1, 1, 1, 1, 1], rollCount: 1))
        try g.announce(.yamb)
    }
}

group("Writing ends the turn") {
    var game = PlayerGame(sheet: Sheet(), turn: Turn(dice: [1, 1, 1, 2, 3, 4], rollCount: 2))
    check(try game.write(Cell(.down, .ones)), .score(3), "three 1s")
    check(game.turn.rollCount, 0, "new turn starts")
    checkThrows("must roll before writing") { try game.write(Cell(.down, .twos)) }

    game = PlayerGame(sheet: game.sheet, turn: Turn(dice: [2, 2, 5, 5, 5, 5], rollCount: 3))
    check(try game.write(Cell(.free, .twos), crossOut: true), .crossed, "voluntary cross-out")
    game = PlayerGame(sheet: game.sheet, turn: Turn(dice: [1, 3, 3, 4, 6, 6], rollCount: 3))
    check(try game.write(Cell(.up, .yamb)), .crossed, "no yamb in up column = X")
}

group("Full game with random dice") {
    // Plays 200 games making random legal moves; every game must end with a full sheet after 48 turns.
    var rng = SystemRandomNumberGenerator()
    var allFinished = true
    for _ in 0..<200 {
        var game = PlayerGame()
        var turns = 0
        while !game.isFinished && turns < 100 {
            try game.roll(all: true, using: &rng)
            if Bool.random(using: &rng), let row = game.sheet.announceableRows.randomElement(using: &rng) {
                try game.announce(row)
            }
            if Bool.random(using: &rng) { try game.roll(all: false, using: &rng) }
            let option = game.options.randomElement(using: &rng)!
            try game.write(option.cell)
            turns += 1
        }
        if !game.isFinished || turns != 48 { allFinished = false }
    }
    check(allFinished, true, "200 random games each finish in exactly 48 turns")
}

group("Fair dice") {
    var rng = SystemRandomNumberGenerator()
    let n = 600_000
    var counts = Array(repeating: 0, count: 7)
    for _ in 0..<n { counts[Dice.roll(using: &rng)] += 1 }
    // Chi-square with 5 degrees of freedom; 20.5 ≈ p = 0.001.
    let expected = Double(n) / 6
    let chi2 = (1...6).reduce(0.0) { $0 + pow2(Double(counts[$1]) - expected) / expected }
    check(chi2 < 20.5, true, "uniform distribution (χ² = \(Int(chi2)))")
    check(counts[0], 0, "never rolls 0")
}

func pow2(_ x: Double) -> Double { x * x }

print(failures == 0 ? "✓ All \(passed) checks passed" : "\n\(failures) failed, \(passed) passed")
exit(failures == 0 ? 0 : 1)
