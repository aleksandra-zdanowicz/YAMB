import SwiftUI
import YambCore

/// The scoresheet grid, laid out like the paper sheet.
struct SheetView: View {
    let sheet: Sheet
    /// Cells that may be written now → preview score (nil = only X).
    let options: [Cell: Int?]
    /// Announce cells that can be tapped to announce.
    let announceable: Set<Cell>
    let announced: Row?
    /// Show what each allowed cell would score. When off, allowed cells are only highlighted.
    var showPreviews = true
    /// Sheet-only mode: filled cells can be tapped to change or clear them.
    var filledCellsEditable = false
    var rowHeight: CGFloat = 27
    let onTap: (Cell) -> Void

    private enum Line: Hashable {
        case row(Row), upperSum, middleSum, lowerSum, total
    }

    // Sizes scale with the row height, so the sheet grows on iPad and Mac.
    private var fontSize: CGFloat { max(15, rowHeight * 0.52) }
    private var labelWidth: CGFloat { max(62, rowHeight * 2.0) }
    private var sumWidth: CGFloat { max(58, rowHeight * 1.8) }
    private var labelFont: Font { .system(size: fontSize * 0.95, weight: .semibold) }
    private var headerFont: Font { .system(size: fontSize * 0.8, weight: .bold) }

    private let lines: [Line] =
        Row.upper.map(Line.row) + [.upperSum] +
        Row.middle.map(Line.row) + [.middleSum] +
        Row.lower.map(Line.row) + [.lowerSum, .total]

    var body: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            GridRow {
                Color.clear.frame(width: labelWidth, height: rowHeight)
                ForEach(Column.allCases, id: \.self) { column in
                    header(column)
                }
                Text("Σ").font(headerFont).foregroundStyle(.secondary)
                    .frame(width: sumWidth, height: rowHeight)
            }
            ForEach(lines, id: \.self) { line in
                GridRow { lineCells(line) }
            }
        }
        .font(.system(size: fontSize, weight: .medium, design: .rounded).monospacedDigit())
    }

    @ViewBuilder
    private func header(_ column: Column) -> some View {
        Group {
            switch column {
            case .down: Image(systemName: "arrow.down").font(headerFont)
            case .up: Image(systemName: "arrow.up").font(headerFont)
            case .free: Text("Free").font(headerFont)
            case .announce: Text("Ann").font(headerFont)
            }
        }
        .foregroundStyle(Theme.accent)
        .frame(maxWidth: .infinity, minHeight: rowHeight)
    }

    @ViewBuilder
    private func lineCells(_ line: Line) -> some View {
        switch line {
        case .row(let row):
            label(row.title)
            ForEach(Column.allCases, id: \.self) { column in
                scoreCell(Cell(column, row))
            }
            blank()
        case .upperSum:
            sumCells("Sum", total: sheet.upperTotal) { col in
                Row.upper.contains { sheet[col, $0] != nil } ? sheet.upperSum(col) : nil
            }
        case .middleSum:
            sumCells("Sum", total: sheet.middleTotal) { sheet.middleSum($0) }
        case .lowerSum:
            sumCells("Sum", total: sheet.lowerTotal) { col in
                Row.lower.contains { sheet[col, $0] != nil } ? sheet.lowerSum(col) : nil
            }
        case .total:
            Text("Total").font(labelFont)
                .frame(width: labelWidth, height: rowHeight + 8, alignment: .leading)
                .padding(.leading, 6)
            Color.clear.frame(height: rowHeight + 8).gridCellColumns(4)
            Text("\(sheet.total)")
                .font(.system(size: fontSize * 1.15, weight: .bold, design: .rounded).monospacedDigit())
                .frame(width: sumWidth, height: rowHeight + 8)
                .background(Theme.accent.opacity(0.18), in: RoundedRectangle(cornerRadius: 6))
        }
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(labelFont)
            .frame(width: labelWidth, height: rowHeight, alignment: .leading)
            .padding(.leading, 6)
    }

    private func blank() -> some View {
        // The Σ column only has cells on the sum rows and the total.
        Color.clear.frame(width: sumWidth, height: rowHeight)
    }

    private func sumCells(_ title: String, total: Int, value: (Column) -> Int?) -> some View {
        let values = Column.allCases.map(value)
        return Group {
            Text(title).font(labelFont)
                .frame(width: labelWidth, height: rowHeight, alignment: .leading)
                .padding(.leading, 6)
            ForEach(Column.allCases, id: \.self) { column in
                Text(values[column.rawValue].map(String.init) ?? "")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, minHeight: rowHeight)
                    .overlay(Rectangle().strokeBorder(Theme.grid, lineWidth: 0.5))
            }
            Text("\(total)").fontWeight(.bold)
                .frame(width: sumWidth, height: rowHeight)
                .overlay(Rectangle().strokeBorder(Theme.grid, lineWidth: 0.5))
        }
        .background(Theme.sumRow)
    }

    @ViewBuilder
    private func scoreCell(_ cell: Cell) -> some View {
        let entry = sheet[cell.column, cell.row]
        let option = options[cell]
        let canAnnounce = announceable.contains(cell)
        let isAnnounced = cell.column == .announce && cell.row == announced

        // Not `.disabled`: that would grey out written scores. Taps on other cells are ignored instead.
        Button {
            if option != nil || canAnnounce || (filledCellsEditable && entry != nil) { onTap(cell) }
        } label: {
            ZStack {
                if let entry {
                    switch entry {
                    case .score(let v): Text("\(v)")
                    case .crossed: Text("X").foregroundStyle(.secondary)
                    }
                } else if showPreviews, let option {
                    Text(option.map(String.init) ?? "X")
                        .foregroundStyle(Theme.accent.opacity(option == nil ? 0.5 : 0.85))
                } else if canAnnounce {
                    Image(systemName: "megaphone").font(.caption2).foregroundStyle(.orange.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity, minHeight: rowHeight)
            .background(background(isOption: option != nil, canAnnounce: canAnnounce, isAnnounced: isAnnounced))
            .overlay(Rectangle().strokeBorder(Theme.grid, lineWidth: 0.5))
            .overlay(isAnnounced ? Rectangle().strokeBorder(.orange, lineWidth: 2) : nil)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func background(isOption: Bool, canAnnounce: Bool, isAnnounced: Bool) -> Color {
        if isAnnounced { return Theme.announceHint }
        if isOption { return Theme.available }
        if canAnnounce { return Theme.announceHint }
        return .clear
    }
}
