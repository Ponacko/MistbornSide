=================== #1
M0: Project foundation and base movement
## What to build

The Godot project is configured for the game as decided in DESIGN.md section 14 (640 by 360 base viewport with integer scaling, pixel snap, 2D physics interpolation, Forward Plus kept, the Jolt 3D physics setting removed) and has the keyboard-and-mouse input map from section 7.1 with gamepad bindings as a parity target. A grey-box test scene contains a placeholder Vin who runs, jumps, grabs ledges, slides down walls and crouches with Celeste-style forgiveness (coyote time, jump buffering, apex gravity reduction). No Allomancy yet. This is the prefactor every other ticket builds on.

## Acceptance criteria

- [ ] Project opens in Godot 4.7 with the decided display and physics settings and no 3D-only configuration left over
- [ ] Every action in DESIGN.md section 7.1 exists in the input map with its keyboard and mouse binding
- [ ] A grey-box scene runs at 60 fps where Vin runs, jumps, ledge-grabs, wall-slides and crouches
- [ ] Coyote time, jump buffering and apex gravity reduction are implemented and exposed as tunable values
- [ ] A folder convention for scenes, scripts, art, audio and levels is in place and described in the README

## Blocked by

- None, can start immediately

=================== #2
M0: Metal sources and blue lines
## What to build

Every metal object in the grey box is a metal source with a mass and a class (anchored, dynamic or carried), registered so nearby sources can be queried cheaply. While Vin has steel or iron available, blue lines run from her chest to every source within range: thickness encodes mass, brightness falls off smoothly with distance, lines through walls are drawn dimmer, lines are drawn above the world but below the HUD. The best source near the mouse cursor is highlighted continuously as the target, scored by cursor distance weighted by mass, with the heuristic fallbacks from DESIGN.md section 5.5 when there is no aim input. Nothing is Pushed yet; this ticket is the reading layer.

## Acceptance criteria

- [ ] Placing a metal source component on any node gives it mass, class and inside-body flag and registers it
- [ ] Blue lines render for all sources within range with thickness by mass and brightness by distance, dimmer through walls
- [ ] Exactly one source is highlighted as the target at any time, following the cursor, with fallbacks when the cursor is idle
- [ ] Lines and highlight update without visible hitching with at least 60 sources in range
- [ ] Lines are drawn on a layer that the mist shader will not affect

## Blocked by

- #1 (M0: Project foundation and base movement)

=================== #3
M0: Steelpush and Ironpull on anchors
## What to build

Holding left mouse Pushes on the target and holding right mouse Pulls, applying one force along the line as equal and opposite impulses each physics frame per DESIGN.md section 5.4: anchored sources receive nothing, dynamic ones share by mass. Force falls off smoothly to zero at range with no abrupt cutoff. Holding sustains the force; releasing stops it; Shift flares (about 1.6x force, 4x drain). Steel and iron reserves drain while used and are shown as vials in a first HUD; a vial pickup refills them. Force constants are derived from designer-facing values (a full Push off an anchor reaches a stated height in a stated time). Momentum is conserved and gravity is reduced near the apex while the button is held. Vin can launch off a fixed anchor, hover at equilibrium above one, and Pull herself to a bracket across a gap.

## Acceptance criteria

- [ ] Pushing on an anchored source launches Vin; Pulling on one brings her to it; a dynamic source and Vin both move by mass ratio
- [ ] Force falls off smoothly with distance and there is no jitter at range
- [ ] Holding sustains the force, releasing stops it, Shift flares with visibly more force and faster drain
- [ ] Steel and iron reserves drain, show in the HUD, and refill from a vial pickup; empty reserves disable the ability without a fail state
- [ ] Tuning values are expressed as reach height and time, not raw force, and are editable live
- [ ] Vin can hover at equilibrium above an anchor and the hover self-stabilises

## Blocked by

- #2 (M0: Metal sources and blue lines)

=================== #4
M0: Coins
## What to build

Vin carries a finite pouch of clips. E flicks a coin toward the cursor; S plus E drops one at her feet. Coins are rigid bodies that settle and become anchors for Pushes within the 35 degree anchor cone of the surface normal, skidding with partial lift outside it. The classic drop-and-Push jump works, including Push coyote time on a coin that just left the ground. Pushing an airborne coin turns it into a projectile that kills a target dummy; holding Pull with no target recalls loose coins to the pouch and catches coins in flight. E plus left mouse sprays several coins in a fan. Coins pool and merge so the physics budget holds with dozens in the scene.

## Acceptance criteria

