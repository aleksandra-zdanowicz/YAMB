import SwiftUI
import YambCore

/// The main game screen: dice on top, roll buttons, the sheet, and a turn bar at the bottom.
struct GameView: View {
    let model: GameModel

    @State private var pendingCell: Cell?
    @State private var confirmNewGame = false

    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > 760
            VStack(spacing: 0) {
                topBar
                if wide {
                    HStack(alignment: .top, spacing: 32) {
                        VStack(spacing: 20) {
                            dice
                            buttons
                            Spacer()
                        }
                        .frame(maxWidth: 420)
                        sheet(rowHeight: max(27, min(40, (geo.size.height - 160) / 17)))
                            .frame(maxWidth: 560)
                    }
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                } else {
                    VStack(spacing: 12) {
                        dice
                        buttons
                        ScrollView { sheet(rowHeight: max(24, min(34, (geo.size.height - 300) / 17.5))) }
                            .scrollBounceBehavior(.basedOnSize)
                    }
                    .padding(.horizontal, 12)
                }
                turnBar
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .confirmationDialog(dialogTitle, isPresented: dialogBinding, titleVisibility: .visible, presenting: pendingCell) { cell in
            dialogButtons(cell)
        }
        .alert("Start a new game?", isPresented: $confirmNewGame) {
            Button("New game", role: .destructive) { model.newGame() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The current game will be lost.")
        }
    }

    // MARK: - Pieces

    private var topBar: some View {
        HStack {
            Menu {
                Button("New game", systemImage: "arrow.counterclockwise") { confirmNewGame = true }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.title3.weight(.semibold))
                    .frame(width: 40, height: 40)
                    .foregroundStyle(Theme.accent)
            }
            .menuIndicator(.hidden)
            .fixedSize()
            Spacer()
            Text("YAMB").font(.headline.weight(.heavy)).foregroundStyle(Theme.accent)
            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 12)
    }

    private var dice: some View {
        HStack(spacing: 8) {
            ForEach(0..<Turn.diceCount, id: \.self) { i in
                DieView(value: model.turn.dice[i],
                        held: model.turn.held.contains(i),
                        active: model.turn.hasRolled,
                        spins: model.spins[i])
                    .onTapGesture { model.toggleHold(i) }
            }
        }
        .padding(.top, 8)
    }

    private var buttons: some View {
        VStack(spacing: 8) {
            if let row = model.turn.announced, let option = model.options[Cell(.announce, row)] {
                // Announced: make "stop and write" the obvious action, rolls become secondary.
                Button { model.write(Cell(.announce, row), crossOut: false) } label: {
                    Label("Write \(option.map(String.init) ?? "X") in Ann · \(row.title)", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

                HStack(spacing: 8) {
                    Button { model.roll(all: false) } label: {
                        Text("Roll unselected").frame(maxWidth: .infinity)
                    }
                    .disabled(!model.turn.canRoll || model.turn.held.count == Turn.diceCount)
                    Button { model.roll(all: true) } label: {
                        Text("Roll all").frame(maxWidth: .infinity)
                    }
                    .disabled(!model.turn.canRoll)
                }
                .buttonStyle(.bordered)
            } else if model.turn.hasRolled {
                Button { model.roll(all: false) } label: {
                    Label("Roll unselected dice", systemImage: "dice").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!model.turn.canRoll || model.turn.held.count == Turn.diceCount)

                Button { model.roll(all: true) } label: {
                    Text("Roll all dice").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!model.turn.canRoll)
            } else {
                Button { model.roll(all: true) } label: {
                    Label("Roll dice", systemImage: "dice").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.game.isFinished)
            }
        }
        .controlSize(.large)
        .tint(Theme.accent)
    }

    private func sheet(rowHeight: CGFloat) -> some View {
        SheetView(sheet: model.sheet,
                  options: model.options,
                  announceable: model.announceable,
                  announced: model.turn.announced,
                  rowHeight: rowHeight) { cell in
            pendingCell = cell
        }
    }

    private var turnBar: some View {
        HStack {
            if model.game.isFinished {
                Text("Game over · \(model.sheet.total) points").font(.headline)
                Spacer()
                Button("New game") { model.newGame() }.buttonStyle(.borderedProminent).tint(Theme.accent)
            } else {
                Text("Your turn").font(.headline)
                Spacer()
                if let row = model.turn.announced {
                    Label("Announced \(row.title)", systemImage: "megaphone.fill")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(.orange)
                } else if model.turn.hasRolled {
                    Text("Roll \(model.turn.rollCount) of \(Turn.maxRolls)")
                        .font(.subheadline).foregroundStyle(.secondary)
                } else {
                    Text("Roll to start").font(.subheadline).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 52)
        .background(.bar)
    }

    // MARK: - Write / announce dialog

    private var dialogBinding: Binding<Bool> {
        Binding(get: { pendingCell != nil }, set: { if !$0 { pendingCell = nil } })
    }

    private var dialogTitle: String {
        guard let cell = pendingCell else { return "" }
        if model.announceable.contains(cell) { return "Announce \(cell.row.title)?" }
        return "\(cell.column.title) · \(cell.row.title)"
    }

    @ViewBuilder
    private func dialogButtons(_ cell: Cell) -> some View {
        if model.announceable.contains(cell) {
            Button("Announce \(cell.row.title)") { model.announce(cell.row) }
        } else if let option = model.options[cell] {
            if let score = option {
                Button("Write \(score)") { model.write(cell, crossOut: false) }
            }
            if Sheet.canCrossOut(cell.row) {
                Button("Cross out (X)", role: .destructive) { model.write(cell, crossOut: true) }
            }
        }
        Button("Cancel", role: .cancel) {}
    }
}
