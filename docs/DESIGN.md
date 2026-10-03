# MistbornSide: Game Design Document

**Working title:** MistbornSide (placeholder; see section 15 for naming notes)
**Version:** 0.1, 2026-10-02
**Engine:** Godot 4.7
**Status:** Pre-production. This document answers "what kind of game is this" and specifies the systems well enough to start the Allomancy prototype.

Supporting research lives in `docs/research/` (magic-system mechanics, chapter-by-chapter plot beats, comparable games and fan prototypes, world and art reference). Statements about the books below are sourced there.

---

## 1. One-paragraph pitch

A 2D sidescrolling action game that retells Brandon Sanderson's original Mistborn trilogy, chapter by chapter, with the player as Vin. You move through the ash-covered, mist-shrouded city of Luthadel the way a Mistborn does in the books: by Pushing and Pulling on metal. Coins are your springboard and your bullets. Every nail, latch, lamp post and guard's breastplate is a handhold or a weapon, shown as faint blue lines running to your chest. Between story missions the night city is yours to roam. The missions themselves are hand-built retellings of the books' set pieces: the Keep Venture heist, the first ball, Kredik Shaw, the siege of Luthadel, the Well of Ascension, the thirteen Inquisitors on the spires. The game is built around one promise: Allomancy that behaves, looks and feels exactly like it does on the page, with controls that stay comfortable while you are flying across rooftops at speed.

## 2. What kind of game this is (the central decision)

### 2.1 The answer

**A momentum-driven action-platformer with stealth, structured as a hub city plus linear story missions.** Roughly: the traversal of Ori and the Will of the Wisps (Bash is almost literally Steelpush), the stealth readability of Mark of the Ninja, the mission-and-cutscene cadence of Katana Zero, and a freely explorable night-time Luthadel between missions in the spirit of a 2D Spider-Man.

### 2.2 Why not the obvious alternatives

Four structures were weighed against the two hard constraints: a fixed plot that follows the books closely, and Allomancy as the centrepiece.

| Structure | Verdict | Reason |
|---|---|---|
| Linear level-based platformer only (Katana Zero, Mark of the Ninja) | Good, but incomplete | Cheapest content per hour and total control of story beats. But corridors turn blue lines into glorified grapple points. Steelpushing begs for open vertical space to play in. |
| Full metroidvania (Hollow Knight, Symphony of the Night) | Rejected | Vin learns all eight basic metals in chapter 7 of book 1, so there is no natural ability gating. The plot is fixed and leaves Luthadel repeatedly (Pits, Terris, Fadrex, Urteau). Push physics would invite constant sequence breaking. Highest content and QA cost for a small team. Prince of Persia: The Lost Crown shows what happens to a story forced into this shape. |
| Narrative action-adventure with heavy cutscenes (Blasphemous) | Folded into the answer | Blasphemous's cryptic storytelling is the opposite of what a beloved plot-heavy novel needs. The cutscene cadence itself is right. |
| Hub city plus story missions | Chosen | Mirrors the book: Vin lives in Luthadel and goes on discrete jobs. The hub is one reusable asset that gets more interesting with every technique and metal she masters. Traversal freedom lives where it is cheap (the hub); precision and set pieces live where they can be tuned (missions). The fixed plot is respected because missions are gated by story. |

### 2.3 What the hub-and-missions structure looks like in practice