- [ ] Pouch count is finite, shown in the HUD, decremented on flick and drop, incremented on recall
- [ ] A resting coin is an anchor inside the cone and skids outside it, and this reads clearly in the preview arrows
- [ ] Drop-and-Push launches Vin to the tuned height; Push coyote time accepts a Push on a coin that left the ground within a few frames
- [ ] A Pushed airborne coin kills a target dummy; coin spray fires a fan
- [ ] Holding Pull with no target recalls coins within range and catches coins in flight
- [ ] Sixty active coins do not drop the frame rate; coins beyond the pool merge into piles

## Blocked by

- #3 (M0: Steelpush and Ironpull on anchors)

=================== #5
M0: Steelsight and forgiveness
## What to build

Pressing Push or Pull with a target highlighted fires instantly. Pressing with no target opens Steelsight: time slows to about 15 percent for up to 0.25 seconds while the player finds a target, and the Push commits the moment one highlights, the window ends, or the button is released, ramping time back over 0.2 seconds while the force already acts. A single time controller owns the time scale and audio pitch together and keeps the HUD and cursor at normal speed. Moving the cursor to another source while holding retargets without releasing; the mouse wheel cycles candidates. While a target is highlighted the game draws two arrows scaled by mass ratio (long on Vin for an anchor, long on the coin for a loose coin) and a faint half-second predicted arc during Steelsight. Push inputs are buffered for a few frames and corner correction nudges Vin around ledges she clips mid-arc.

## Acceptance criteria

- [ ] A press with a highlighted target has no added latency; a press with none slows time and commits as specified
- [ ] The time controller scales physics and audio pitch together while the HUD and cursor stay at full speed
- [ ] Retarget while holding and target cycling both work and are discoverable through the highlight
- [ ] Preview arrows show the mass ratio correctly for anchored, dynamic and carried sources; the arc preview appears during Steelsight
- [ ] Input buffering and corner correction are implemented and tunable
- [ ] Every timing and factor in this ticket is exposed in a settings resource

## Blocked by

- #4 (M0: Coins)

=================== #6
=================== #7
M0: Pewter and tin
## What to build

Keys 1 and 2 toggle pewter and tin, which burn continuously while on and drain reserves at their own rates (pewter fastest). Pewter: 1.4x run speed, 1.3x jump, half damage from a test hazard, no stagger from light hits, shoulder through a weak board; flaring raises it further; running out while flared or after about 40 seconds of continuous flare triggers the pewter crash (two second stagger, ten seconds slowed). Tin: the mist shader thins and visible radius grows, darkness lifts, footsteps and voices from test emitters draw expanding rings through walls, hidden metal glints; a test lantern flash whites out the screen and stuns Vin for a second while tin is on. Flaring tin pulses a one-off reveal.

## Acceptance criteria

- [ ] Pewter and tin toggle on and off, burn continuously, show in the HUD vials and drain at distinct rates
- [ ] Pewter changes speed, jump, damage taken and stagger as specified and lets Vin break a weak board
- [ ] The pewter crash triggers under the specified conditions and reads clearly on screen
- [ ] Tin thins the mists, extends visibility, draws noise rings from emitters through walls and highlights hidden metal
- [ ] A lantern flash whites out and stuns Vin only while tin is on
- [ ] There is no deferred pewter debt damage

## Blocked by

- #6 (M0: Mists and night atmosphere)

=================== #8
M0: Mistcloak
## What to build

Vin wears the mistcloak: about a dozen verlet chains of charcoal grey tassels hanging from her shoulders, driven by her velocity and by wind sampled from the mist flow field, rendered as textured strips. The cloak fans wide on a launch, trails on a fall, settles when she stands, and twists like the mists while she walks. It is Vin's silhouette and must read at her 48 pixel sprite height.

## Acceptance criteria

- [ ] Tassel chains simulate stably at 60 fps and never explode under a flared Push
- [ ] The cloak fans on launches, trails on falls and settles on landing
- [ ] Wind from the mist flow field visibly moves the cloak while Vin stands still
- [ ] The cloak can be hidden for the Valette scenes with one flag

## Blocked by

- #1 (M0: Project foundation and base movement)

=================== #9
M0: Tuning panel and grey-box playtest
## What to build

A debug panel lets a designer edit every force, falloff, Steelsight, coin, pewter and tin value live while playing, save and load named presets, and reset to defaults. The grey-box scene is expanded into a rooftop course with coins, brackets, a gate, gaps and a wall climb. An exported desktop build goes to at least three testers who have never seen the game. Milestone 0 passes when a new tester crosses the course by coin-jumping within ten minutes and asks to keep playing; the findings and the final preset are recorded in the repo.

## Acceptance criteria

