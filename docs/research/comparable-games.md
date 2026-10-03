# Research: Comparable 2D Games, Fan Prototypes, Godot Notes, IP

Supporting research for `docs/DESIGN.md`. Compiled 2026-10-02 from web sources (listed at the end). Some primary pages (Ori fandom wiki, Coppermind's Birthright article, 17th Shard physics thread) blocked automated fetching; where only search excerpts were available this is noted.

## 1. Traversal-feel references

### Ori and the Blind Forest / Will of the Wisps: Bash (closest analogue to Steelpush)
Near a bashable object the player holds a button, the world freezes, an arrow shows the launch direction, the player aims with the left stick, and on release Ori flies along the arrow while the object flies the opposite way. Feedback stack: bashable objects glow and a "wake-up" sound plays in range; during the hold time stops and the arrow shows Ori's launch vector; on release there is an explosion VFX, sound, and rumble. Will of the Wisps moved Bash to LB so jump (right thumb) and Bash (left index) can be chained without thumb contention.

Momentum: releasing with a neutral stick preserves horizontal momentum; a double-jump cancels downward momentum; Bashes chain indefinitely. Redirected projectiles go opposite to Ori's aim, so Bash is also a reflect.

Lessons: hold-to-freeze, release-to-commit. Draw the resulting vector, not the input vector (for Mistborn: two arrows scaled by mass ratio). Put Push/Pull on the opposite hand from jump. Preserve horizontal momentum on neutral release.

### Teslagrad (magnetic polarity)
Praised as easy to learn, hard to master, but criticised for controls lacking finesse and for no visual representation of field strength, making landings unpredictable. Lesson: blue lines show direction but not magnitude; encode strength in thickness/brightness and consider a predicted trajectory ghost while aiming.

### Magnetic by Nature
Smooth magnet physics, but weak baseline run/jump made the non-magnet moments feel bad. Lesson: do not neglect Vin's baseline movement.

### Bionic Commando (NES / Rearmed)
Three fixed arm angles; levels authored to those angles; low control lag. Rearmed's ragdoll rope was called stiff. Lesson: a small fixed set of aim angles is viable only if levels are built for them; a generic physics engine can make a grapple worse.

### Umihara Kawase
Elastic line, reel in/out, bounce, vault. Elasticity is expressive but hard to master. Ironpull could use a mild spring model (force grows with distance up to a cap).

### Worms ninja rope
Beloved because predictable in collisions and conserves momentum; later versions "lose momentum" and were disliked. Lesson: predictability and momentum conservation are the whole appeal.

### Aiming schemes compared
- Flinthook: aim with the movement stick, 360 degrees, a few degrees of aim assist, hook snaps to discrete rings.
- Grapple Dog: hook only up or 45 degrees up; called restrictive.
- Gravity Circuit: hook direction from d-pad; "pressing up while moving forward reads as diagonal" caused deaths; dev declined input buffering because valid directions are state-dependent, added a dedicated vertical-hook button instead.
- Webbed: mouse click zips to a point; swinging praised, precise aiming called flaky.
- SpiderHeck: minimal controls, intuitive to move, hard to master.
- Pepper Grinder: one trigger overloaded for drill/grapple/cannon with inconsistent release semantics; criticised.

Lessons: aim shared with movement produces diagonal errors; fix with right stick/mouse, hold-to-freeze, or target cycling. Discrete targets plus aim assist beat free aim. One verb per button with consistent hold/release semantics. Buffer Push/Pull inputs and design the state machine for buffering from the start.

### Celeste, Super Meat Boy, Mario, GDC "Building a Better Jump"
Celeste forgiveness: coyote time, jump buffering, halved gravity at apex while holding jump, corner correction, lift momentum storage, wall jump from 2 px away. A 4-frame jump buffer raised successful jumps in testing from 78% to 99.2%. Super Meat Boy spent three months on jump physics. Mario reduces gravity while rising with A held. Pittman's GDC talk derives gravity and launch velocity from designer values (jump height, time to peak), with different gravity on the way down.

Lessons for Steelpush: "Push coyote time" on coins that just left the ground; lift momentum storage maps to Pushing off a moving object; parametrize Push force by designer values; lower gravity at the apex of a Push arc while the button is held for the "hanging in the mists" feel.

### Others
- Katana Zero: slow-mo is a depleting resource; deflect bullets in slow-mo; full-speed replay of each room. A Push-chain replay is a cheap on-theme flourish.
- Mark of the Ninja: transparent systems, visualised sound rings and vision cones. Template for tin.
- Hyper Light Drifter: unclear dash cooldown and missing buffering drew complaints. Dead Cells and Hollow Knight are the buffering standard. Decide which Mistborn actions are committed and which cancel.
- Rain World: procedural limb animation; a verlet chain is the cheap way to do mistcloak tassels.
- Noita: emergence vs exploits; physics Pushes on dynamic props produce both.
- Hollow Knight: downward pogo is precedent for "Push down off a coin to bounce".

## 2. Game-feel synthesis for Steelpush/Ironpull
1. Detection: metal in a radius gets a blue line, thickness = available force (mass/anchoring and distance). Line-of-sight only.
2. Targeting: hold Push or Pull; time scales to ~0.1-0.2; nearest eligible metal in an aim cone highlights; d-pad users get nearest in that octant; no input defaults to last target or nearest.
3. Preview: two arrows scaled by mass ratio. Anchored object: full arrow on Vin. Loose coin: long arrow on coin, stub on Vin. A coin resting on ground counts as anchored.
4. Commit: release; apply impulse; keep horizontal momentum on neutral stick; short lockout plus hit-stop and rumble.
5. Forgiveness: Push buffering, Push coyote time, smooth force falloff with distance (abrupt range cutoff was the top complaint on the best-known fan game), corner correction.
6. Hold-to-sustain: holding after launch applies continuous force with falloff; enables hovering at equilibrium; cap it.
7. Coins: drop spawns a rigid coin; it becomes an anchor on resting contact. Pushing a coin horizontally is a ranged attack; Pulling a coin in flight is a catch.

## 3. Existing Mistborn fan games and the cancelled official game

### 2D fan prototypes
- MightyJor's Mistborn Fan Game (itch.io): steel launches from ground, pushable lanterns, coins as anchors. Complaints: sticks to ceilings/walls; push sometimes pulled; push cuts off abruptly at max range causing jitter; too-rapid deceleration; cannot push a coin below without jumping first; accidental coin drops; keyboard layout issues. Requests: smooth range falloff, remappable controls, combat.
- Mistborn: Project Coinshot (droxdev): pixel-art degree project explicitly modelling iron/steel on Ori's Bash, gamepad-first, challenge rooms.
- Mistborn Pushing Heights (Sutams): Era 2 themed, three levels.
- Small Unity prototypes by BlankisDev, itsjustoneguy, gramlingc.

### 3D fan prototypes
- Worldhopper (jsevilla, Unity): metals classed as static, dynamic (moves by weight), and coins; thin rays to metals in range; a button cycles targets prioritising on-screen ones; iron and steel meters with three vials each. Reusable: the three-class taxonomy and on-screen-first cycling.
- Allomancy (defantazer, Unreal): praised mostly for mistcloak and atmosphere.

Recurring failure modes: aiming (wrong direction, wrong metal), loss of control after launch, harsh velocity edges, no combat loop. None implemented Ori-style freeze-and-preview.

### Mistborn: Birthright (Little Orbit, 2012-2017)
Original prequel story by Sanderson, ~300 years before the trilogy, following noble Fendin "Fiddle" Fathvell. Pitched as fast-paced action with RPG elements. 2014 plans mentioned an open world combining Assassin's Creed and Dishonored with Allomancy physics, "ironpushing off rivets in the ground". Cancelled 2017; rights reverted to Sanderson. A search excerpt suggests Sanderson once pitched a 2D Symphony-of-the-Night-style Mistborn game (unverified). As of 2024-2025 he is in early talks with AAA studios for a licensed game.

## 4. Structure options for a fixed-plot adaptation
- A. Linear level-based (Katana Zero, Mark of the Ninja): full control of beats, cheapest per hour, easy difficulty tuning; but corridors can reduce blue lines to grapple points.
- B. Full metroidvania (Hollow Knight, SotN): natural ability gating; but highest content/QA cost, Push invites sequence breaks, fixed plot conflicts with free order (Lost Crown critique), and the trilogy leaves Luthadel repeatedly.
- C. Cutscene-heavy action-adventure (Blasphemous): A with heavier presentation; Blasphemous's cryptic approach is the opposite of what a plot-heavy novel needs.
- D. Hub-city plus story missions (recommended): "Luthadel at night" traversal hub plus authored linear missions. Hub-and-spoke per Totten; mirrors the book; hub is one reusable asset that gets better with every metal unlock; missions stay cheap and tuned. Cons: two level-design languages; hub needs side content; story gating must prevent sequence breaks. No notable 2D indie does open-city swinging plus story missions; a gap, not a warning.

## 5. Multiple playable characters
Trine (bound trio, swap any time), Lost Vikings (all present, sequence puzzles), Castlevania III (one companion, recruited on branches), Portrait of Ruin (tag team plus AI partner commands), Streets of Rage (pick at start).

Mapping: Vin is the sole full-kit character; every Misting is Vin with a metal mask (one Allomancer controller). Castlevania III model for mission-specific crew (Kelsier prologue, Marsh bronze infiltration, Spook tin scouting) that teaches single metals without Steelpush fallback. Portrait of Ruin partner call-ins for Ham and Breeze. Free swapping conflicts with fixed plot; avoid. Sazed's weight-storing interacts with Pushes; a single "weight slider" mission is the cheapest version.

## 6. Godot 4 implementation notes
- CharacterBody2D for Vin and enemies, RigidBody2D for coins and props. Keep an external_velocity term that Pushes add to and that decays via move_toward, blended with input velocity.
- Equal and opposite: one force F; apply_central_impulse(-F) on the coin, +F/vin_mass to Vin's external velocity. Coin is anchored (infinite mass) when it has a resting contact or is sleeping, or when the target is a StaticBody2D.
- Do not switch Vin between body types mid-flight.
- custom_integrator is the wrong tool for a platformer protagonist; known flicker issue #56049.
- Detection via Area2D radius plus ShapeCast2D/RayCast2D for line of sight; lines via Line2D or _draw with width mapped to force.
- Slow motion: Engine.time_scale affects physics and timers; pair with AudioServer.playback_speed_scale; keep UI and cursor on process_mode ALWAYS or scale deltas manually. Enable physics interpolation so low time_scale does not stutter.

## 7. IP and legal notes
Dragonsteel's policy: no objection to non-commercial fan art and fan fiction. Crowdfunding of any fan project is forbidden. Licensing requires signed written permission. Fan video games are not explicitly addressed; many Mistborn fan prototypes have sat on itch.io for years. Risk factors: any monetisation or donations, crowdfunding, the IP name in storefront/studio branding, and the active AAA licensing talks. Practical stance: free, no donations, clearly labelled unofficial, keep the name out of studio branding, and build systems so they could be reskinned as original IP.

## Sources
Ori: marianevincent93.wixsite.com Bash analysis; critpoints.net Ori overview; viciousundertow.wordpress.com traversal piece. Teslagrad: pushsquare.com, playstationlifestyle.net, bigredbarrel.com. Grapple games: hardcoregaming101.net Bionic Commando; engadget.com Umihara Kawase; Steam threads for Worms, Gravity Circuit, Pepper Grinder; godisageek.com Flinthook; videochums.com Grapple Dog; screenhub.com.au and vooks.net Webbed. Game feel: threadreaderapp.com Thorson thread; gamejuice.co.uk coyote time; critical-gaming.squarespace.com Super Meat Boy; media.gdcvault.com Pittman slides; gamedeveloper.com Mark of the Ninja articles; unity.com Rain World; gdcvault.com Noita. Fan games: mightyjor.itch.io, droxdev.itch.io, jsevilla.itch.io, defantazer.itch.io, sutams.itch.io. Birthright: pcgamesn.com, techraptor.net, vice.com, gamespot.com. Structure: gamedeveloper.com Totten excerpt; fextralife.com Lost Crown; abstractinggames.com Blasphemous; metroidvaniareview.com Portrait of Ruin. Godot: dev.to knockback article; kidscancode.org; ludonauta.itch.io devlog; github.com/Frogbeerr grappling demo; docs.godotengine.org; godot issue #56049. IP: brandonsanderson.com/pages/fan-art-policy; faq.brandonsanderson.com.
