import Foundation
import Observation
import YambCore

/// The solo game the screen shows. Saves itself after every change, so a game survives closing the app.
@Observable
final class GameModel {
    private(set) var game: PlayerGame {
        didSet { save() }
    }

    /// How many times each die has been rolled (drives the spin animation).
    private(set) var spins = Array(repeating: 0, count: Turn.diceCount)

    private static let saveKey = "currentSoloGame"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.saveKey),
           let saved = try? JSONDecoder().decode(PlayerGame.self, from: data) {
            game = saved
        } else {
            game = PlayerGame()
        }
    }

    var sheet: Sheet { game.sheet }
    var turn: Turn { game.turn }

    /// Allowed cells this turn → preview score (nil = only X possible).
    var options: [Cell: Int?] {
        Dictionary(uniqueKeysWithValues: game.options.map { ($0.cell, $0.score) })
    }

    /// Announce cells that can be tapped to announce right now.
    var announceable: Set<Cell> {
        guard turn.rollCount == 1, turn.announced == nil else { return [] }
        return Set(sheet.announceableRows.map { Cell(.announce, $0) })
    }

    func roll(all: Bool) {
        let rolling = turn.dice.indices.filter { all || turn.rollCount == 0 || !turn.held.contains($0) }
        guard (try? game.roll(all: all)) != nil else { return }
        for i in rolling { spins[i] += 1 }
    }

    func toggleHold(_ index: Int) { game.toggleHold(index) }

    func announce(_ row: Row) { try? game.announce(row) }

    func write(_ cell: Cell, crossOut: Bool) { _ = try? game.write(cell, crossOut: crossOut) }

    func newGame() { game = PlayerGame() }

    private func save() {
        if let data = try? JSONEncoder().encode(game) {
            UserDefaults.standard.set(data, forKey: Self.saveKey)
        }
    }
}