- **Hub:** a continuous 2D slice of Luthadel at night, several screens tall and dozens of screens wide. Rooftops, keep spires, the city wall, canal bridges, skaa tenements, Kredik Shaw looming at one end. It is a traversal playground with optional content (Kelsier's training challenges, informant errands, hidden Alendi logbook pages, coin caches). The hub changes state as the story advances: house-war fires, the Garrison marching out, executions in the fountain square, the siege camps outside the walls in book 2, ash drifts burying streets in book 3.
- **Missions:** hand-authored linear levels launched from story triggers (Clubs' shop, Elend's balcony, the Renoux mansion). Each is one or two chapters of the book. Mission types: infiltration, assault, chase or escape, endurance traversal, social stealth (the balls), boss duel, and short non-combat exploration.
- **Cutscenes and dialogue:** in-engine, between and inside missions. Dialogue scenes use the game's own sprites in a visual-novel style frame, not pre-rendered video.
- **Acts:** three acts, one per book. The hub is rebuilt per act (see section 9).

### 2.4 Audience and tone

Readers of the trilogy first, action-platformer fans second. The tone follows the books: oppressive, quiet, melancholy, with explosive relief when Allomancy lets Vin fly. It is violent (Vin kills with coins) but never gratuitous. Rated roughly T.

### 2.5 Length and scope target

A full trilogy retelling at about 12 to 16 hours of play. Act 1 is the largest and most detailed because the heist structure of book 1 gives the richest mission set. The plan is to ship Act 1 first as a complete game ("The Final Empire") and treat Acts 2 and 3 as follow-ups built on the same systems. Section 15 gives milestones.

## 3. Design pillars

1. **Allomancy is physics, not animation.** A Push is a real force along a real line, equal and opposite, scaled by mass and distance. The player learns Kelsier's weight rule by feeling it, not by reading it.
2. **Faithful to the page.** Every mission is a chapter. Characters do what they do in the books. Where the books are vague, the game takes licence; where they are specific, the game obeys.
3. **Comfortable at speed.** Aiming slows time. Targets snap. Inputs buffer. Mistakes are forgiven in the player's favour, as in Celeste. The player should never feel they lost control of Vin; only that they asked for something unwise.
4. **The mists are the mood.** Night, ash, silence, blue lines. The world is beautiful because it is bleak.
5. **Vin grows.** From a flinching thief who distrusts everyone to the Lady Heir to Preservation. Mechanics track that growth through mastery and trust, not through finding power-ups.

## 4. The player character: Vin

- Small, light, fast. Barely over five feet. Her low mass is a mechanic: almost everything anchors her, and almost anything heavier than a coin can throw her.
- Base movement without pewter is deliberately ordinary: run, jump, ledge grab, wall slide, crouch. Pewter makes her superhuman. Steel and iron make her fly.
- Equipment: two obsidian daggers (no metal, cannot be Pushed away), a pouch of copper clips, glass vials in a sash, the mistcloak.
- The mistcloak is a verlet-simulated chain of grey ribbon strips that twist and curl like the mists when she moves. It is her silhouette. In disguise as Valette Renoux she wears gowns and the cloak is gone; missing it should feel like being underwater.
- Vin has health, not lives. Pewter reduces damage and regenerates health slowly while burning. Death restarts at the last checkpoint, which are generous (every room transition or every fight).

## 5. Allomancy: mechanics specification

This is the heart of the game and the first thing to prototype. Every subsection lists book behaviour, then the game rule.

### 5.1 Metal reserves and vials

- Vin has a reserve bar per metal, shown as eight thin vertical vials in the HUD, plus slots for atium beads and story metals.
- Metals burn only while active. Steel and iron burn while Pushing or Pulling. Pewter, tin, copper and bronze are toggles that burn continuously while on. Zinc and brass burn while aimed at a target. Burn rate differs per metal: pewter fastest, copper slowest, matching the books.
- Flaring multiplies effect by about 1.6 and burn rate by about 4. On gamepad, flare is trigger depth (see section 7). On keyboard it is a held modifier.
- A vial refills every basic metal to full. Vin carries a small number of vials per mission (default three) and finds more in the level and from Clubs' shop stock. The hub refills vials automatically.
- Atium is a separate consumable: beads, each worth a short burst of future-sight. Extremely rare. The book's economy applies: Vin has only a few beads in all of Act 1.
- There is no "out of all metal" fail state. Out of steel, Vin can still run, jump and stab. Out of pewter, she is fragile.

### 5.2 Metal in the world

Every metal object is a component with a mass, an anchor state, and a line-of-sight flag. Three classes:

- **Anchored** (effectively infinite mass): nails in beams, door hinges, window latches, lamp posts, gate bars, roof fittings, the bronze bars of the Fellise spikeway, Kredik Shaw's spires, metal plating. Pushing on these moves only Vin.
- **Dynamic** (rigid bodies with real mass): coins, horseshoes, dropped weapons, braziers, buckets, cart fittings, a guard's spear. Pushing shares the force by mass. A coin flies; a cart barely rocks and sends Vin sailing.
- **Carried** (metal attached to a character): breastplates, helmets, swords, bracers. Pushing acts on the character's whole body mass. Pushing a guard's breastplate shoves him back; Pulling his sword rips it from his hand if his grip check fails. This is straight from the books and makes armour a liability, which is why hazekillers carry none.

A coin resting on the ground counts as anchored for Pushes directed into the surface within an "anchor cone" of about 35 degrees from the surface normal. Outside the cone the coin skids and Vin gets only partial lift. This is Kelsier's lesson about Pushing from the centre of mass, made into a rule.

Metal inside a body cannot be Pushed or Pulled. This covers Inquisitor spikes, the Lord Ruler's bracers, Vin's own earring, and coins that have lodged in a target. The only exceptions are scripted: Vin drawing on the mists in the finale of Act 1 and the end of Act 3, and the Lord Ruler himself. Aluminum casts no line and cannot be affected.

### 5.3 Blue lines

- Visible only while burning steel or iron. They are pale translucent blue, converge at Vin's chest, and run to every metal source within range (roughly two screens).
- Thickness encodes mass: a hair for a clip, a cable for a gate. Brightness encodes distance and falls off smoothly. Lines pass through walls, drawn dimmer; Vin can Push on metal through a thin wall, as she does in the books, and physics will decide what happens when she hits the wall.
- The current target's line is drawn thicker and brighter with a small glyph at the far end. Lines to carried metal pulse gently so the player can read "that guard has armour".
- Lines are rendered on a separate layer that is excluded from the mist and darkness shaders, so they stay readable in the thickest fog.

### 5.4 Steelpush and Ironpull: the force model

Book: force along the line, equal on both ends; strength proportional to the Allomancer's weight but much larger than it; falls off with distance; a bigger anchor, a flare, or duralumin raises the zenith.

Game rule: one scalar force F is computed along the line and applied as equal and opposite impulses to Vin and the target each physics frame while the Push is held.

```
F = F0 * flare * falloff(d)
falloff(d) = clamp(1 - (d / R)^2, 0, 1)     # smooth to zero at range R, never an abrupt cutoff
a_vin    = F / m_vin
a_target = F / m_target                      # zero for anchored metal
```

Design-facing tuning values, not physics constants: "a full Push off a coin on flat ground reaches 7 tiles in 0.55 seconds", "a flared Push off an anchored lamp post reaches 11 tiles". F0 is derived from those at startup, in the manner of the GDC "Building a Better Jump" method.

Consequences the player will discover:
- Push down on a dropped coin: Vin launches. The classic Mistborn jump.
- Push sideways on a coin on the ground: it skids, Vin barely moves. Push sideways on a coin in the air: it becomes a bullet.
- Push on a guard's breastplate: he staggers back, Vin slides back a little.
- Pull on a gate: Vin flies to it. Pull on a dropped sword: it flies to her hand.
- Pull on a loaded cart: it rolls toward her and she had better move.
- Two Allomancers Push on the same anchor: the lighter one loses. Vin is always the lighter one. Push contests (Zane at Keep Hasting) are won by anchoring yourself to something heavier first.

Sustained Push: holding the button keeps applying force. Hovering at equilibrium above a coin is possible and intended, as in the books, but F falls off with height so it caps naturally. Gravity is reduced by about 30 percent near the apex of a Push arc while the button is held, giving the "hanging in the mists" feel without making the whole game floaty.

Momentum is conserved. A Push adds to existing velocity; it does not replace it. Horizontal speed persists on a neutral stick. A jump input cancels downward speed (coyote-friendly). Nothing damps velocity harshly on release; the number one complaint about existing fan prototypes was jittery range cutoffs and hard deceleration.

### 5.5 Aiming: Steelsight

Two aiming problems killed earlier fan prototypes: the Push went the wrong way, or it grabbed the wrong metal. The fix borrows Ori's Bash and adapts it for a mouse-first game with sustained pushes. (Decided 2026-10-03.)

- **Continuous highlight.** While steel or iron is available, the best candidate metal source near the aim point is highlighted at all times, before any button is pressed. "Best" is scored by distance from the cursor (mouse) or by a 40 degree cone around the stick direction (gamepad), weighted by mass so a gate beats a nail at equal distance. With no aim input, a heuristic picks: when falling, the nearest anchor below; when on the ground, the coin at your feet, else the nearest metal in the facing direction; else the last target.
- **Instant commit.** Pressing Push or Pull with a highlight fires immediately. No latency on rhythm chains: coin, click, coin, click across a rooftop line.
- **Steelsight.** Pressing with nothing highlighted slows time to about 15 percent for up to 0.25 seconds (0.4 on gamepad) while the player finds a target; the Push commits the moment one highlights, or when the window ends, or on release. Time ramps back over 0.2 seconds while the force is already acting. This is the safety net for flailing mid-air, not the default path.
- **Hold to sustain, release to stop.** Holding keeps the force on the locked target. Flare is a held modifier (Shift) on mouse and trigger depth on gamepad.
- **Retarget while holding.** Moving the cursor to another source while a Push is active switches to it without releasing. Experts chain anchors without ever letting go.
- **Target cycle.** Mouse wheel or a bumper steps through candidates near the aim point for precise picks in dense metal (a keep interior).
- **Preview.** While a target is highlighted, two arrows are drawn, scaled by the mass ratio: a long arrow on Vin and a stub on an anchored target, or a long arrow on a coin and a stub on Vin. Players learn the weight rule from the arrows without a tutorial box. A faint predicted arc for Vin's first half second is drawn during Steelsight.
- **Forgiveness.** Push inputs are buffered for 6 frames. A coin that left the ground within the last 5 frames still counts as anchored ("Push coyote time"). Pushing from a coin that is still bouncing is accepted if the coin's velocity is small. Corner correction nudges Vin around ledges she clips during a Push arc.

Steelsight costs nothing and has no cooldown. Slowing time while aiming is Vin's instinct, not a resource. The one exception is in Push contests and some boss phases where the enemy also acts in slow time.

### 5.6 Coins

- **Coin pouch:** a finite count of clips, default 30 per mission, restocked from pickups, Clubs' shop and by Pulling spent coins back. Boxings (gold) are currency, not ammunition, but can be Pushed in a pinch.
- **Flick (Coin button):** tosses a clip a short distance in the aim direction, or straight down if there is no aim input. It is a rigid body. It lands, settles, and is now an anchor.
- **Drop (Down + Coin):** drops a clip at Vin's feet without a toss. The standard pre-jump.
- **Shoot (Coin then Push while the coin is airborne):** the coin becomes a projectile. Pushed clips accelerate along the line and kill unarmoured humans in one hit, two for light armour. Armour plates deflect at shallow angles. This is the book's "Coinshot" attack and Vin's primary ranged weapon.
- **Spray (Coin + Push together):** throws five clips in a fan and Pushes them all. Expensive, loud, lethal in a crowd. The WoA Assembly fight.
- **Steel bubble (hold Push with no target while metal projectiles approach):** incoming metal (enemy coins, arrows with metal heads, thrown knives) is Pushed away in a radius. Costs steel continuously. Enemy Coinshots do the same, so coin exchanges become volleys. Wooden hazekiller weapons and obsidian ignore it.
- **Recall (hold Pull with no target):** loose coins within range fly to Vin and are re-pouched on contact. Also catches coins mid-flight.
- Coins have a lifetime pool in the world (about 60 active) and merge into small piles when they settle near each other, so the physics budget holds.

### 5.7 Pewter

Book: strength, speed, balance, durability, healing; fastest burn; collapse when it runs out after heavy use; pewter dragging.

Game rule:
- Toggle. While on: run speed 1.4x, jump height 1.3x, damage taken halved, no stagger from light hits, heavy dagger attacks, can shoulder through wooden doors and break weak boards, slow health regeneration.
- Flared: run speed 1.9x, strength to shove koloss-weight objects, damage taken quartered. The "pewter drag" mission (TFE 25) is an endurance run where you hold flare across the ash plains while managing vials.
- **Pewter crash:** if pewter runs out while flared or after more than about 40 seconds of continuous flare, Vin staggers for 2 seconds and moves at 70 percent speed for 10 seconds. (Decided 2026-10-03: no deferred "pewter debt" damage. The books make pewter a debt, but hidden delayed damage is hard to read and easy to feel cheated by. The crash alone carries the idea.)
- Pewter also raises how much force Vin can take from a Push before tumbling. Without pewter a flared Push off a big anchor sends her head over heels (an animation state, still controllable). With it she lands clean.

### 5.8 Tin

Book: all senses at once; see through the mists; hear footsteps streets away; bright light and loud sound hurt.

Game rule:
- Toggle. While on: the mist shader thins and the visible radius triples; darkness lifts; enemy footsteps and voices draw expanding rings through walls (Mark of the Ninja style); hidden metal glints; whispered dialogue becomes legible; secrets (loose boards, hidden ledges) are outlined faintly.
- Cost: an unshuttered lantern swung in Vin's face, a flashbang-like brazier burst, a bell or a gunpowder-free "crack" of a thrown pot, all stun her for a second and white out the screen if tin is on. Enemies with lanterns are therefore a soft counter to tin-on stealth. Rioting a lamplighter to drop his lamp is the counter to the counter.
- Flare: a one-off pulse that reveals everything on screen for a moment and clears a daze (Vin uses it to shake off a blow in the books).
- Spook's version in Act 3 is a savant: permanent, extreme, and the basis of his missions (section 8).

### 5.9 Copper and Bronze

- **Copper (toggle, very cheap):** a coppercloud hides Vin's Allomancy from Seekers. Inquisitors, obligator Seekers and Seeker guards detect any burning metal within a radius unless copper is on. Copper also blocks enemy Soothers and Rioters from affecting Vin. The default is copper on. The books reveal after Kredik Shaw that Inquisitors see through copperclouds anyway, and from that mission on stealth against them changes permanently.
- **Bronze (toggle):** shows Allomancer enemies as pulsing beacons through walls, labelled by Misting type after a second of listening. Vin's earring lets her hear through enemy copperclouds, which is why she can find Smokers that others cannot.

### 5.10 Zinc and Brass

Book: Riot inflames, Soothe dampens; target a person or a group; cannot affect yourself; copper immunises; extreme emotions resist.

Game rule:
- Hold the Emotion button to aim a cone at NPCs; left stick picks Soothe or Riot with an emotion wheel of four: calm or fear, anger or trust. Effects on guards: Soothe fear lowers alertness and makes them forget a sighting faster; Riot fear sends them fleeing; Riot anger makes them attack the nearest person, including each other; Soothe anger stops a fight. On crowds: disperse or rally. On animals: calm a dog.
- In dialogue scenes, Soothing and Rioting appear as conversational options with visible consequences, including bad ones. Vin's arc includes learning when not to use them.
- Copper-burning enemies and Inquisitors are immune. Kandra are immune without duralumin.
- Act 2 unlock: duralumin plus brass or zinc takes direct control of koloss and kandra (section 5.13).

### 5.11 Atium

Book: shadows of the future a second or two ahead; nothing surprises you; against another atium burner the shadows split.

Game rule:
- A bead is a consumable worth about 8 seconds. Press Atium to start burning; it ends when the bead is gone or when pressed again (unused remainder is lost, as in the books).
- While burning: every enemy shows a translucent shadow performing its next action about 1.2 seconds ahead; incoming projectiles draw their paths; Vin's dodge window becomes generous and her dagger counters auto-aim; time slows slightly (90 percent) to make reading easier.
- Against atium-burning enemies (Shan, Zane, Inquisitors, the Lord Ruler): both sets of shadows split into three or four possibilities and flicker. The fight reduces to who runs out first, exactly as the books say. Vin's trick against Zane (watching his reaction to her future and changing it) is scripted as the climax mechanic of that boss.
- Enemies that burn atium while Vin has none are terrifying by design: Vin's attacks are dodged automatically unless she uses the environment (collapsing a ceiling, Pushing a brazier) or feints (the Shan fight).
- Act 3: electrum lets Vin split her own shadow, nullifying enemy atium.

### 5.12 Gold, Malatium, Electrum, Aluminum

- **Gold:** a single scripted scene (TFE 27). Vin sees her other self. Not a mechanic.
- **Malatium (the Eleventh Metal):** finale of Act 1. Shows the past selves of the Lord Ruler. A cutscene reveal and a boss-phase mechanic for reading his weakness.
- **Electrum:** Act 3. Toggle; Vin's own future splits, so enemy atium cannot read her. Also gives a faint self-shadow that doubles as a subtle "where will I land" preview.
- **Aluminum:** story only. The Inquisitors force it on Vin in Kredik Shaw and her HUD empties.

### 5.13 Duralumin (Act 2 onward)

Book: detonates every metal currently burning for one enormous burst, emptying them.

Game rule: hold Duralumin and press a metal's activation. Effects:
- Steel or Iron: a city-crossing Push or Pull. Vin burns pewter automatically to survive it. Used as a scripted traversal beat (crossing the siege lines) and as a desperate finisher that empties the steel bar.
- Pewter: a single strike that kills anything short of a boss, then a crash.
- Brass or Zinc: seizes control of a koloss or kandra in the cone. Controlled koloss follow Vin and fight for her; this is the WoA 54 koloss army mechanic in miniature. The control persists after the metal is spent.
- Tin: reveals the whole level map for the mission but blinds and deafens Vin for 10 seconds. Mostly a trap for the curious.
- Bronze: pierces every coppercloud on the level for a moment.
- Atium: 3 seconds of seeing 5 seconds ahead. Act 3 only.

### 5.14 Drawing on the mists (scripted)

Twice in the trilogy Vin's earring is torn out and she channels Preservation: the Lord Ruler fight and the Kredik Shaw ascension. Both are scripted sequences with their own rules: unlimited reserves, Pushes that affect metal inside bodies, and the mists pouring into her. They are the only places the simulation's rules are suspended, and the game makes that obvious.

## 6. Combat and stealth

### 6.1 Combat philosophy

Lethal by default (decided 2026-10-03). Coins and daggers kill; there is no knockout state. The non-lethal path is stealth: Soothing, rooftops, timing.

Vin is fragile and lethal. Without pewter three hits from a guard kill her. Her advantage is mobility and information. Good play looks like the books: arrive from above, kill before the enemy understands, leave by the roof. Standing toe to toe with a hazekiller squad is a mistake you can survive only with pewter and skill.

### 6.2 Vin's melee

- Daggers: a three-hit light combo, a dash-stab, a downward plunge from the air, a backstab that kills unaware humans instantly.
- Pewter heavy: a slower strike that staggers or kills armoured enemies and breaks wooden shields in two hits.
- Disarm: Pull on an enemy's metal weapon. Success depends on the enemy type: guards lose spears, hazekillers have nothing to lose, Thugs hold on.
- Shove: Push on an enemy's metal armour to open distance or throw him off a roof. Environmental kills are encouraged.
- Dodge: a short roll with invulnerability frames. Atium makes it generous.

### 6.3 Enemy roster

| Enemy | Where | Behaviour | Allomantic interaction |
|---|---|---|---|
| Skaa thug | Camon's lair, slums | Weak, unarmoured, cudgels | Coins kill in one; Soothe or Riot trivially |
| Keep guard | Keeps, Garrison | Spear, breastplate, lantern on some | Armour is Pushable: shove, throw, disarm. Lantern bearers stun tin |
| Garrison soldier | Garrison, streets, executions | Formations, shields and spears | Metal shields deflect coins; Push the shield to open the line |
| Archer | Walls, towers | Metal-headed arrows | Steel bubble deflects; Pull an arrow back to throw it |
| Hazekiller | Noble keeps, Kredik Shaw, Cett's men | Trained anti-Allomancer squads; wooden shields, staves, no metal; attack in groups of 4 to 8 | Immune to Push/Pull. Daggers and pewter only. Coins bounce off shields; Riot their fear or Soothe their resolve |
| Obligator / Seeker | Cantons, balls, Kredik Shaw | Detects burning metal without copper; raises alarms | Keep copper on or kill quietly |
| Misting: Thug | Noble retinues | Tanky, fast, pewter | Immune to shove stagger; outlast or environment kill |
| Misting: Coinshot | Noble retinues, assassins | Shoots coins from range, Pushes yours back | Volleys; close the distance or Push his own coins back |
| Misting: Lurcher | Noble retinues | Pulls your coins into a shield; Pulls you off ledges | Ranged attacks fail; fight in melee or Push off his own shield |
| Misting: Tineye | Patrols | Sees through mist, hears you | Lantern flash counter; Rioting works |
| Misting: Smoker | Noble retinues | Hides the retinue's Allomancers from bronze | Vin's earring hears through him; kill him first |
| Misting: Soother / Rioter | Balls, Soothing stations | Affects Vin's suspicion and crowd states | Copper blocks them |
| Mistwraith | Outside the walls, night | Boneless mass, slow, harmless unless cornered | Atmosphere; Pull its collected bones |
| Steel Inquisitor | Hunters, bosses | Pewter, steel, iron, atium, pierce copper; obsidian axes; sees by blue lines | Spikes cannot be Pushed. Kill by pulling the linchpin spike from behind (a scripted finisher), decapitation (boss), or escape. In Act 1 you mostly run |
| Koloss | Acts 2 and 3 | Size classes 5 to 12 ft; huge swords; rage states | Four spikes protrude but cannot be Pushed by Vin. Kill with coins to the face at small sizes, pewter and swords at medium, control with duralumin + brass at any size |
| Kandra | Story | Shapeshifting infiltrators | Unkillable; immune to emotion without duralumin. Mostly cutscene; TenSoon is an ally |
| Mistborn (Shan, Zane) | Bosses | Full kit, atium | Mirror duels; see section 10 |
| The Lord Ruler | Act 1 finale | Compounding immortal | Scripted phases; see section 10 |

### 6.4 Stealth model

- Light and dark: Vin is hidden in shadow, visible in lantern light. The mists themselves are a soft cover that tin-burning enemies pierce.
- Noise: landing hard, Pushing on heavy metal, and fights make noise rings. Tin shows them. Pewter landings are quieter.
- Suspicion: guards have a three-stage state (idle, suspicious, alerted) shown by an icon. Soothing lowers it. An alerted keep summons hazekillers after a timer. Alarms in Act 1 are bells (metal, Pushable to silence them, which is a nice trick).
- Seekers add a second detection channel: burning any metal without copper within their radius raises suspicion even from hiding.
- Rooftop advantage: most guards do not look up unless alerted. This is deliberately generous because it is how the books describe noble security.
- Social stealth (the balls): no combat, no mistcloak. Suspicion is driven by Valette's behaviour: standing too long alone, approaching restricted areas, burning metal near Seekers. Conversations are the mission objectives. Soothing is available but noticed by Seekers. Shan Elariel is a persistent threat who tests Vin.
## 7. Controls

Design rules: one verb per button; identical hold, tap and release semantics for Push and Pull; Push and Pull on the opposite hand from jump so they chain; every binding remappable.

**Decided 2026-10-03: keyboard and mouse is the primary input for the prototype and slice.** Mouse aim is the most precise way to pick a metal source, and the slice must prove aiming first. Gamepad support follows with full parity before any wider release; the trigger-depth idea below is kept as the gamepad design.

### 7.1 Keyboard and mouse (primary)


| Input | Action |
|---|---|
| WASD | Move; S + coin drops |
| Mouse | Aim |
| Space | Jump |
| Left mouse | Steelpush (hold); Shift held = flare |
| Right mouse | Ironpull (hold); Shift held = flare |
| Mouse wheel or Q | Target cycle |
| E | Coin flick; E + LMB spray |
| F | Dagger; hold for heavy |
| Ctrl or C | Dodge |
| 1, 2, 3, 4 | Toggle pewter, tin, copper, bronze |
| R | Emotion (hold), wheel on mouse direction |
| Tab | Atium (hold to confirm) |
| V | Duralumin |
| Esc / J | Pause / Journal |

Mouse aim is naturally precise, so Steelsight's slow window is 0.25 seconds by default for mouse users (adjustable); gamepad users get 0.4 seconds.

### 7.2 Gamepad (parity target)

| Input | Action |
|---|---|
| Left stick | Move; emotion wheel while Emotion is held |
| Right stick | Aim (Steelsight, coins, emotions). Neutral uses the heuristic target |
| A (bottom face) | Jump; cancels downward speed mid-Push |
| X (left face) | Dagger attack; hold for pewter heavy when pewter is on |
| B (right face) | Dodge roll |
| Y (top face) | Interact; context: pull spike (finisher), open, talk |
| RT (right trigger) | Steelpush. Depth = burn intensity; full pull = flare |
| LT (left trigger) | Ironpull. Depth = burn intensity; full pull = flare |
| RB | Coin: tap to flick in aim direction; down + RB drops at feet; RB + RT spray; hold RB for a handful |
| LB | Target cycle while Steelsight is active; otherwise atium (hold to confirm, prevents waste) |
| D-pad up | Toggle pewter |
| D-pad down | Toggle tin |
| D-pad left | Toggle copper |
| D-pad right | Toggle bronze |
| Left stick click | Emotion (hold): Soothe or Riot via wheel |
| Right stick click | Duralumin (Act 2 onward; hold then press a metal) |
| Start / Select | Pause / Journal and codex |

Triggers as burn intensity is the most important gamepad control idea in this document. Steelpushing in the books is analogue: a light touch to nudge a coin, a flare to launch across the street. Analogue triggers give that for free, and feathering the trigger while hovering above a coin feels exactly like the book describes.

### 7.3 Accessibility and comfort

- Every timing in section 5.5 is exposed in settings: Steelsight slow factor and duration, buffer frames, aim cone width, aim assist strength, auto-target on or off.
- An "assist" preset slows all time by 20 percent and makes Vin take half damage, in the Celeste tradition.
- Toggle vs hold for Push and Pull, and a "sticky target" mode that keeps the last target until changed.
- Line visibility options: always show blue lines (not only while burning), high-contrast lines, line thickness multiplier.
- Full remapping; colour-blind palettes for lines and suspicion icons; screen-shake and flash intensity sliders (the tin whiteout especially).

## 8. Playable characters beyond Vin

The question was left open by the brief. The recommendation is: **Vin is the protagonist and plays roughly 80 percent of the game. Three other characters are playable in specific missions where the books leave Vin absent and the material is too good to lose. Everyone else is a cutscene character or a call-in partner.** Trine-style free swapping is rejected because it conflicts with the fixed plot and with Vin's primacy.

Implementation note: every Allomancer is the same controller with a metal mask. Ham is Vin with only pewter, Spook is Vin with only tin. That makes extra playable Mistings cheap in code and expensive only in art and level design.

| Character | Playable where | Kit | Why |
|---|---|---|---|
| **Kelsier** | Act 1 prologue (Tresting plantation), Keep Venture heist (TFE 5), the house-war night (TFE 19), the fountain square (TFE 34) | Full Mistborn, more mass and force than Vin, no fear states, atium in the square | He is the master; playing him before Vin learns is the tutorial by example. His death played rather than watched is the emotional core of Act 1 |
| **Spook** | Act 3 Urteau arc, three to four missions | Tin savant: permanent extreme senses, blindfold by day, no steel or iron until the pewter sliver; later pewter | The books' second protagonist of book 3; a stealth-and-senses game with no flight is a strong contrast to Vin |
| **Sazed** | The Steel Gate stand (WoA 52), the Well descent against Marsh (WoA 58), optionally the Conventical of Seran (WoA 12) as exploration | Feruchemy: tap or store weight, strength, speed, health from finite metalminds with a storing-and-tapping economy | Weight storing interacts with the Push system (a heavy Sazed is unmovable, a light one falls safely), which makes him a puzzle-platformer variant of the core system |
| Elend | Optional: the koloss camp (WoA 42) as a non-Allomancer stealth-talk mission; the final charge (HoA 81) as a Mistborn with raw power and no finesse | None, then unrefined Mistborn | Nice to have; cuttable |
| Ham, Breeze | Call-in partners during the siege: Ham holds a gate, Breeze Soothes a crowd | Not controlled | Portrait of Ruin partner model; cheap |
| Marsh, TenSoon | Cutscenes only | | TenSoon's escape from the Homeland is tempting but out of scope |

If scope forces a cut, the order of removal is: Elend, Sazed's Conventical mission, Sazed entirely, Spook reduced to two missions. Kelsier stays.

## 9. Acts, hubs and the shape of the story

The game follows the trilogy's three books as three acts. Each act has a hub that reflects that book's world state and a mission chain that follows the chapters. In-world time passes as it does in the books: about a year for book 1, a few months for book 2, about a year for book 3, with roughly a year between each.

### 9.1 Act 1: The Final Empire

**Hub: Luthadel at night, 1022 FE.** The city of a thousand spires under ash. Districts from east to west: the skaa slums and Camon's lair, the Twists, Clubs' shop (home base), the canals and the River Channerel, the noble keeps (Venture, Elariel, Hasting, Lekal, Tekiel), the fountain square, the Cantons of the Steel Ministry, the Garrison by the Steel Gate, and Kredik Shaw in the centre. The city wall bounds the map, and the Fellise spikeway runs off one edge as a corridor to the Renoux mansion. Hub states advance with the story: ash and quiet at first; house-war fires and corpses mid-act; the Garrison marching out; the fountain square red after the executions; the city rising after Kelsier's death.

Hub content: Kelsier's training targets (timed coin-jump courses on the rooftops), informant errands for Dockson, Alendi logbook pages hidden in high places (the codex), coin caches, a few optional encounters (a patrol to ambush, a Seeker to evade). Nothing in the hub is required.

### 9.2 Act 2: The Well of Ascension

**Hub: Luthadel besieged, 1024 FE.** The same city in its new state: Straff's army of 50,000 camped to the north, Cett's to the west, later Jastes' koloss to the east. The keeps are Elend's palace (Venture), Cett's fortress (Hasting), the Assembly Hall. Refugee warehouses. The mist spirit watches from rooftops. Zane appears on spires as a recurring optional encounter: duels you can seek out. The wall is the hub's edge, and the siege camps are mission spaces.

### 9.3 Act 3: The Hero of Ages

**Two hubs.** Elend's army camp outside Fadrex City and the red rock shelves of Fadrex itself are Vin's hub for the middle of the act; the ash falls thicker every mission, the sun is a dim red disc, and the mists come during the day. Spook's Urteau (drained canals as streets, wooden buildings, the Citizen's patrols) is the second hub for his arc. Luthadel returns only for the finale, buried in ash and crowned with Kredik Shaw's spires in the rain.