- [ ] Debug panel edits every tunable from DESIGN.md sections 5.4 to 5.8 live, with save, load and reset
- [ ] A rooftop course exists with at least five distinct Allomantic traversal problems
- [ ] An exported build runs on a machine without Godot installed
- [ ] At least three first-time testers are observed; their times, failures and quotes are recorded in a playtest note
- [ ] The milestone exit criterion is met, or the note records why not and what changes next

## Blocked by

- #5 (M0: Steelsight and forgiveness)
- #7 (M0: Pewter and tin)
- #8 (M0: Mistcloak)

=================== #10
M1: Guards and Vin's melee
## What to build

A keep guard patrols a route, carries a spear and a breastplate (carried metal sources), and attacks on contact. Vin has health that pewter halves and slowly regenerates, a three-hit dagger combo, a dash stab, an aerial plunge, a backstab that kills an unaware guard instantly, a pewter heavy attack, and a dodge roll with invulnerability frames. Pushing a guard's breastplate shoves him back or off a roof; Pulling his spear disarms him on a grip check. Coins kill unarmoured guards in one hit and lightly armoured ones in two. Dying restarts Vin at the last checkpoint. A test corridor with three guards can be cleared by stealth kills, coins, shoves or fighting. Lethal by default; there is no knockout state.

## Acceptance criteria

- [ ] A guard patrols, notices Vin on contact and attacks; he dies to backstab, two coins, a dagger combo or a fall
- [ ] Pushing on a guard's armour moves him by his body mass; Pulling his weapon disarms him on a grip check
- [ ] Vin has health, pewter mitigation, dagger combo, dash stab, plunge, backstab, heavy and dodge with invulnerability frames
- [ ] Death returns Vin to the last checkpoint with reserves and pouch restored to the checkpoint state
- [ ] The test corridor can be completed at least four different ways

## Blocked by

- #7 (M0: Pewter and tin)

=================== #11
M1: Stealth layer
## What to build

Guards gain the three-stage suspicion state (idle, suspicious, alerted) with an icon above them. Vin is hidden in shadow and visible in lantern light; landing hard and fighting make noise rings that guards react to and that tin shows. Keys 3 and 4 toggle copper and bronze: a Seeker obligator detects any metal Vin burns inside his radius unless copper is on, and bronze shows Allomancer enemies as pulsing beacons through walls labelled by type after a moment. A lantern bearer blinds tin-burning Vin if he swings his lantern at her; Rioting is not in scope yet. An alarm bell summons reinforcements when rung and can be Pushed silent. A test yard with patrols, a Seeker and a bell can be crossed unseen.

## Acceptance criteria

- [ ] Suspicion rises and falls per the rules in DESIGN.md section 6.4 and shows as a readable icon
- [ ] Vin is hidden in shadow and seen in light; noise rings alert nearby guards
- [ ] The Seeker detects burning without copper and not with it; bronze reveals Allomancers through walls
- [ ] Lantern bearers blind Vin only while tin is on
- [ ] The alarm bell summons reinforcements and can be silenced by Pushing it
- [ ] The test yard can be crossed without triggering an alert

## Blocked by

- #10 (M1: Guards and Vin's melee)

=================== #12
M1: Hazekillers and the Inquisitor pursuer
## What to build

Hazekillers arrive in squads of four to eight, carry wooden shields and staves and no metal, so Push and Pull do nothing to them and coins bounce off their shields; they are beaten with daggers, pewter heavies that break shields in two hits, and the environment. Inquisitor Bendal is a pursuer: immune to Push and Pull, pewter-fast, he coin-jumps along an authored route behind Vin, closes if she stalls, Pushes her coins back at her and strikes with an obsidian axe that removes most of her health. On a test route Vin can outrun him only by moving well; standing to fight loses.

## Acceptance criteria

- [ ] A hazekiller squad engages Vin as a group, ignores Pushes, blocks coins with shields and loses shields to two heavy hits
- [ ] Bendal follows an authored route by coin-jumping, closes distance when Vin stalls and strikes with the axe
- [ ] Bendal Pushes Vin's coins back when she shoots at him and cannot be moved by her Pushes
- [ ] The mists part around Bendal using the repeller from the mists ticket
- [ ] On the test route a competent run escapes and a stalled run dies

## Blocked by

- #10 (M1: Guards and Vin's melee)

=================== #13
M1: Companion and demonstrator
## What to build

Kelsier can be placed in a level as a companion: he follows Vin through corridors, engages the nearest guard with dagger and shove, cannot die, and never leaves her path or Pushes off into traversal. Separately, Kelsier can be placed as a demonstrator: at a lesson beat he performs one scripted move (for example drop a coin, Push, land on a higher roof), then waits as a silhouette in the mists at the next vantage point until Vin arrives. Both are the same character with two behaviour modes and will serve Ham and Breeze later.

