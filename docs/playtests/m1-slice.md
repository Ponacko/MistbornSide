# M1 vertical-slice playtest

Status: **not yet run.** No testers have played the slice. The protocol and the record sheet are ready; the results sections are empty until sessions happen.

## Build
- Title screen, New game (mission 4, the bridging card, mission 9, the ending card), Missions (mission 9 unlocks after 4), Settings (every DESIGN.md 7.3 option, key remapping), Practice yard (the M0 grey box), pause menu on Esc.
- Saves story flags, settings and bindings to `user://save.json`; checkpoints within missions.
- Export with `tools/export.sh` once the Godot 4.7.2 export templates are installed (not installed on the development machine as of 2026-10-04, so no exported build exists yet).

## Who
At least five testers, with at least two readers of the books and at least two action-platformer players who have not read them. None may have seen the game before.

## Protocol
1. Hand over the exported build with keyboard and mouse. Say only: "It is a fan game based on Mistborn. Play until you want to stop."
2. Observe silently; do not help unless a tester is stuck for five minutes on one beat (record it).
3. Record per mission: time to finish (the mission's own clock: `Mission.elapsed`), deaths per beat, prompts that confused, places they got lost.
4. After both missions ask: what did Allomancy feel like? What was hardest? Would you play the rest? Readers: did it feel like the book?

## Targets from the design
- Mission 4: 8 to 12 minutes on a first playthrough.
- Mission 9: 15 to 20 minutes on a first playthrough (proposed).
- A scripted bot clears each mission in about 30 seconds with dialogue skipped, so replays under three minutes are possible; whether humans manage it is still to be measured.

## Results

| Tester | Reader? | M4 time | M4 deaths | M9 time | M9 deaths | Bugs | Quote |
|---|---|---|---|---|---|---|---|
| | | | | | | | |

## Findings

(none yet)
