# YAMB app – Plan

One SwiftUI app for iPhone, iPad and Mac. The rules are in [RULES.md](RULES.md).

## Game screen (from the sketch)

From top to bottom:

1. **Top bar:** menu button (☰) on the left.
2. **Dice:** 6 big dice in one row. Tap a die to keep it (it gets highlighted). Kept dice can be tapped again to release them.
3. **Buttons:**
   - **Roll unselected dice** (on top, the main button)
   - **Roll all dice** (underneath)
   - A roll counter (1/3, 2/3, 3/3)
4. **Scoresheet, always visible:** columns ↓ / Free / ↑ / ANN plus a totals column. Rows 1–6, SUM, Max, Min, SUM, Quint, Full, Poker, Yamb, SUM, then the final Total.
   - Cells you're allowed to fill are highlighted and show a preview of what they'd score.
   - Tap a cell to write the score. If the dice don't qualify, you're offered X.
   - **Announce:** after roll 1, tap an ANN cell to announce it. It stays locked until the end of the turn.
5. **Bottom bar:** "Your turn" or "Basha's turn".

On iPad and Mac there's more room, so the dice and the sheet sit side by side.

## Modes

| Mode | What it is |
|---|---|
| **Solo** | Just you, with the app's dice. |
| **Online** | Each player on their own device. When it's someone else's turn, you watch their sheet and dice live. |
| **Sheet only** | Real dice on the table, the app is just the scoresheet. You enter your dice (or the score) and the app checks it and adds everything up. Works solo or for each player on their own device. |

## Features

- **Fair dice:** every roll uses the system's cryptographically secure random generator, so each face has exactly a 1/6 chance and the results can't be predicted.
- **Stats:** games played, average score, best score, Yambs rolled, and so on.
- **High scores:** your personal best scores.
- **Head-to-head:** your win/loss record against each opponent, e.g. "You vs Basha: 3–1".
- **Themes:** light and dark, plus pastel colour themes (pink, blue, green, purple, …).
- **Sounds and haptics,** each with an on/off switch.
- **Saved games:** you can leave a game and pick it up later.

## Build order

| Phase | What gets built | What you can do at the end |
|---|---|---|
| 1 | Rules engine + automated tests | Prove the scoring matches Basha's sheet (1541) |
| 2 | Solo game with your screen layout | Play a full game in the iPhone Simulator |
| 3 | Sheet-only mode | Score a game played with real dice |
| 4 | Themes, sounds, haptics, iPad/Mac layout | Make it look and feel finished |
| 5 | Stats and high scores (on the device) | See your history |
| 6 | Online play + watching + head-to-head | Play with Basha on two phones |
| 7 | TestFlight / App Store | Install it on friends' phones |

## Open decisions

- ~~Online technology~~ **Decided: Apple Game Center.** All players are on Apple devices. It handles sign-in, invites, turns and live watching, and it needs no server.
- **Sheet-only input:** typing the 5 dice values vs typing the score directly.

## Prerequisites

- **Xcode** from the Mac App Store. It's free but large (about 10+ GB), and it's needed from phase 2 onward.
- An **Apple Developer account** ($99/year), needed only from phase 6–7 (Game Center, TestFlight, App Store).