## Acceptance criteria

- [ ] Companion Kelsier follows through a test corridor, fights beside Vin, cannot die and never blocks a doorway for more than a moment
- [ ] Demonstrator Kelsier performs a scripted move on trigger, then waits at the next marker as a silhouette
- [ ] A level designer can place either mode with markers and no code
- [ ] Switching between modes mid-level is possible for the split at the hut in mission 9

## Blocked by

- #10 (M1: Guards and Vin's melee)

=================== #14
M1: Dialogue, cutscenes and prompts
## What to build

A data-driven dialogue system plays scenes with the game's own sprites in a visual-novel frame: speaker, portrait, lines, and choice points where Vin may Soothe or Riot with a visible consequence recorded as a story flag (light dialogue, as decided). An in-engine cutscene convention lets a level play a scripted sequence with the camera and characters and hand control back. Tutorial prompts show a key binding and can gate progress until the player performs the action. The HUD is finished: eight vials, atium beads, coin count, a health bar that fades when full, and screen-edge tints for pewter and tin.

## Acceptance criteria

- [ ] A sample scene plays from data with a Soothe or Riot choice that sets a flag and changes a later line
- [ ] A sample cutscene moves the camera and a character, then returns control
- [ ] A prompt can require a specific input before the level advances and never shows twice
- [ ] The HUD shows reserves, beads, coins and health as specified and matches the art direction's minimal style
- [ ] Story flags persist across a level reload

## Blocked by

- #1 (M0: Project foundation and base movement)

=================== #15
M1: Atium
## What to build

Tab, held to confirm, burns an atium bead for about eight seconds. While burning, every enemy shows a translucent shadow performing its next action about 1.2 seconds ahead, projectiles draw their paths, time runs at 90 percent, Vin's dodge window is generous and her counters auto-aim. Pressing again stops the burn and the remainder is lost. Beads are rare pickups shown in the HUD. Against Bendal the shadow reveals the gaps in his attacks that let Vin grab the logbook and run.

## Acceptance criteria

- [ ] A bead burns for the tuned duration, shows enemy shadows about 1.2 seconds ahead and projectile paths
- [ ] Dodge is wider and counters auto-aim only while burning
- [ ] Stopping early loses the remainder; the HUD shows beads correctly
- [ ] Against the pursuer from the Inquisitor ticket, shadows reveal a safe window in his attack pattern

## Blocked by

- #10 (M1: Guards and Vin's melee)

=================== #16
M1: Mission 4, Eight Metals
## What to build

The first slice mission, built to final quality per its design note: Clubs' shop at night where Kelsier hands Vin the mistcloak and her first vial; the rooftop where tin reveals the city and a lamplighter demonstrates the whiteout; the gap that needs pewter; the coin lesson with the anchor cone; the Pull lesson on a lamp bracket and recalling a coin; the run to the city wall with Kelsier ahead as a silhouette; the top of the wall. Kelsier is a demonstrator, lessons use prompt-gated toggles in book order (tin, pewter, steel and iron), and the mission runs 8 to 12 minutes first time. Environment art for the rooftops, shop interior and wall is final pixel art with normal maps and night lighting.

## Acceptance criteria

- [ ] All seven beats from the mission note play in order with Kelsier demonstrating each move once
- [ ] Tin and pewter beats gate on the player's own toggle press and never prompt again afterwards
- [ ] The coin beat teaches the anchor cone with a gap that requires standing over the coin
- [ ] First-time testers finish in 8 to 12 minutes; replays under 3 minutes
- [ ] Rooftop, shop and wall environments are final art with normal-mapped lighting and the mists

## Blocked by

- #9 (M0: Tuning panel and grey-box playtest)
- #13 (M1: Companion and demonstrator)
- #14 (M1: Dialogue, cutscenes and prompts)

=================== #17
M1: Mission 9, Kredik Shaw
## What to build

The second slice mission, built to final quality per its design note: a stealth approach across the spire exterior with patrols and a Seeker obligator; interior corridors and halls fought alongside companion Kelsier where armour makes Pushes a weapon and the Lord Ruler's Soothing presses on Vin; the domed mural chamber and the hut; the unwinnable Bendal encounter where atium reveals the way to grab the logbook and run; the authored rooftop chase with Bendal as a live pursuer while Vin's health is pinned and pewter is locked on and draining; the scripted collapse at Sazed's carriage. Environment art for the exterior, interiors and chamber is final.

