# YAMB – Rules

This is the reference the app is built against. If the app ever disagrees with this file, one of them is wrong.

## Equipment and players

- **6 dice.** Only **5** of them count for any score: the player chooses which 5 (the app can pick the best 5 automatically).
- **1 or more players.** Each player has their own scoresheet, and players take turns.
- **Who starts:** each player rolls 1 die and the highest number goes first. On a tie, those players roll again. Play then continues in seating/turn order.

## A turn

1. **Roll 1:** roll all 6 dice.
2. **Roll 2 (optional):** keep any dice you like and re-roll the rest. You can also re-roll all of them.
3. **Roll 3 (optional):** dice kept after roll 2 can be re-rolled now too. You choose freely again what to keep and what to roll.
4. **Write:** at the end of the turn you must **fill in or cross out (X = 0) exactly one cell**.

You can stop rolling early and write your score after roll 1 or 2.

## The scoresheet

There are 4 columns and 12 scoring rows (1–6, Max, Min, Quint, Full, Poker, Yamb), so **48 turns per player**. The game ends when every cell is filled.

### Columns

| Column | Rule |
|---|---|
| **↓ Down** | Fill strictly top to bottom: 1, 2, 3, 4, 5, 6, Max, Min, Quint, Full, Poker, Yamb. No skipping. |
| **Free** | Fill in any order. |
| **↑ Up** | Fill strictly bottom to top: Yamb, Poker, Full, Quint, Min, Max, 6 … 1. No skipping. |
| **ANN Announce** | See "Announcing" below. |

**Crossing out:** if your dice don't fit, you may write X (0) in any cell you're currently allowed to fill. In Down/Up that means only the next cell in order. Max and Min can't be crossed out.

### Announcing

- You may only announce **right after roll 1**. You name one free cell in the Announce column (e.g. "announce 4s").
- Once you've announced, you can't change it. This turn **must** be written into that cell.
- You can stop rolling once you have it. For example, if roll 1 is already a Yamb, announce Yamb and write it straight away.
- If you miss, you still write whatever score the dice give for that row. For number rows that means a partial score (announced 4s with only one 4 = 4). For a row where your dice don't qualify (Quint, Full, Poker, Yamb), you write X = 0.
- You can't fill an Announce cell without having announced it in that turn.

## Scoring

### Top section: 1–6

- Score = **sum of the dice showing that number** (at most 5 dice). Example: three 4s = 12.
- **Bonus:** if a column's 1–6 total is **≥ 60**, add **+30**.
  - Row "SUM (60+30)" = 1–6 total (+30 if the bonus applies).

### Middle section: Max / Min

- **Max** = sum of the 5 chosen dice (aim high).
- **Min** = sum of the 5 chosen dice (aim low).
- Row "SUM (Max−Min)×1" = **(Max − Min) × the value in that column's "1" row**.
  - This **can be negative** if Max < Min.
  - If the "1" cell is 0 or X, this section scores 0.
  - A negative result is subtracted from the total score.
  - **Max and Min can never be crossed out.** They always score the dice sum, even a bad one.

### Bottom section

| Row | Requirement | Score |
|---|---|---|
| **Quint** | 1-2-3-4-5 or 2-3-4-5-6 | **66** on roll 1, **56** on roll 2, **46** on roll 3 |
| **Full (3+2)** | 3 of one number + 2 of a **different** number. Five of a kind does **not** count. | sum of the 5 dice **+ 30** |
| **Poker (4)** | at least 4 of a kind. Five of a kind counts. | sum of **the 4 matching dice** **+ 40** |
| **Yamb (5)** | 5 of a kind | sum of the 5 dice **+ 50** |

If the dice don't meet the requirement, the cell can only be crossed out (X = 0).

### Totals

- Per column: top SUM, middle SUM, bottom SUM.
- Each section's SUM is also totalled across the 4 columns.
- **Final score** = top total + middle total + bottom total.

## Worked example (Basha's sheet, final score 1541)

| | ↓ | Free | ↑ | ANN | Total |
|---|---|---|---|---|---|
| 1–6 (+bonus) | 65+30 = 95 | 61+30 = 91 | 36 | 87+30 = 117 | 339 |
| (Max−Min)×1s | (27−9)×5 = 90 | (27−9)×3 = 54 | (30−10)×3 = 60 | (26−6)×5 = 100 | 304 |
| Quint+Full+Poker+Yamb | 66+58+56+X = 180 | 56+56+52+75 = 239 | 66+45+64+75 = 250 | 56+46+52+75 = 229 | 898 |
| **Final** | | | | | **1541** |
