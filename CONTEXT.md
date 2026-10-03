# MistbornSide

A 2D sidescrolling retelling of the original Mistborn trilogy played as Vin. This glossary fixes the words the design, code and levels use for the game's own concepts.

## Language

### Structure

**Act**:
One of the three books, adapted as a chapter of the game with its own hub state and mission chain.
_Avoid_: Book, chapter (reserved for the novels), episode

**Hub**:
The freely explorable city space the player roams between missions; its state changes as the story advances.
_Avoid_: Overworld, open world, map

**Mission**:
A hand-authored linear level adapting one or two chapters of a book, launched from a story trigger in the hub.
_Avoid_: Level, stage, quest

**Set piece**:
A scripted moment inside a mission that reproduces a specific scene from the books.
_Avoid_: Event, cutscene (a cutscene has no player control)

### Allomancy

**Metal source**:
Any object in the world that an Allomancer can Push or Pull on; it has a mass and is either anchored, dynamic or carried.
_Avoid_: Metal object, target (a target is the metal source currently selected), magnet

**Anchor**:
A metal source that does not move when Pushed or Pulled, so all the force goes to the Allomancer. Fixed metal is always an anchor; a coin resting on the ground is an anchor for Pushes directed into the surface.
_Avoid_: Fixed point, grapple point

**Blue line**:
The visible line from an Allomancer's chest to a metal source while burning steel or iron; thickness shows mass, brightness shows distance.
_Avoid_: Tether, beam, ray

**Target**:
The one metal source currently highlighted for the next or current Push or Pull.
_Avoid_: Selection, lock

**Burn**:
Using a metal at normal intensity, draining its reserve at its base rate.
_Avoid_: Activate, cast, use

**Flare**:
Burning a metal harder for more effect at several times the drain. A held modifier, not a separate ability.
_Avoid_: Boost, overcharge, charge

**Steelsight**:
The brief slow-time window that opens when the player presses Push or Pull with no target highlighted; it closes when a target is found, the window expires, or the button is released.
_Avoid_: Bullet time, aim mode, slow-mo

**Reserve**:
The amount of one metal an Allomancer has swallowed and can still burn.
_Avoid_: Mana, fuel, meter, charge

**Pewter crash**:
The stagger and slowdown an Allomancer suffers when pewter runs out after heavy use.
_Avoid_: Burnout, exhaustion, debuff

### Characters

**Companion**:
A crew member who fights beside the player under simple AI, cannot die, and never leaves the player's path.
_Avoid_: Ally, partner, escort, NPC follower

**Demonstrator**:
A crew member who performs a move once as a scripted animation so the player can copy it, then waits at the next vantage point.
_Avoid_: Tutorial NPC, guide

### Stealth

**Suspicion**:
A guard's three-stage awareness of the player: idle, suspicious, alerted. Soothing lowers it; noise, light and Seeker detection raise it.
_Avoid_: Alert level, aggro, detection meter

**Seeker detection**:
The second detection channel: a bronze-burning enemy notices any metal the player burns within its radius unless copper is on.
_Avoid_: Magic detection, aura