### 9.4 Chapters Vin does not see

A substantial part of books 2 and 3 happens away from Vin. The game handles this with three devices, chosen per scene: a playable mission for another character (section 8), an in-engine dialogue scene (Sazed and Tindwyl in the library, TenSoon's trial, Elend's politics), or a codex entry unlocked at the right moment (the epigraphs: Alendi's logbook in Act 1, Kwaan's steel plate in Act 2, Sazed's notes in Act 3). The codex is in-fiction: it is Vin's journal, and the epigraph texts appear in it exactly as the books present them.

## 10. Mission list

Each mission names its chapters, its type, and its Allomantic focus. Boss encounters are described in 10.4. This list is the content plan for Act 1 in full and a sketch for Acts 2 and 3. Mission counts: Act 1 about 15, Act 2 about 12, Act 3 about 13.

### 10.1 Act 1: The Final Empire

| # | Mission | Chapters | Playable | Type | Focus |
|---|---|---|---|---|---|
| 1 | The Survivor | Prologue | Kelsier | Assault and escape | Full kit shown at mastery: coins, Pushes, pewter. The player sees what Vin will become |
| 2 | Luck | 1 to 3 | Vin (no Allomancy knowledge) | Stealth, dialogue | Vin's "Luck" is unexplained Soothing; the Canton of Finance scam; Camon's beating; Kelsier arrives |
| 3 | The Crew | 4 | Vin | Dialogue | Camon's lair meeting; the plan. Hub introduced afterwards as a short walk to Clubs' shop |
| 4 | Eight Metals | 7 | Vin | Tutorial traversal | Kelsier gives Vin the mistcloak and teaches the eight metals on the rooftops; ends on the city wall. The Steelsight tutorial |
| 5 | Off the Wall | 8 | Vin | Traversal | Kelsier pushes Vin off the wall; braking with a coin; the road to Fellise with a mistwraith following; meet Renoux |
| 6 | Keep Venture (Kelsier) | 5, told as a flashback by Dockson | Kelsier | Infiltration, hazekiller fight, escape | The atium safe heist. Introduces hazekillers (no metal) and keep guards (armour). Scripted escape through stained glass |
| 7 | Valette | 9 to 12 | Vin | Sparring, social stealth | Cat-and-mouse with Kelsier in the Fellise gardens (combat tutorial); the first ball at Keep Venture; meeting Elend on the balcony |
| 8 | The Spikeway | 13 | Vin | Traversal | Tailing Kelsier along the bronze bars from Fellise into Luthadel at night; atium taught |
| 9 | Kredik Shaw | 14 | Vin | Infiltration, boss escape | Fighting guards with Kelsier; the hut within the chamber; Inquisitor Bendal; atium; the axe wound; the chase through the city (section 10.4) |
| 10 | The House War | 18, 19, 23 | Vin and Kelsier | Social stealth (Elariel ball), stealth (Kelsier plants a corpse, meets Hoid), tower climb | Shan Elariel introduced as a social threat; Kelsier's night mission is the stealth masterclass |
| 11 | Pewter Drag | 24 to 25 | Vin | Endurance traversal | A day's run across the ash plains with Kelsier; vial management; the destroyed army |
| 12 | A Sky of Blood | 26 to 29 | Vin | Cutscene-heavy, hub events | Executions; gold; the Soothing stations found with Marsh's help (a short Seeker mission); the logbook's end |
| 13 | The Last Ball | 30 | Vin | Social stealth into assault, boss | Kliss's warning; through the window; two Thugs, two Coinshots, two Mistborn; the Shan duel |
| 14 | The Square | 32 to 34 | Vin then Kelsier | Stealth, boss, scripted death | Spook teaches tin on the rooftops over Keep Hasting; Kelsier's return; Kelsier vs Bendal played in full; the Lord Ruler arrives and Kelsier dies |
| 15 | The Hill of a Thousand Spires | 35 to 38 | Vin | Infiltration, boss, prison break, final boss | Turning Goradel; Kar; capture and aluminum; the dungeon with Sazed; the throne room; the Lord Ruler (section 10.4) |
| Epilogue | | Epilogue | Vin | Traversal | Dropping through Elend's skylight |

### 10.2 Act 2: The Well of Ascension (sketch)

| # | Mission | Chapters | Playable | Type |
|---|---|---|---|---|
| 1 | Eight Allomancers | 1 to 2 | Vin | Opening ambush; the Watcher helps; last atium spent |
| 2 | The Watcher | 5 to 8 | Vin | Rooftop chase of Zane; duralumin discovered by accident |
| 3 | Breeze's Run | 11 | Vin | Escort under archer fire from the wall; first deliberate duralumin Push |
| 4 | The Conventical | 12 | Sazed | Exploration, no combat, dread; Kwaan's plate (optional, cuttable) |
| 5 | Envoy | 17 | Vin | Zane Push contest at Keep Hasting |
| 6 | The Feint | 25 | Vin | Wall defence against Straff's probe |
| 7 | The Assembly | 38 | Vin | Assassins among civilians; coin spray with collateral rules |
| 8 | Knives | 43 | Vin with Zane | Keep Hasting assault; sparing Cett is a choice the game forces as in the book |
| 9 | Two Shadows | 47 | Vin | Zane boss (section 10.4) |
| 10 | The Gates | 52 to 53 | Sazed, then Vin | Steel Gate stand; Vin's horseshoe flight back |
| 11 | Lady Heir | 54 to 55 | Vin | Burning Luthadel; pewter runs dry; duralumin-Soothing the koloss; Straff |
| 12 | The Well | 57 to 59 | Vin | Descent beneath Kredik Shaw; Marsh vs Sazed; the power released |

### 10.3 Act 3: The Hero of Ages (sketch)

| # | Mission | Chapters | Playable | Type |
|---|---|---|---|---|
| 1 | Vetitan | 1 to 5 | Vin | Koloss battle; controlling koloss; the plated Inquisitor; the first cache |
| 2 | Streets of Water | 14 to 19 | Spook | Urteau introduction; tin-savant stealth; the burning of nobles |
| 3 | Fadrex | 25 to 27 | Vin | Infiltration of the rock-shelf city; Slowswift; Hoid |
| 4 | Survivor of the Flames | 23 to 26, 35 to 41 | Spook | Stabbed, left in a burning house; "Kelsier" gives him pewter; the rescue from the fire |
| 5 | Keep Orielle | 30 to 32 | Vin | Ball; Yomen; exit by Steelpush with Elend |
| 6 | The Siege Camp | 36 to 37 | Vin | Cavalry raid; tent spikes as missiles; siege engines |
| 7 | The Cache | 43 to 45 | Vin | Social stealth into heist; sealed in; Ruin as Reen |
| 8 | Streets of Fire | 46 to 58 | Spook | The uprising; pulling Quellion's spike and his own; flooding the canals |
| 9 | Captive | 54 to 65 | Vin | Staged escape; Marsh in Yomen's hall; the earring Pushed into his forehead |
| 10 | Mistfallen | 67 to 74 | Vin | Earthquake; the mists Snap Allomancers; Yomen's atium |
| 11 | The Homeland | 66 to 78 | Sazed (cuttable) | Riding TenSoon; the Trust; the Resolution |
| 12 | Thirteen | 72 to 73 | Vin | Inquisitor gauntlet on Kredik Shaw's spires in the rain; the ascension (section 10.4) |
| 13 | Hathsin | 80 to 82 | Elend (optional), cutscene | The final battle; Sazed's ascension; green fields |

### 10.4 Boss encounters

- **Inquisitor Bendal, Kredik Shaw (Act 1, mission 9).** Unwinnable by design. Phase 1: Vin and Kelsier fight guards; the Soothing in the hall drags Vin's suspicion meter down (a reversed effect). Phase 2: Bendal appears; he Pushes Vin's coins back, cannot be shoved, and his axe hits remove most of her health. Atium shows the way out: the shadows reveal gaps in his attacks so Vin can take the logbook and run. Phase 3: the chase across Luthadel, Bendal coin-jumping behind her, until she collapses at Sazed's feet. The lesson is "you do not fight Inquisitors yet".
- **Shan Elariel, Keep Venture (Act 1, mission 13).** A mirror duel. Shan burns atium; Vin has one bead. While both burn, shadows split and the fight is honest. When Vin's bead runs low she must feign it: the game lets her stop burning early and the fight's final beat scripts the book's trick, a feint that Shan reads as weakness.
- **Bendal again, the fountain square (Act 1, mission 14), played as Kelsier.** The full fight: Pushing a soldier as a projectile, spinning metal bars to deflect arrows, then pinning the Inquisitor's head spikes into a cart and beheading him with his own axe. Then the Lord Ruler walks in and the player loses, on purpose.
- **The Lord Ruler, the throne room (Act 1, mission 15).** Three phases. Phase 1 through the stained glass with Marsh killing the other Inquisitors around you; the Lord Ruler Pushes everything in the room including the player, and all metal is a hazard. Phase 2: malatium shows his past selves; the player learns to read the shadow that is not him. Phase 3: the earring is torn out and Vin draws on the mists: unlimited steel, Pushes that work on metal in his body, the bracers ripped free, and the spear.
- **Zane, the mists (Act 2, mission 9).** Both burn atium; both shadows split. TenSoon's intervention is scripted. The final mechanic is Vin's: for a few seconds the game shows Zane's reaction to her intended attack before she commits, and she must change the attack to one he did not foresee. One clean hit ends it.
- **Marsh, Yomen's hall (Act 3, mission 9).** The books do not describe this fight in detail; the game takes licence. Marsh has twenty-two spikes, atium and gold healing. Her win condition is to Push her own earring (metal she owns) into his forehead as a scripted finisher after draining his atium.
- **Thirteen Inquisitors, Kredik Shaw (Act 3, mission 12).** A gauntlet on the spires in the rain. The first phase is survivable only by movement: the spires are anchors, the Inquisitors are not. The second phase is scripted: Marsh breaks Vin's limbs, rips the earring out, and the mists pour in. The player then has a short, cathartic section of godlike Allomancy: Pushing spikes out of Inquisitors, flattening the palace in one Push.

## 11. Progression without power-ups

Vin has her whole kit by mission 4 of Act 1. The game is still a progression game, in these ways:

- **Mastery by teaching.** Each basic metal gets a formal lesson from a crew member, as in the books: Kelsier for steel and iron, Ham for pewter, Spook for tin, Breeze for brass and zinc, Marsh for bronze, Clubs for copper. The lesson unlocks the HUD element and the formal technique list. Before the lesson the metal still works if the player finds it, because Vin's instinct is canon ("Luck").
- **Technique challenges.** Kelsier's rooftop courses in the hub teach specific moves: the braking coin, the horizontal shot, the hover, the Pull swing, the anchor behind you. Completing them unlocks nothing but a record; the reward is the skill.
- **New metals by story.** Atium (Act 1, mission 8), gold and malatium (story), duralumin (Act 2, mission 2), electrum (Act 3). These are genuine new verbs and arrive where the books put them.
- **Economy.** Vials and coins per mission are the resource layer. Clubs' shop stock grows as the crew's funds grow, so later missions start with more.
- **Trust.** A simple hidden stat driven by dialogue choices with the crew; it affects which optional scenes play and some lines, never success. It exists to let Vin's arc of learning to trust be felt in play.
- **The codex.** Logbook pages, Kwaan's plate fragments and Sazed's notes are collectibles that reward exploration of high places.
## 12. Art direction

### 12.1 Style

**High-resolution pixel art with dynamic 2D lighting**, in the lineage of Dead Cells, Blasphemous and Katana Zero. Internal resolution 640 by 360, integer scaled. Reasons: a small team can produce a large city in pixel art; the style tolerates reuse of tilesets; normal-mapped sprites let lanterns, limelights and the red sun light the scene convincingly; and the mists, ash and blue lines are shader effects that sit naturally on top of pixel art. Hand-painted 2D (Ori style) was considered and rejected on cost: a trilogy's worth of locations is not achievable at that fidelity without a large art team.

Character sprites are tall enough to read faces and the mistcloak: Vin about 48 pixels tall, koloss up to 120.

### 12.2 Palette and light

The books give the palette directly and the game obeys it.

- **Night (most of the game):** near-black blues and greys. The mists are faintly luminescent, so the night is never pitch black: a soft grey-blue glow with no visible light source. Lanterns are warm orange points; limelights outside the keeps throw hard white light through stained glass, casting cascades of colour onto the ash. Blue lines are the brightest cool element on screen.
- **Day:** a crimson sun behind haze, light "crimson or golden", a brown-and-black world. Ash drifts are black, not grey. Every building has a black ash gradient from the top down, "like paint running down a canvas". Plants are brown and yellow-brown. There is no green anywhere until the final cutscene, and the game should make players notice its absence.
- **Interiors:** keeps are the only places with saturated colour, and only through glass. Keep Venture's hall is a cathedral of rectangular stained glass windows lit from outside; Keep Elariel's colour comes from rose-window skylights; Keep Hasting's seven towers are wrapped in curling glass. Kredik Shaw's throne room has one cylindrical wall of glass with no picture at all, colours melted into mist-like trails. Vin crashes through it at dawn.
- **Act 3:** the sun dims further, ash falls constantly, lava glows on the horizon, and the mists appear by day. The final scene after the Catacendre is green grass, a yellow sun and a blue sky, and it should look like a different game.
- **Black mist** belongs to Ruin alone, around the Well and around Reen's apparition. The mists are never red.

### 12.3 The mists

The mists are the most important visual effect and get their own budget. Requirements from the books: they fade into existence after sunset rather than rolling in; they move lazily and pool on floors; they will not enter buildings and dissipate at doorways; they swirl toward an Allomancer who is burning metal and shy away from anyone bearing a Hemalurgic spike; tin thins them for the viewer. Implementation: two or three parallax noise layers with a flow field, plus a particle layer near the camera. The flow field has attractors on burning Allomancers and repellers on Inquisitors and koloss, so an Inquisitor announces itself by the hole it leaves in the fog. Steelsight tints the mists slightly bluer and slows their motion with the time scale.

### 12.4 Characters

Follow the books' descriptions in `docs/research/world-and-visuals.md`. Highlights that matter for silhouettes:
- Vin: tiny, short black hair in Act 1, the mistcloak's charcoal tassels fanning on every jump. Valette in gowns with the cloak gone.
- Kelsier: tall, blond, always smiling, scarred forearms visible when the cloak flares.
- Inquisitors: a head taller than anyone, bald, dark robes, two spikes out the back of the skull, obsidian axes. They are drawn so the spikes catch light.
- Koloss: blue, red-eyed, skin either sagging (small) or torn (large), swords their own height.
- Obligators: grey robes and eye tattoos of increasing complexity.
- Sazed: tall, bald, V-pattern robes, metal on every forearm and ear.
- The Lord Ruler: black and white, a trailing coat, bracers piercing his upper arms.

### 12.5 HUD

Minimal and diegetic where possible. Eight thin vials along the bottom left show reserves; atium beads beside them; a coin count; health as a thin bar that fades when full. The suspicion icon floats over guards. Steelsight draws its arrows and arc in the world, not in the HUD. Pewter and tin toggles are shown as a faint warm or cool tint at the screen edge rather than as icons.

## 13. Audio

- **Ambience is the lead instrument.** Luthadel at night is quiet: dripping condensation, distant forges, the mists distorting sound, ash landing on tile. Tin raises the ambient mix and brings in footsteps and voices through walls.
- **Allomancy sounds.** Steel and iron: a low tonal hum while lines are visible, rising in pitch with trigger depth; a soft "pluck" when a target locks; a bass thump on launch. Coins: a bright ring on landing. Pewter: a heartbeat under the mix. Atium: the world's sound thins and gains a reverb tail. Steelsight drops the mix's pitch with the time scale.
- **Music.** An original score; the books describe almost no music, so there is no canon to honour except the string orchestras at balls. Sparse strings and low brass for the empire; a solo motif for Vin that grows from a few notes in Act 1 to the full theme at the Well; the Survivor's motif reused for the Church of the Survivor and, bitterly, for Ruin's false Kelsier in Act 3. Balls are the only place with diegetic music, played by an orchestra on a platform.
- **Voice.** Partial voice acting at most: grunts, efforts and short barks for everyone, full lines for key scenes if budget allows. Dialogue is primarily text.

## 14. Technical approach (Godot 4.7)

- **Project setup.** Decided 2026-10-03: keep the Forward Plus renderer (2D HDR and glow for limelights and blue lines; desktop-only target). Remove the Jolt 3D physics setting since nothing is 3D. Set a 640 by 360 base viewport with integer scaling, pixel snap on, and 2D physics interpolation on so low time scales do not stutter.
- **Bodies.** Vin and all characters are `CharacterBody2D`. Coins and dynamic props are `RigidBody2D`. Anchored metal is `StaticBody2D` or tile metadata. Never switch Vin between body types mid-flight. Vin keeps an external velocity term that Pushes add to and that decays through `move_toward`, blended with input velocity in `_physics_process`.
- **Metal component.** A `MetalSource` node with mass, anchored flag, "inside body" flag, owner reference, and a function returning the current line thickness. All metal registers with a spatial grid so the line query is cheap.
- **Push and Pull.** One force per active target per frame. Apply `apply_central_impulse(-F * dt)` on dynamic targets and `+F * dt / m_vin` to Vin's external velocity. Anchored and inside-body targets receive nothing. The anchor cone test on resting coins uses the contact normal from `get_colliding_bodies` or a short downward raycast.
- **Steelsight.** Scale `Engine.time_scale` and `AudioServer.playback_speed_scale` together; HUD and aim cursor run with `process_mode = ALWAYS`; ramp back over 0.2 seconds. A single `TimeController` autoload owns this so boss fights can override it.
- **Lines.** A single `Node2D` with `_draw` per frame, drawing antialiased lines with width from mass and alpha from distance, on a `CanvasLayer` above the mist shader and below the HUD.
- **Mistcloak.** A verlet chain per tassel group (about 12 chains of 6 points), driven by Vin's velocity and a wind sampler from the mist flow field. Rendered as a `Line2D` strip with a tassel texture.
- **Mists.** A full-screen `ColorRect` shader sampling two scrolling noise textures and a flow-field texture updated from attractor and repeller positions each frame. Interiors mask the shader through a `Light2D`-style occlusion mask or per-room polygons.
- **Enemies.** A shared `Allomancer` controller with a metal mask, so Mistings and Mistborn enemies and secondary playable characters reuse Vin's code. Behaviour trees or simple state machines per archetype.
- **Levels.** TileMap layers for geometry; hand-placed metal props; a `Room` scene convention for checkpoints and mist masking. The hub streams districts as separate scenes.
- **Dialogue and cutscenes.** A data-driven dialogue system (a JSON or resource format) and an `AnimationPlayer`-driven cutscene convention. Codex entries are resources.
- **Save.** Story flags, hub state, codex, settings. No mid-mission saves beyond checkpoints.

## 15. Scope, milestones and the first prototype

### 15.1 What to build first

**Committed scope as of 2026-10-03: Milestones 0 and 1 only.** The Allomancy prototype and a vertical slice are the deliverable; whether Act 1 is built to completion, and whether Acts 2 and 3 follow, is decided after the slice is played. Everything in this document beyond the slice is a plan, not a commitment.

The Allomancy prototype decides whether this game is worth making. Nothing else matters until it is fun.

**Milestone 0, Allomancy grey box (4 to 6 weeks).** One grey-box rooftop scene with anchored metal, coins and a few armoured dummies. Vin's full movement set, steel and iron with Steelsight, coins (flick, drop, shoot, recall), pewter toggle, blue lines, the mistcloak chain, the force model and all the forgiveness rules of section 5.5. Exit criterion: a tester who has never seen the game can cross the scene by coin-jumping within ten minutes and wants to keep doing it. Everything in section 5.4 and 5.5 is tunable live from a debug panel.

**Milestone 1, vertical slice (3 to 4 months).** Mission 4 (Eight Metals) and mission 9 (Kredik Shaw) built to final quality: art, lighting, mists, enemies (guards, hazekillers, an Inquisitor chase), tin and copper stealth, one dialogue scene, the HUD. This slice is the thing to show people.

**Milestone 2 (contingent on the slice), Act 1 content complete (further 9 to 12 months for a two- or three-person team).** All fifteen Act 1 missions, the Luthadel hub with its state changes, the Kelsier missions, the bosses, codex, save system.

**Milestone 3 (contingent), Act 1 polish and release.** Tuning, accessibility, music, localisation if any.

**Acts 2 and 3** follow as separate projects on the same systems. Their new systems are, in order of cost: koloss (new enemy class with size scaling and control), duralumin, the siege hub state, Sazed's Feruchemy, Spook's savant mode, electrum, the ascension sequences.

### 15.2 Team shape

The design assumes a very small team: one programmer-designer, one pixel artist, part-time audio. Where a choice in this document trades fidelity for cost, that is why. The pixel-art style, the shared Allomancer controller, the reuse of the Luthadel hub across two acts and the "cuttable" marks on secondary characters all serve that assumption.

### 15.3 Risks

- **Feel.** Physics-driven traversal is unforgiving to get right; every prior fan prototype failed here. Mitigation: Milestone 0 is only this, with live tuning and outside testers.
- **Scope.** Three books is a lot of content. Mitigation: ship Act 1 as a complete game; keep Acts 2 and 3 as sketches until Act 1 proves the systems.
- **Intellectual property.** Dragonsteel permits non-commercial fan works and forbids crowdfunding; fan video games are not explicitly addressed; Sanderson is actively negotiating a licensed AAA Mistborn game, which raises the chance that a visible fan game draws a takedown. Mitigation: keep the project free with no donations, label it clearly as an unofficial fan work, do not use "Mistborn" in a studio or storefront name, and design the systems so the game could be reskinned as original IP if ever needed. If the goal is ever commercial, contact Dragonsteel's licensing channel before building further. Section 15.4 covers the name.
- **Sequence breaking.** Pushes let players reach places designers did not plan. Mitigation: treat it as a feature in the hub, and gate missions by story triggers rather than geometry.
- **Non-Vin chapters.** Books 2 and 3 are full of chapters Vin does not see. Mitigation: the three-device approach in section 9.4; accept that some material becomes codex text.

### 15.4 Naming

"MistbornSide" is the repository name and a fine working title. For a public release the title should avoid the trademark as its lead word. Candidates drawn from the books: "Ash and Steel", "Children of a Bleeding Sun" (Part Three's title), "Dancers in a Sea of Mist" (Part Four's title), "Survivor of Hathsin". Any of these with a subtitle such as "an unofficial Mistborn fan game" is the recommended pattern.

## 16. Open questions for the owner

These are decisions that change the work and that the brief left open.

1. **Secondary playable characters.** Decided 2026-10-03: as recommended in section 8. Kelsier in four Act 1 missions, Spook for the Urteau arc, Sazed if budget allows, Elend optional, no free swapping.
2. **Lethality and tone.** Decided 2026-10-03: lethal by default; the only non-lethal path is not being seen (Soothing, rooftops, timing). No knockout mechanic, no kill rating.
3. **Art style.** High-resolution pixel art is recommended. If you have a strong preference for hand-painted 2D or a different resolution, it changes the art pipeline from the start.
4. **Release model.** Decided 2026-10-03: vertical slice first; Act 1 standalone versus full trilogy is deferred until the slice exists.
5. **Dialogue depth.** Decided 2026-10-03: light. Scenes play as written with a few Soothe/Riot choice points that have visible consequences; the balls are social stealth with conversation objectives, not a persuasion system.
6. **Platform.** PC first is assumed. Decided 2026-10-03: keyboard and mouse first, gamepad parity later.
7. **IP stance.** Non-commercial fan game, or an attempt to license? This changes the naming, the distribution and how much effort is worth investing in trilogy fidelity versus reskinnable systems.

## Appendix A: Glossary of Allomantic terms used in this document

- **Push / Pull:** Steelpush (repel metal) and Ironpull (attract metal).
- **Anchor:** a metal source that does not move when Pushed, so all the force goes to Vin.
- **Steelsight:** the game's slow-time aiming mode for Push and Pull.
- **Flare:** burning a metal harder for more effect and faster drain.
- **Coppercloud:** copper's field that hides Allomancy from Seekers.
- **Seeker / Smoker / Thug / Tineye / Coinshot / Lurcher / Soother / Rioter:** Mistings for bronze, copper, pewter, tin, steel, iron, brass, zinc.
- **Hazekiller:** a trained anti-Allomancer soldier who carries no metal.
- **Mistfallen:** people Snapped by the mists in Act 3; Seers.
- **Clip / Boxing:** copper coin (ammunition) / gold coin (money).

## Appendix B: Document map

- `docs/DESIGN.md` (this file): the design.
- `CONTEXT.md`: the glossary of the game's own terms; the words code and levels must use.
- `docs/adr/`: architectural decision records (structure, IP stance, art pipeline).
- `docs/missions/`: per-mission design notes, starting with the two vertical-slice missions.
- `docs/research/allomancy-mechanics.md`: book-sourced magic mechanics, the basis for section 5.
- `docs/research/trilogy-plot-beats.md`: chapter-by-chapter events, cast and locations, the basis for sections 9 and 10.
- `docs/research/world-and-visuals.md`: palette, architecture, costume, adaptations, the basis for section 12.
- `docs/research/comparable-games.md`: traversal references, fan prototypes, Godot notes, IP, the basis for sections 2, 5.5, 7 and 14.
