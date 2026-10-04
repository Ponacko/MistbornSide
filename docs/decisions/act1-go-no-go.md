# Act 1: go or no-go

Date: 2026-10-04. Status: **recommendation, provisional on playtests.**

## Recommendation

**No-go for committing to Act 1 today; go for running the slice playtests now, then decide.**

The slice is complete as software: both missions play start to finish, every M0 and M1 system is in and covered by 200+ headless tests, including scripted runs of the rooftop course, the guard corridor (four ways), the stealth yard, the pursuit route and both missions. But the question this decision turns on, whether the Allomancy feels good to people who have never seen it, has not been asked of a single person. DESIGN.md 15.3 names feel as the top risk and says the slice decides whether the game is worth making. Nothing in the repository yet answers that.

## Decide go if, after the playtests
- The M0 exit criterion holds for at least three of the first-time testers: they cross the grey-box course by coin-jumping within ten minutes and want to keep going.
- At least four of five slice testers finish both missions, and mission 4 lands near its 8 to 12 minute target.
- Testers describe Pushing and Pulling in terms of weight and momentum rather than fighting the controls (the failure mode of every earlier fan prototype).
- No beat is a wall: no more than two testers stuck for five minutes at the same place.

## Decide no-go, or rework first, if
- Aiming complaints dominate (wrong metal, wrong direction): revisit Steelsight and targeting before any content.
- Testers bounce off the force model (floaty, twitchy, uncontrollable): retune with the F1 panel during the sessions and re-test before building more.

## What going would cost first
- Art: every environment and character is a procedural stand-in on the real normal-mapped pipeline (`art/characters` sheets exist to paint over). Act 1 needs a pixel artist before content.
- Audio: synthesized placeholders; Act 1 needs a composer and sound designer.
- Content: thirteen more Act 1 missions and the Luthadel hub (DESIGN.md 10.1, 9.1), most needing systems not yet built (zinc and brass, the balls' social stealth, Kelsier as a playable character, boss phases).
