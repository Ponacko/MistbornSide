# M0 grey-box playtest

Status: **not yet run.** No first-time testers have played the build, so the Milestone 0 exit criterion (a new tester crosses the course by coin-jumping within ten minutes and asks to keep playing) is not met yet.

## What exists
- Rooftop course in `levels/greybox/greybox.tscn` with six Allomantic problems: Pull up to a high bracket; Pull across a street and retarget; Push off a gate across a gap; climb a wall off a grate and a wall plate; a coin jump that only works standing over the coin (anchor cone); a mid-fall Push off a spire. A timer runs from the first input to the goal flag.
- Each problem has a scripted solution in `tests/unit/test_rooftop_course.gd`, so it can be crossed with the default tuning.
- F1 opens the live tuning panel (save, load, reset presets).

## What changes next
1. Install the Godot 4.7.2 export templates (about 1.3 GB) and export a desktop build.
2. Observe at least three first-time testers; for each, record time to the goal, failures per problem and quotes in this note.
3. Save the preset used as `data/tuning/m0_final.tres`.
