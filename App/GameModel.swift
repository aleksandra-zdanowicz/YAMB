import Foundation
import Observation
import YambCore

/// How the current game is played.
enum GameMode: String, Codable {
    /// The app rolls the dice.
    case appDice
    /// Real dice on the table; the app is only the scoresheet.
    case sheetOnly
}

/// The solo game the screen shows. Saves itself after every change, so a game survives closing the app.
@Observable
final class GameModel {
    private(set) var game: PlayerGame {
        didSet { save() }
    }
    private(set) var mode: GameMode {
        didSet { save() }
    }

    /// How many times each die has been rolled (drives the spin animation).
    private(set) var spins = Array(repeating: 0, count: Turn.diceCount)

    private struct Saved: Codable {
        var mode: GameMode
        var game: PlayerGame
    }

    private static let saveKey = "currentSoloGame"

    init() {
        let data = UserDefaults.standard.data(forKey: Self.saveKey)
        if let data, let saved = try? JSONDecoder().decode(Saved.self, from: data) {
            game = saved.game
            mode = saved.mode
        } else if let data, let oldFormat = try? JSONDecoder().decode(PlayerGame.self, from: data) {
            game = oldFormat
            mode = .appDice
        } else {
            game = PlayerGame()
            mode = .appDice
        }
        // Testing hook: launching with `-YambStartMode sheetOnly` (or appDice) starts a fresh game in that mode.
        if let raw = UserDefaults.standard.string(forKey: "YambStartMode"), let start = GameMode(rawValue: raw) {
            mode = start
            game = PlayerGame()
        }
    }

    var sheet: Sheet { game.sheet }
    var turn: Turn { game.turn }

    /// Allowed cells this turn → preview score (nil = only X possible).
    /// In sheet-only mode: every cell that may be filled, without a preview.
    var options: [Cell: Int?] {
        switch mode {
        case .appDice:
            return Dictionary(uniqueKeysWithValues: game.options.map { ($0.cell, $0.score) })
        case .sheetOnly:
            return Dictionary(uniqueKeysWithValues: sheet.sheetOnlyAllowedCells.map { ($0, nil) })
        }
    }

    /// Announce cells that can be tapped to announce right now.
    var announceable: Set<Cell> {
        guard mode == .appDice, turn.rollCount == 1, turn.announced == nil else { return [] }
        return Set(sheet.announceableRows.map { Cell(.announce, $0) })
    }

    // MARK: App dice

    func roll(all: Bool) {
        let rolling = turn.dice.indices.filter { all || turn.rollCount == 0 || !turn.held.contains($0) }
        guard (try? game.roll(all: all)) != nil else { return }
        for i in rolling { spins[i] += 1 }
    }

    func toggleHold(_ index: Int) { game.toggleHold(index) }

    func announce(_ row: Row) { try? game.announce(row) }

    func write(_ cell: Cell, crossOut: Bool) { _ = try? game.write(cell, crossOut: crossOut) }

    // MARK: Sheet only

    /// Writes, changes or clears (nil) a cell directly. Used in sheet-only mode, where scores come from real dice.
    func setEntry(_ entry: Entry?, at cell: Cell) {
        var sheet = game.sheet
        sheet.set(entry, at: cell)
        game = PlayerGame(sheet: sheet)
    }

    // MARK: -

    func newGame(_ mode: GameMode) {
        self.mode = mode
        game = PlayerGame()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(Saved(mode: mode, game: game)) {
            UserDefaults.standard.set(data, forKey: Self.saveKey)
        }
    }
}
