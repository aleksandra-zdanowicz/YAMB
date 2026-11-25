import SwiftUI
import YambCore

/// The main game screen: dice on top, roll buttons, the sheet, and a turn bar at the bottom.
struct GameView: View {
    let model: GameModel

    @State private var pendingCell: Cell?
    @State private var confirmNewGame = false
    @State private var pickingCell: Cell?
    @State private var showSettings = false
    private var settings: AppSettings { AppSettings.shared }

    private var sheetOnly: Bool { model.mode == .sheetOnly }

    var body: some View {
        GeometryReader { geo in
            // Side by side only when there's room for both (landscape iPad, Mac window).
            let wide = geo.size.width > 900 && geo.size.width > geo.size.height
            // Stacked layout: centred, at most 700 wide; rows fill the height left over.
            let stackWidth = min(geo.size.width - 24, 700)
            let stackRow = (geo.size.height - stackWidth / 6 - 260) / 17.5
            VStack(spacing: 0) {
                topBar
                if sheetOnly {
                    // Real dice: just the sheet, as big as fits.
                    ScrollView {
                        sheet(rowHeight: max(26, min(48, (geo.size.height - 150) / 17.5)))
                            .frame(maxWidth: 760)
                            .frame(maxWidth: .infinity)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                } else if wide {
                    // iPad / Mac: dice and buttons on the left, the sheet on the right.
                    HStack(alignment: .top, spacing: 40) {
                        VStack(spacing: 24) {
                            dice
                            buttons
                            Spacer()
                        }
                        .frame(maxWidth: 460)
                        sheet(rowHeight: max(27, min(46, (geo.size.height - 150) / 17.5)))
                            .frame(minWidth: 480, maxWidth: 680)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                } else {
                    VStack(spacing: 12) {
                        dice
                        buttons
                        ScrollView { sheet(rowHeight: max(24, min(46, stackRow))) }
                            .scrollBounceBehavior(.basedOnSize)
                    }
                    .frame(maxWidth: stackWidth)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity)
                }
                turnBar
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .confirmationDialog(dialogTitle, isPresented: dialogBinding, titleVisibility: .visible, presenting: pendingCell) { cell in
            dialogButtons(cell)
        }
        .confirmationDialog("New game", isPresented: $confirmNewGame, titleVisibility: .visible) {
            Button("Play with app dice") { model.newGame(.appDice) }
            Button("Sheet only (real dice)") { model.newGame(.sheetOnly) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(model.game.isFinished || model.sheet.entries.isEmpty
                 ? "How do you want to play?"
                 : "How do you want to play? The current game will be lost.")
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .preferredColorScheme(settings.appearance.colorScheme)
        .sheet(item: $pickingCell) { cell in
            ScorePickerView(cell: cell, current: model.sheet[cell.column, cell.row]) { entry in
                model.setEntry(entry, at: cell)
            }
        }
    }

    // MARK: - Pieces

    private var topBar: some View {
        HStack {
            Menu {
                Button("New game", systemImage: "arrow.counterclockwise") { confirmNewGame = true }
                Button("Settings", systemImage: "gearshape") { showSettings = true }
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
                  showPreviews: settings.showPreviews && !sheetOnly,
                  filledCellsEditable: sheetOnly,
                  rowHeight: rowHeight) { cell in
            if sheetOnly { pickingCell = cell } else { pendingCell = cell }
        }
    }

    private var turnBar: some View {
        HStack {
            if model.game.isFinished {
                Text("Game over · \(model.sheet.total) points").font(.headline)
                Spacer()
                Button("New game") { confirmNewGame = true }.buttonStyle(.borderedProminent).tint(Theme.accent)
            } else if sheetOnly {
                Label("Sheet only · real dice", systemImage: "list.bullet.rectangle")
                    .font(.headline)
                Spacer()
                Text("Tap a cell to write").font(.subheadline).foregroundStyle(.secondary)
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