## Acceptance criteria

- [ ] The exterior can be crossed by stealth; being caught summons guards rather than failing the mission
- [ ] Interior fights are unavoidable arenas fought with companion Kelsier
- [ ] The Bendal encounter cannot be won, teaches the escape through atium shadows, and ends with the axe wound
- [ ] The chase uses the authored corridor with Bendal pursuing, pinned health, locked draining pewter, and death on empty pewter
- [ ] The mission ends at the scripted collapse and the Kredik Shaw environments are final art

## Blocked by

- #11 (M1: Stealth layer)
- #12 (M1: Hazekillers and the Inquisitor pursuer)
- #13 (M1: Companion and demonstrator)
- #14 (M1: Dialogue, cutscenes and prompts)
- #15 (M1: Atium)

=================== #18
M1: Character art pass
## What to build

Final normal-mapped pixel art sprite sets replace the placeholders for Vin (about 48 pixels, with every movement, combat and Allomantic state and the cloak attachment points), Kelsier, the keep guard, the hazekiller, the obligator and the Inquisitor, following the descriptions in the world-and-visuals research note. Inquisitor spikes catch light; the guard's breastplate reads as metal; Kelsier's scars show when the cloak flares.

## Acceptance criteria

- [ ] Every animation state used by the movement, combat, stealth and pursuer systems has a final sprite for each character
- [ ] Sprites are normal-mapped and respond to 2D lights
- [ ] Vin's cloak attaches correctly across all her states
- [ ] Silhouettes are distinguishable at gameplay zoom in the mists

## Blocked by

- #12 (M1: Hazekillers and the Inquisitor pursuer)

=================== #19
M1: Audio pass
## What to build

The slice sounds like the books: quiet night ambience with dripping condensation and distant forges, ash landing on tile; a low tonal hum while blue lines are visible that rises with flare; a soft pluck on target lock and a bass thump on launch; coin rings on landing; a heartbeat under pewter; the mix thinning with reverb under atium; pitch following the time controller during Steelsight. Placeholder music themes for the night city and for Kredik Shaw.

## Acceptance criteria

- [ ] Ambience, Allomancy, coin, pewter and atium sounds play in the grey box and both missions
- [ ] Steelsight lowers audio pitch with the time scale and restores it on ramp back
- [ ] Tin raises the ambient mix and brings in footsteps and voices through walls
- [ ] Placeholder music plays per area with a clean loop

## Blocked by

- #9 (M0: Tuning panel and grey-box playtest)

=================== #20
M1: Slice integration and playtest
## What to build

The two missions become one playable build: a title screen, a mission select limited to the slice, a bridging title card between mission 4 and mission 9 summarising the skipped chapters, checkpoints and a save of story flags and settings, the accessibility options from DESIGN.md section 7.3, and an exported desktop build. At least five testers, including readers of the books and action-platformer players who are not, play it start to finish; their results and the decision on whether to proceed to Act 1 are recorded.

## Acceptance criteria

- [ ] Title, mission select, bridging card, checkpoints, save and settings all work in the exported build
- [ ] The accessibility options in section 7.3 are present and functional
- [ ] At least five testers finish both missions; times, deaths, quotes and bugs are recorded
- [ ] A written go or no-go recommendation for Act 1 is added to the repo

## Blocked by

- #16 (M1: Mission 4, Eight Metals)
- #17 (M1: Mission 9, Kredik Shaw)
- #18 (M1: Character art pass)
- #19 (M1: Audio pass)

=================== #6
M0: Mists and night atmosphere
## What to build

The grey box becomes a night in Luthadel. A full-screen mist shader with scrolling noise and a flow field makes the mists move lazily, pool near floors and dissipate at interior doorways defined by room masks. The flow field has attractors on Allomancers who are burning metal, so the mists swirl toward Vin while she Pushes, and repellers for spiked beings (used later for Inquisitors and koloss). Ash falls as black flakes. Lanterns are 2D lights with warm colour. The mists are faintly luminescent so the night is never pitch black, and the blue lines layer is unaffected by the shader.

## Acceptance criteria

- [ ] Mists render over the grey box with lazy motion and floor pooling, and are masked out inside a marked interior
- [ ] Mists visibly swirl toward Vin while she burns steel or iron and settle when she stops
- [ ] A repeller marker pushes the mists away from a test object
- [ ] Black ash particles fall continuously; a lantern 2D light lights the scene warmly
- [ ] Blue lines remain fully readable through the thickest mist
- [ ] The shader runs at 60 fps at 640 by 360 on an integrated GPU

## Blocked by

- #3 (M0: Steelpush and Ironpull on anchors)

