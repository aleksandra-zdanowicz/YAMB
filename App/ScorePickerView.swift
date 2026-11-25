import SwiftUI
import YambCore

extension Cell: @retroactive Identifiable {
    public var id: Int { column.rawValue * 100 + row.rawValue }
}

/// Sheet-only mode: pick the score for a cell from the values that are actually possible.
struct ScorePickerView: View {
    let cell: Cell
    let current: Entry?
    let onPick: (Entry?) -> Void

    @Environment(\.dismiss) private var dismiss

    private var scores: [Int] { Scoring.possibleScores(cell.row) }
    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: cell.row == .quint ? 96 : 58), spacing: 10)]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(scores, id: \.self) { score in
                        Button { pick(.score(score)) } label: {
                            VStack(spacing: 2) {
                                Text("\(score)").font(.title3.weight(.semibold).monospacedDigit())
                                if cell.row == .quint {
                                    Text(quintLabel(score)).font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(isCurrent(score) ? Theme.accent.opacity(0.25) : Theme.available,
                                        in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()

                VStack(spacing: 10) {
                    if Sheet.canCrossOut(cell.row) {
                        Button(role: .destructive) { pick(.crossed) } label: {
                            Text("Cross out (X)").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    if current != nil {
                        Button { pick(nil) } label: {
                            Text("Clear cell").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.secondary)
                    }
                }
                .controlSize(.large)
                .padding(.horizontal)
            }
            .navigationTitle("\(cell.column.title) · \(cell.row.title)")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func pick(_ entry: Entry?) {
        onPick(entry)
        dismiss()
    }

    private func isCurrent(_ score: Int) -> Bool { current == .score(score) }

    private func quintLabel(_ score: Int) -> String {
        switch score {
        case 66: return "1st roll"
        case 56: return "2nd roll"
        default: return "3rd roll"
        }
    }
}
