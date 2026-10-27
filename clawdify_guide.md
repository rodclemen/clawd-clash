# Clawdify guide: adding a universe to Clawd Clash

## Last updated: 19 October 2026 (the universe-modules refactor)

This guide is for an AI assistant (Claude Code or similar) working in this repo. To start, point the assistant at it along with the franchise you want, for example:

> clawdify fraggle rock using clawdify_guide.md

Any film, show, game or comic works. The assistant reads this file and knows what to do from there, from checking that the franchise has enough characters to rendering the trailer.

Each step below ends at an **approval gate**: show the user what you have, then wait. Don't go on to the next step until they've said yes, or they've said what to change and you've changed it. Clawd Clash's universes were built this way, a step at a time with the user signing off. Expect the user to swap characters, rename things, and add ideas of their own.

### One universe, one folder

A universe is one folder, `Sources/App/Universes/<Folder>/`, and nothing else. Its cast, places, trips, ride, HEM's costume, menu icon and trailer all live there, and the app finds it through its `universe.conf`. You never edit a file outside it. That's what lets several people build universes at once without fighting over the same lines, and it's what keeps the shared engine free of special cases nobody can follow.

So there are two roles, and this guide says which one each step belongs to:
- **The contributor** (you, and the user you're working with) grows the folder, from the template to a finished universe and its trailer, and hands off only the folder.
- **The owner** of the repo hands out the universe's number, builds anything new the engine needs, and, after merging, does everything public and shared: the changelog, the README, `llms.txt`, the release.

If the user *is* the owner, you'll do both halves, but still in that order: the folder first, the shared files after.

Reference builds to read when you get stuck:
- **The template** (`Sources/App/Universes/_Template/`) is where every universe starts. Read `TemplateUniverse.swift`'s header first: it's the "start here". Every rule in this guide that's about code is also written next to the code it applies to.
- **Clawd Slayer** (`Sources/App/Universes/Slayer/`, released in 3.7.0) is the newest full universe: fifteen art files, thirteen trips with a file each, three rides that drive, a compaction look, and habits built from the engine's stage quirks.
- **Doctor Clawd** (`Sources/App/Universes/DoctorClawd/`) is the most compact complete one: roster, art, places, transitions, a ride, regeneration on compaction, and a trailer.
- **Clawd of the Rings** (`Sources/App/Universes/ClawdOfTheRings/`) has guises (one character in two looks) and a homebound dragon, both plain facts.

---

## Step 0: Understand the request

"clawdify X using clawdify_guide.md" (or just "clawdify X") means: plan, and then build, X as a new Clawd Clash universe. Work out what X is:
- If X is ambiguous (a franchise with reboots, spin-offs or several eras), ask which parts count. Doctor Clawd covered every Doctor; Stevie Clawdberg was nine films the user picked.
- Some requests are a mix of several properties, like a director's films. Agree on the list first.

Then check the repo's current state, because things change between universes:
- `git status` and `git branch -a`. A universe may be half built on another branch.
- `Sources/App/Universes/NUMBERS` lists every universe there has ever been, with its number, key, folder and status (`shipped`, `reserved`, or the template's `template`). A `reserved` line means someone has already started one, so check it isn't this franchise.
- `~/.claude/plans/` and any project memory may list planned universes.

**Don't pick a number yourself.** A universe's number decides every id it gives out, and ids are saved in running sessions, so two people picking the same one would be a real clash. The owner hands numbers out (Step 2, item 4). You'll ask for one once the overview is approved.

---

## Step 1: Research and viability check

Research the franchise before you propose anything. Use web search: wikis, episode guides, cast lists. Go beyond what you remember, because a full ensemble needs the deep cuts as well as the main cast.

Count the characters who would make **good Clawd Clash characters**:
- **Recognisable:** a fan would know them from a 72×52 pixel sprite with a name tag.
- **Visually distinct:** a costume, silhouette, prop or colour that sets them apart. Ten identical grey suits are one character, not ten.
- **Something to do:** a weapon, a power, or a recognisable signature move or catchphrase.
- **Fits the tone:** the app is a desktop toy. Leave out characters whose whole point is gore, sexual violence, child harm or real-world atrocity. The Clawd Files left out Donnie Pfaster and the Peacock family for this reason.
- **Fictional:** no real people (politicians, celebrities). Never use actors' names.

Sort them into **heroes** and **villains**. Some franchises don't split neatly. Fraggle Rock, for example, has few true villains. In that case, "villains" can be the antagonists, troublemakers, monsters and rivals (the Gorgs, and the creatures that menace the Rock). Say how you sorted them.

**The threshold is 20 heroes and 20 villains.** If either side has fewer than 20 good candidates, tell the user plainly that this would be **a limited experience**: the same faces repeat, and some sides of a fight will be thin. Then offer them a choice:
1. Go ahead with a smaller universe anyway.
2. Widen the source: spin-offs, specials, comics, games, animated series, or a sister franchise.
3. Pick a different franchise.

Agent-only small fry, like Star Clawds' MSE-6 droid, are bit-part creatures that only ever appear as subagents. They help fill out a cast, but they don't count towards the 20.

---

## Step 2: The overview (approval gate 1)

Give the user a short overview to decide on. Include:

**1. A comparison with the universes already in the app.** Read the numbers from the code each time; don't copy them from this guide. The quickest way is `QUICK=1 Tools/CheckUniverse/check.sh --all`, which prints each universe's counts, places, transitions and size. By hand:
- Heroes and villains are the cases of each universe's two enums, in `<Prefix>Facts.swift`. Heroes include HEM, and villains include agent-only characters.
- Places: the `places:` list in each universe's `Theme`, in `<Prefix>Roster.swift`.
- Transitions: the cases of each universe's wipe enum (`DoctorWipe`, `SlayerWipe`, …). Star Clawds uses the engine's plain wipes.

```
| Universe          | Heroes | Villains | Total | Places | Transitions |
|-------------------|--------|----------|-------|--------|-------------|
| Star Clawds       |     NN |       NN |    NN |     NN | plain wipes |
| …one row per universe in NUMBERS (shipped)…                           |
| <New> (proposed)  |    ~NN |      ~NN |   ~NN |    ~20 |       8–15  |
```

**2. A viability verdict:** whether it clears 20 heroes and 20 villains, and the "limited experience" warning if it doesn't.

**3. Name options.** Give two to four, with your recommendation. The style is a light pun that works "Clawd" in: Star Clawds, Marvelous Clawds, Detective Clawds, Doctor Clawd, The Clawd Files, Stevie Clawdberg. The user picks.

**4. Code naming.** The code never uses the franchise's trademark. Propose:
- the **folder** (`Sources/App/Universes/<Folder>/`, like `DoctorClawd`);
- the **prefix**, which starts every file and type in it (`Doctor`: `DoctorRoster.swift`, `DoctorHero`, `doctorTheme`). Swift needs file names unique across the repo, so check nobody else has it;
- the **key**, saved in settings and the screen-saver feed for good (`doctor`);
- the git branch name.

The **number** comes from the owner. Once the user approves the overview, ask the owner (or, if the user is the owner, remind them) to add a `reserved` line to `NUMBERS` on `main`: `<number> <key> <Folder> reserved`. That one line is the only shared change a new universe ever needs, and it's the owner's, so it never clashes with anyone's hand-off. The universe's ids are `number × 1000` and up. The folder, prefix, key, title and number all end up in its `universe.conf`, which `Tools/new-universe.sh` writes for you (Step 7).

**5. The cast at a glance:** the groups you'd draw from (for Fraggle Rock: the Fraggles, the Doozers, the Gorgs, Doc and Sprocket in Outer Space…), with rough numbers per group.

**6. Ideas that make it its own universe.** One or two each:
- the ride (how people arrive and leave);
- a set piece;
- a habit;
- a compaction mechanic, if the franchise has a natural one. Doctor Clawd regenerates and The Clawd Files has missing time. Not every universe needs one.
- **the signature opening**: the show's title sequence, the film's iconic opening, the game's attract screen. This becomes a transition and opens the trailer (see Step 5 and Promo).

If an idea needs something the engine can't do yet, say so here: it'll be an engine request (see [The engine toolkit](#the-engine-toolkit-and-engine-requests)), and the owner should know early.

**7. A tone note:** anything you plan to leave out, and why.

Wait for a go-ahead and a name before you draft the roster.

---

## Step 3: The roster (approval gate 2)

Draft the full cast in tables, grouped the way fans think of the franchise. Every character must carry the show. **Nothing is added just to grow the count.** For scale:
- Star Clawds has 82 characters.
- Doctor Clawd has 98.
- The comic universes have about 200.
- 80–110 is a good target for a TV or film franchise. `check.sh` marks anything outside it as worth a look, not as a failure.

### Naming

- **Light puns on the on-screen name:** Darth Vapor, Fox Clawder, Dana Scrawly, Doctor Gloom. Readable at a glance, never mean-spirited.
- Generic titles get a number or nickname: Doctor One … Fifteen, the Burnt Master.
- **Never use actors' names.** Never use real people.
- If a name has no pun, a near-spelling is fine (Gibson Prays, Max Fenig). A forced pun is worse than none.

### Columns

Heroes and villains each get a table:

```
| # | Name | Look | Weapon | Signature |
```

- **Look:** what makes them recognisable as pixels: hair, outfit, colour, prop.
- **Weapon:** mapped onto the engine (below).
- **Signature:** a recognisable idle move or catchphrase. Write "none" when there isn't a clear one; don't invent one.

### Signature moves and callouts

A character's signature move is the little routine it plays now and then while idle. It's what fans notice and screenshot: Han Yolo spinning his blaster, Thanoz snapping, Doctor Four offering round his jelly babies, the Smoking Clawd blowing smoke rings. Each one is worth getting right.

- **Take it from the source.** Use a gesture, prop or habit the character is known for: Fox Clawder spitting sunflower seeds, Scrawly's raised eyebrow, Doctor Eleven putting on the fez. Look each one up rather than guessing.
- **It has to read at 72×52 pixels.** Big, clear motions work: a spin, a throw, a prop coming out, something rising or glowing. A facial twitch or a fine hand gesture won't show. If the iconic gesture is too small, build it around a prop: Skinnard takes off his glasses rather than just frowning.
- **Keep it short and loopable:** 2–4 seconds (`Persona.signature`, in seconds). The drawing function gets `p.signature` running 0…1 through it, and has to start and end in the character's normal pose.
- **Keep it fun at desktop scale.** A horror character's move should be eerie rather than gruesome: Tooms stretches into a vent, Leonard Betts sheds his head cartoonishly.
- **Callouts** (`Persona.callout`) are what the character says now and then while leading a session. Use a catchphrase, short enough for a speech bubble: "Hmm!", "Jelly baby?", "Allons-y!", "I want to believe". Puns on the catchphrase are fine; long quotes aren't.
- **Not everyone needs one.** "none" is better than a made-up move nobody would recognise. The leads, though, should all have one.

### Get the weapons right

Research **each character's** actual weapon or power. Don't assign one by group. Ask: what do they fight with on screen? What colour is it? Do they fly, hover or walk? Does anything bounce off them? A wrong weapon (a pacifist with a gun, a fire-user shooting blue) breaks the character for fans. If a character never fights, `.none` is the right answer.

### Mapping the franchise onto the engine's weapons (`Sources/App/Persona.swift`)

| Engine | Use it for |
|---|---|
| `.saber` | melee: swords, fists, claws, bats, staffs. Deflects shots. |
| `.blaster` + `ShotStyle` | anything at range: `.energy`, `.beam`, `.bullet`, `.arrow`, `.fire`, `.ice`, `.card`, `.thrown(colour)`, `.web` |
| `.lightning` + `Magic` | magic and energy streams. `jagged: false` gives a steady ray (sonic screwdriver, flashlight beam, mind control). |
| `.none` | stays out of fights: runs, points, cheers |
| `motion: .fly / .hover / .swing` | flyers, floaters, web-swingers. `canSit: false` for things that can't sit (a fish, a ghost). |
| `armoured: true` | shots ricochet off: robots, armour, rock, the unstoppable |
| `bulk` | big bodies, so duels stand further apart |
| `callout` | the line they say now and then while leading a session |

Pick weapons that fit the franchise as a whole. The Doctors use sonic screwdrivers rather than guns. The FBI agents shoot, and carry a flashlight as their signature. A gentle franchise like Fraggle Rock might be mostly `.none` and `.thrown` (radishes!) with the odd `.saber` bonk. That's fine: fights can be silly.

### Also in the roster

These all end up as plain facts in `<Prefix>Facts.swift` (the template's has each one written out, commented):
- **HEM**, the app's rare cameo, is always **the last hero**. Give him a costume idea for this universe: a hat, a coat and a prop for a weapon. Doctor Clawd's is a fez, a bow tie and a sonic; The Clawd Files' is a trench coat, a lanyard and a flashlight.
- **Agent-only small fry:** 0–9 tiny creatures that only appear as agents.
- **Nemeses:** 10–25 hero ↔ villain pairs who face off first when both are on stage.
- **Rivals:** optionally, one pair that should never lead two sessions back to back (Vader and Kylo).
- **Guises:** optionally, one character in two looks that are never on screen together (Strider and Aragorn).
- **Homebound:** optionally, someone who only ever appears at home (Smaug at the Lonely Mountain).
- **Claude's side:** heroes by default. Say if Claude should play the villains instead.
- **Enum order is the order characters are added, and it can never change** (ids are saved). Put the skeleton's first characters first.

Show the full roster with counts per group and totals, and wait for approval. Expect swaps. A swap keeps the count unless the user says otherwise.

---

## Step 4: The places (approval gate 3)

Draft about **20 places**. Doctor Clawd and The Clawd Files have 20; the comic universes have 43. Each is a pixel-art backdrop with:
- **a still picture**;
- **a moving layer**: something alive, like flicker, rain, water or a spinning reel. Be specific: "the I WANT TO BELIEVE poster, pencils stuck in the ceiling tiles, a slide projector flickering";
- **tall-canvas extras** for the screen saver, where the scene is much taller than the window's strip (`Scenes.isTall`).

Rules:
- **The first place is the default**, where the crew stands when nobody's home is known. Make it the franchise's most iconic spot: the TARDIS console room, the FBI basement, Fraggle Rock's Great Hall.
- Give every character a **home** among the places, and list the homes by group.
- Place keys are saved, and must be **unique across every universe**. Start each with the prefix (`doctorConsoleRoom`), as the template does, and check for clashes with `grep -rn 'Location("' Sources/App/Universes`. `check.sh` checks it again before hand-off.
- Prefer variety: interior and exterior, day and night, colour palettes that differ from each other.

Show the list and the homes, and wait for approval.

---

## Step 5: Mechanics and transitions (approval gate 4)

### Mechanics

Propose whichever of these fit. Each one is something your folder gives the engine through the module (Step 7 has the table), so none of them means editing a shared file:
1. **The ride.** Who gets picked up or dropped off, and by what: the Millennial Falcon, the Clawdjet, the TARDIS that materialises, the FBI sedan, the Mystery Machine's cousin. A ride is a `Ride` of your own in `<Prefix>Rides.swift`: it flies in, drives in along the ground, or materialises where it stands (`arrival`), and you draw it nose to the right. The theme's `ride:` closure picks who takes it, and the module's `rides` lists it for Preview. Slayer's school bus and two cars are worked examples.
2. **A compaction mechanic** (optional). When a Claude Code or pi session compacts its context, something in-universe happens to its leader. There are three kinds, set as `compaction` in your facts: **regenerate** (Doctor Clawd: the next face in a list, same session), **away** (The Clawd Files' abduction, Stevie Clawdberg's 88 mph, Clawd Slayer's forgetting spell: gone for a moment, back the same) or **transform** (Clawds of the Universe: a leader with another guise turns into it, and back at the next compaction, never while the other is on stage). The module draws it: `regeneration`, `compactionLook` or `transformation`. Limit it to a clear group of characters.
3. **Habits and stage quirks:** idle behaviour unique to a character. The engine already has `moonwalkers` and a set of `quirks` any universe can use: moving only while nobody looks (the Weeping Angle), a jump and a shiver near something (Captain Clawd), a prop drawn beside someone (T. Wrecks's glass of water), a remark to someone nearby, a hush that takes everyone's voice (the Gentlemen), a signature after every duel (Mayor Wilclawds). There's also `shootOuts`, where one bolt now and then gets through (Han shoots first). Habits that only change a character's own drawing (Slayer's full moon) stay in its art.
4. **Bespoke practice drills:** what characters do when working alone (Dalicks "Elevate!", Doctor Four's jelly babies), as the module's `drills`. Also decide who **floats cross-legged in meditation** (`meditation`: magic users by default, nobody, magic users and saber-wielders, or chosen heroes). Doctor Clawd and The Clawd Files don't; in Clawd Slayer only the witches do.

If a mechanic needs something none of these can do, it's an **engine request**: write down what should happen on screen and who uses it, and it goes to the owner (see [The engine toolkit](#the-engine-toolkit-and-engine-requests)).

### Transitions: between 8 and 15

Every universe except Star Clawds changes place with transitions of its own, so plan **at least 8 and no more than 15**.

- **If the franchise has a signature opening** (a title sequence, a film's opening crawl or logo sting, a game's intro), **it must be one of the transitions.** It's usually the longest and rarest one. It also **opens the trailer** (see Promo).
- Base the rest on the franchise's own visual language: how scenes change in the show, iconic effects, props, creatures. The user may bring their own list. Use theirs first and fill in from yours.
- Each transition has an **owner** (characters who make it come up more often when they're on screen) and optionally a **turf** (places that do the same). Some, like Doctor Clawd's Blink and the Dalick eyestalk, only come up with their owner present (`needsOwner`).
- **Style:** everything is drawn in the app's **pixel art**, not painted or glossy. Use a palette that fits the franchise (The Clawd Files: desaturated greens, cold blue-greys, deep blacks, the odd fluorescent green), with halftone dots or grain where it helps. Avoid fine detail that won't read at pixel scale.
- Optionally, a **universe-wide finishing touch**. The Clawd Files ends every transition with a typewriter caption of the new place's name, the way scenes open in the show (the module's `placeCaption`).
- List what you **left out and why**: overlaps, too fine to read, or a better fit as a habit.

Show a table with #, name, what happens, and who or where makes it come up more often. Wait for approval.

---

## Step 6: Write the plan

Once all four gates are passed, write the whole plan to `~/.claude/plans/<slug>.md`, or to a private repo if the user asks. That folder is on the user's own machine. If they want to share the plan (in a post proposing the universe, say), also give them a version they can paste: the whole plan as one Markdown block, with local paths, memory notes and anything private left out. Use the latest universe's plan in `~/.claude/plans/` as the template if there is one; otherwise follow these sections:

1. **Context:** the name, the folder, prefix and key, the number from `NUMBERS`, size, naming style, tone.
2. **Your folder:** the files it will hold (Step 7's list), which of the module's members it writes and which it leaves at their defaults, and any **engine requests**, each with what should happen on screen and who uses it. There's no list of shared files to wire: there aren't any.
3. **Cast:** the approved tables, the weapon mapping, HEM, agent-only, nemeses.
4. **Places:** the approved list and the homes.
5. **Mechanics.**
6. **Phases:** see below.
7. **Verification.**
8. **Transitions:** the approved table, the style, and what was left out.
9. **Promo:** which transition opens the trailer.

If the assistant has a memory system, save a short project memory pointing at the plan file and branch. Then, once the number is in `NUMBERS` on `main`, create the branch off `main` and start phase 1 when the user says so.

Merging a universe before it's finished, to build the rest on `main` out of sight as Clawd of the Rings was, is the owner's call: `Universe.isReleased` keeps an unreleased universe out of everything people pick from while the tools still see it, and it lives in the core.

---

## Step 7: Build it, in phases

Each phase **builds, gets checked with Preview sheets, and is shown to the user** before the next one starts. Commit at the end of each phase. Everything you commit is inside your folder: the changelog text goes in the hand-off (Step 8), not in `CHANGELOG.md`.

| Phase | What |
|---|---|
| 1. Skeleton | `Tools/new-universe.sh` (below), then turn the template's samples into the real thing: the lead hero, the lead villain and one more; the default place; the menu icon; HEM's costume; the facts. It runs end to end from the first build, in the app, the window, the screen saver and Clawd Royale, with the template's one trip until phase 5. |
| 2. Core ensemble | About 30–40 characters and about 8 places, with their homes and nemeses. It's fine to commit the enum cases first, which then show as stand-ins, and draw them in a second commit. The Clawd Files did this. |
| 3. The rest | The full cast and all places, with every home filled in. Ends with **the character audit** (below). |
| 4. Mechanics | Ride, compaction mechanic, habits and quirks, bespoke drills. |
| 5. Transitions | The 8–15 trips and any finishing touch, through the module's `transitions`. |
| Polish pass | Every weak spot noted in phases 2–5, fixed (see below). **Always before phase 6.** |
| 6. Trailer and hand-off | The trailer (see Promo), the optional showcase, the README and changelog text; then, once it's [complete](#when-a-universe-is-complete), hand off the folder (Step 8). |

### Phase 1: start from the template

Once the owner has added your `reserved` line to `NUMBERS`:

```
Tools/new-universe.sh <Folder> <Prefix> <key> "<Title>" <number>
```

It copies `Sources/App/Universes/_Template/` to your folder, renames its files, types, helpers and place keys to your prefix, fills in `universe.conf`, and takes out the lines that keep the template out of normal builds. It refuses if the number, key and folder don't match their `NUMBERS` line, or if the key or prefix is already someone else's. Copying by hand works too: `Tools/universes.sh` stops the build with a plain message at anything of the template's left over.

Then build and run the real app, with every universe and yours: `./build.sh --no-install` (it runs the copy in `build/` and leaves the installed app and your AIs' hooks alone). Settings → Universe → yours. A sample hero, HEM, a sample villain, one place and one trip are already working, next to all the others. From here you grow the folder: the samples are there to show how things are done, not to be kept.

To look at the template itself without copying it: `TEMPLATE=1 ./build.sh` runs it from `build/` and never saves anything about it, and `Tools/CheckUniverse/check.sh --template` draws its sheets.

### The character audit (end of phase 3, approval gate)

Once every character is drawn, go back over the whole cast before starting on mechanics. When characters are drawn in batches over several sessions, details drift: a weapon gets swapped for one that was easier to draw, a shot colour gets copied from the persona above it, a signature never gets drawn.

For **every** character, check the `Persona` and the drawing against the source and against the approved roster:

- **Weapon:** the right kind (`.saber`, `.blaster`, `.lightning`, `.none`) for how they fight on screen.
- **Shots and magic:** the right `ShotStyle`, the right colours for core and glow, and `jagged` set correctly (steady ray or forked lightning).
- **Motion and body:** `.fly`, `.hover` or `.swing` only if they do that in the source; `armoured`, `canSit` and `bulk` where they fit.
- **Signature:** it's in the roster, `signature:` is set, and the drawing actually uses `p.signature`. Check that it plays and reads in `build/preview cast`. (`check.sh` also catches a signature whose drawing never reads `p.signature`.)
- **Callout:** in character, and short.
- **Look:** recognisable, and not confusable with anyone else in this universe or with a lookalike in another one (they meet in Clawd Royale).
- **Detail:** up to the bar in [Look and style](#characters): folds, buckles, cuffs and boots, seams and rivets, fur in strokes, readable at 1×. A character still in two flat blocks of colour isn't finished.
- **Home and nemesis:** they make sense.

Re-check the facts with a quick search where you're not sure. Then show the user a table of **only the mismatches**, with a proposed fix for each:

```
| Character | What's wrong | Fix |
```

Apply the fixes once the user agrees, and re-render the Preview sheets. Changing a `Persona` or a drawing is safe at any time. Only the enum order is permanent.

### Keep a weak-spot list as you go

At the end of every phase, write down everything that doesn't quite read in the Preview sheets: a prop too small to
see, an outline artefact, a place with a big empty area on the screen saver, a transition whose lettering is too small
at window size. Name the character or place, say what's wrong, and add it to the plan (or the handoff file). **Don't
stop to fix these mid-phase.** The phase's job is to get everything in; the polish pass fixes them all together.

### The polish pass (after phase 5, before phase 6)

Go through the whole weak-spot list before starting on the trailer. **The order matters:** the README's
roster and locations sheets, the desktop line-up, the social preview, the app icon and above all the trailer are all
rendered from the characters, places, rides and transitions. Anything polished after them means rendering them again,
and redoing a trailer is the expensive part. So everything that shows on screen gets finished first, and phase 6 only
renders what's done.

- **Split it by file** and run it in parallel, the way phases 2 and 3 were drawn: one helper per group of art files
  (`Art/<Prefix>Heroes…`, `Art/<Prefix>Villains…`) and per group of `Places/` files, each in its own worktree,
  editing only its own files. Rides, mechanics and transitions are in their own files, so they can be done alongside.
- **Launching many helpers at once** can fail to create some of their worktrees (a race in git). Check every launch
  result, and relaunch exactly the ones that failed: it's easy to relaunch the wrong brief and end up with two helpers
  on one batch and none on another.
- **Before and after.** Each helper renders every fixed character or place before and after, side by side, enlarged.
  Show those to the user: that's the polish pass's approval gate.
- **Engine-wide issues** (a habit every universe shares, like callouts overlapping or steady rays wobbling) are
  reported, not fixed inside one universe's files. They're engine requests: note them for the owner.
- Re-check the rest of the cast too while you're there: the polish pass is the last look before the universe is shown
  off in public.

### Your folder: `Sources/App/Universes/<Folder>/`

Everything below starts as the template's, already renamed to your prefix. Each file's header says what goes in it and the rules that apply there.

| File | What it holds |
|---|---|
| `universe.conf` | The manifest: `number`, `key`, `title`, `prefix`, `entry` (your `<Prefix>Universe`), `reel`, `cask` (left empty: casks are the owner's) and `detail`. Plain `key = value` lines, read by the build scripts. The number and key are forever. |
| `<Prefix>Facts.swift` | The cast's enums, `<Prefix>Hero` and `<Prefix>Villain`, **append-only**, with `hem` the last hero. The universe's constant (`static let <key> = Universe(number: N)`), its `UniverseEntry`, and its `UniverseFacts`: the counts (from the enums, never typed), agent-only, Claude's side, rivals, guises, homebound, compaction. The hook compiles this file and nothing else of yours, so keep it to enums and numbers, no drawing. |
| `<Prefix>Universe.swift` | The entry: `struct <Prefix>Universe: UniverseModule`, everything the engine asks of the universe (the table below). |
| `<Prefix>Roster.swift` | The persona dictionaries merged from the Art files, `Location.<prefix>Home(of:)`, the `Cast` helpers, the nemeses, `let <prefix>Theme = Theme(universe:villains:heroes:places:home:nemeses:ride:menuIcon:legend:)`, the `static let` place keys, and `let <prefix>Places` merged from the Places files. |
| `<Prefix>Hem.swift` | HEM's costume here, a `HemCostume`: his legs, top colours, what shows on his chest, a hat, and his prop. His face, buns and fist-shaking are the engine's. |
| `<Prefix>Icon.swift` | The menu bar icon, 28×26, in colour and in mono (a template image). |
| `<Prefix>Wipes.swift` | The trips (phase 5): an enum of kinds with `duration`, `needsOwner`, owners and `turf`, and a `<Prefix>Trip` with `pick` and `draw`. With more than a handful, each kind's drawing goes in its own `<Prefix><Name>Trip.swift`, as Slayer does. |
| `Art/<Prefix>Heroes1…N.swift`, `Art/<Prefix>Villains1…N.swift` | 8–10 personas a file, each a `Persona(...)` entry plus its `private func draw…(_ c: PixelCanvas, _ p: Pose)`. Add each new file to the roster's list and to the module's `preview`. |
| `Places/<Prefix>Scenes1…N.swift` | A few places a file, each a `Place(name:panel:still:moving:)` drawn in an extension of `Scenes`. Scale landmarks up when `Scenes.isTall(c)`. |
| `<Prefix>Rides.swift`, `<Prefix>Drills.swift`, `<Prefix>Kit.swift`… | As needed: the ride, bespoke drills, a compaction look, art helpers shared across files. |
| `Promo/<Prefix>Reel.swift` | The trailer, compiled only into `Tools/RenderPromo`, never into the app (see Promo). |
| `Promo/<Prefix>Showcase.swift` | Optional: the showcase pictures, compiled only into `Tools/RenderShowcase`. |

Drawing, in short (the template's art files and the header of `Sources/App/Pose.swift` have the rest): the canvas is 72×52, facing right. Every character is Clawd (the orange body) in costume, always on Clawd's four legs. Draw the legs and shoes first, then `c.oy += p.breathe`, then the body; anything that hangs over the legs (coat tails, skirts, a robe's hem) goes after the breath, over the legs, and still leaves four distinct legs showing below.

**Names.** Every file starts with your prefix. Every top-level name that isn't `private` starts with it too (lower-cased for helpers: `doctorTheme`, `doctorFez`), because Preview compiles every universe together, so two universes' `drawHat`s would clash, and a plain name could shadow a system function the app relies on (`scripts/pr-guard.py` refuses one). Keep a file's helpers `private` to it; put helpers several files share in `<Prefix>Kit.swift` with prefixed names. Inside your folder, write `.hero(<Prefix>Hero.x)` rather than a bare `.hero(.x)`: every universe has one, and a bare one is ambiguous once they're all compiled together.

**The line around the folder.** Code in your folder never names another universe, and nothing outside it names yours. `check.sh` checks both.

### The module: what `<Prefix>Universe` gives the engine

`UniverseModule` (`Sources/App/Universes/UniverseModule.swift`) is the whole of what the app asks a universe. The first five have no default, so the compiler tells you, in your own folder, if one is missing. The rest have sensible defaults; the template writes every one out so you can see it and its rule.

| Member | What it is | Default |
|---|---|---|
| `theme` | The cast, the places in order (the first is the default), homes, nemeses, the ride closure, the menu icon, the Status Symbols character. | must be written |
| `places` | Every place's drawing, by key. Every key in `theme.places` has one. | must be written |
| `hem` | HEM's costume (`<Prefix>Hem.swift`). | must be written |
| `preview` | What Tools/Preview needs: the batch names, one per art file in order, and the characters by enum case name. Usually `.of(.<key>, heroes: "<prefix>Heroes", [...], villains: "<prefix>Villains", [...])`. | must be written |
| `transitions` | The trips: `pick` chooses the next (with the last one, the cast and the places), `every` lists one of each kind for Tools/Transitions. | nil: plain edge and clock wipes, as only Star Clawds keeps |
| `playgroundPrompts` | Five sample prompts for the Playground's cards, in the universe's voice. | five general ones |
| `meditation` | Who floats cross-legged among their drills: `.casters`, `.never`, `.castersAndSabers`, `.heroes([...])`; `stones` for floating rock. | magic users |
| `poseStyle` | How guns are drawn. `.classic` is Clawd Wars' way, kept for Star Clawds only. | `.modern` |
| `moonwalkers` | Who has the moonwalk among their habits. | nobody |
| `swingLine` | The web line's colour for characters who swing. | near-white |
| `placeCaption` | A caption that types the place's name in at each scene change (The Clawd Files'). | the usual name |
| `compactionLook(k:cast:)` | What a compacted leader looks like while it's away, `k` 0…1 through it (with `compaction: .away` in the facts). | nothing to see |
| `regeneration` | What a regeneration looks like, drawn over the character in its next face (with `compaction: .regenerate`). | nil |
| `transformation` | What a change into the other guise looks like, and its line (with `compaction: .transform`). | nil |
| `morals` | The lessons leaders give now and then when their session finishes (who, and how often: `morals` in the facts). | none |
| `quirks` | `StageQuirks`: `unseenMovers`, `jitter`, `prop`, `remark`, `hushers`, `afterDuel`. | none |
| `shootOuts` | Pairs where one bolt now and then gets through: shooter, target, what each says, and whether the shooter draws a gun for it. | none |
| `rides` | Every ride, for Preview's sheet. Who takes which is `theme.ride`. | none |
| `drills` | Characters' own practice sets (`BespokeDrill`), by cast. | none |
| `docs` | What Tools/RenderDocs draws for the README besides the roster and places: the desktop line-up (`LineupSlot`s, left to right) and the social preview's title, line and cast. | neither drawn |
| `isTemplate` | Only the template says true. `new-universe.sh` takes the line out, and the default is what you want. | false |

### Verification, every phase

- `./build.sh --no-install` builds and launches the copy in `build/`. If the owner is building their own installed app, plain `./build.sh` installs it too.
- The optimized release build can hit Swift's "unable to type-check in reasonable time" on dense `sin`/`cos` drawing expressions. Find them with `-Xfrontend -warn-long-expression-type-checking=300` and split them up. `check.sh` lists the slow ones for you (it doesn't yet do the full release-style build), so look at its "slow to type-check" line before calling a phase done.
- `Tools/Preview/build.sh`, then:
  - `build/preview cast out.png <name>` shows every pose of one character (or a batch: `<prefix>Heroes1`, or the universe's key or title for everyone); a name another universe has too is an error, so put your key in front (`<key>:<name>`);
  - `build/preview fight out.png <hero> <villain>`;
  - `build/preview place out.png "<Universe title>"` (or place keys) shows each place at window and screen-saver size;
  - `build/preview drills`, `build/preview rides` and `build/preview magic` for the rest;
  - and the batch sheets, one per Art file.

  **Look at the PNGs yourself** before showing the user. Check that each character reads as who it's meant to be, that nobody is confusable with someone else in the cast, and that there are no outline gaps.
  - `build/preview edges out.txt "<Universe title>"` lists every moment solid art touches the frame's edge (see Look and style); everything it lists should be on purpose.
- Transitions: `Tools/Transitions/build.sh`, then `build/transitions <outdir> <placeA> <placeB>` between two of the new places.
- `Tools/CheckUniverse/check.sh <Folder>` (below), at the end of every phase and not just at hand-off: it's quicker to fix a stray name or a clashing place key when it's new. `QUICK=1` skips the builds and sheets.
- In the app:
  - Settings → Universe → the new one. New sessions get cast from it, and subagents include villains and small fry.
  - The screen saver's Options list it.
  - Random and Clawd Royale reach it, and Settings → Universes can uncheck it and check it again.
- For a compaction mechanic, run `/compact` in a Claude session.

### check-universe

`Tools/CheckUniverse/check.sh <Folder>` prints a checklist for your folder: ✓ passes, ✗ fails, ! is worth a look, · is a note. It exits with an error if anything fails, and **it has to pass with no ✗ before you hand off** (see [When a universe is complete](#when-a-universe-is-complete)). It checks:
- the manifest against `NUMBERS`, and that the key, prefix and entry are your own;
- that nothing of the template is left (its key, number, prefix, files, sample places or `CLAWD_TEMPLATE` lines);
- **that only your folder changed since `main`** (the hand-off scope);
- file names and top-level names carry your prefix;
- counts (from the enums), HEM the last hero and drawn by the engine, every home one of your places and every place drawn, place keys unique across every universe, every magic user with its own look, signatures that are really drawn, nemeses, rides, every transition rendering start to end;
- **every id already on `main` still means the same character**, place and magic look;
- that no code outside your folder names your universe, and yours names no other;
- that the app, screen saver, Preview and Transitions build, with slow-to-type-check expressions flagged;
- and it writes sheets to `build/check/<key>/` (cast batches, places, rides, transitions) to look at.

---

## The engine toolkit and engine requests

### The rule

A universe may use anything in the **toolkit** below, freely, from inside its folder. Anything beyond it is an **engine request**: the owner builds it into the core first, as a general hook, and then any universe can use it.

Why: the core is the part everybody shares. If each universe slips its own `if` into it, every hand-off turns into a merge fight, and the core fills up with special cases nobody can follow. Most of the module's members started that way, as one universe's special case (the Weeping Angle, Han shooting first, Captain Clawd's flinch, the typed captions), and were turned into hooks every universe can use.

### The toolkit

| Area | What | Where it lives |
|---|---|---|
| Characters | `Persona` (weapon, shot, magic, motion, `armoured`, `canSit`, `bulk`, `callout`, `signature`, `headTop`, `muzzle`, `pivot`) | `Persona.swift` |
| Drawing | `PixelCanvas` (72×52, facing right), `Pose` (`breathe`, `step`, `armRaise`, `signature` 0…1, `gunY`), `drawLegs`, `drawBody`, `drawBoots`, `drawHood`, `Look`, `C(0xRRGGBB)`, `lerp`, `noise`, `gradient`, `pattern`, outlines | `Pixel.swift`, `Pose.swift`, `Characters.swift`, `Locations.swift` |
| Weapons | `.saber`, `.blaster` + `ShotStyle`, `.lightning` + `Magic`, `.none`. Don't set `magic.variant` yourself: the engine numbers every magic user in order through every universe, so no two look alike. | `Persona.swift`, `Fights.swift` |
| Motion | `.walk`, `.fly`, `.hover`, `.swing` (with `swingLine`) | `Persona.swift` |
| Places | `Place(name:panel:still:moving:)`, `Scenes`' helpers, `Scenes.isTall` and `Scenes.unit` | `Locations.swift` |
| Rides | `Ride` (flies, drives, materialises) and the ride kit | `Theme.swift`, `Rides.swift` |
| Practice | `BespokeDrill`, `Meditation` and the drill helpers | `Drills.swift` |
| Stage | `StageQuirks`, `ShootOut`, `moonwalkers` | `UniverseModule.swift` |
| Transitions | `Trip`, `TransitionSet`, `ShownTrip`, `PlaceCaption` | `UniverseModule.swift`, `ComicTransition.swift` |
| Compaction | `UniverseCompaction` (`.regenerate`, `.away`, `.transform`), `CompactionLook`, `regeneration`, `Transformation` | `Sources/Shared/UniverseFacts.swift`, `UniverseModule.swift` |
| HEM | `HemCostume` | `Universes/Hem.swift` |
| Promo | the promo kit: `Shot`, `Mix`, `brawl`, `windowShot`, `statusOf`, `agentsOf`, `everyAI`, the hook shot, the end card | `Tools/RenderPromo/Kit/` |

You may extend `Scenes`, `Location`, `Cast`, `Universe` and `Ride`, and your own types may conform to `Trip`, `CompactionLook` and `UniverseModule` (`CONTRIBUTING.md` has the full rules for universe code).

### Asking for a new hook

If you need something the toolkit can't do (a new compaction effect, a new kind of quirk, a new motion), open an issue that says what should happen on screen and who uses it. The owner builds it as a general hook on `main`. You then rebase and use it from your folder. **Engine changes and universe folders never travel in the same pull request.**

If the user is the owner, the same split holds: build the hook as its own commit (better, its own branch) on `main`, with the universe that needs it as its first user, then go back to the folder.

---

## When a universe is complete

This is the one place that says what "done" means. Everywhere else in this guide that says a universe is finished, ready or done points here. A universe is complete when **every** box is ticked:

- [ ] **Every approval gate is passed:** the overview, the roster, the places, the mechanics and transitions, the character audit and the polish pass ([the gates](#approval-gates-in-order), 1 to 8).
- [ ] **The whole cast and every place meet the detail bar** in [Look and style](#look-and-style), characters and places both, checked at window size and at full screen (the screen saver), not only zoomed in.
- [ ] **`Tools/CheckUniverse/check.sh <Folder>` passes with no ✗.** Every `!` it prints is explained (in the plan and the hand-off), not just left.
- [ ] **It builds and runs in the real app:** the window, the screen saver, Clawd Royale and Settings → Universes, and the Preview sheets all look right. `build/preview edges` lists nothing touching the frame's edge that isn't meant to.
- [ ] **The trailer** (`Promo/<Prefix>Reel.swift`) has an approved storyboard and renders, `REEL=<reel> build/renderpromo check` included.
- [ ] **The weak-spot list is empty**, or every item left on it is one the user has agreed to leave.
- [ ] **Nothing outside the folder has changed**, and every engine request it needed is already on `main`.

Once it's complete:
1. **The contributor hands it off:** a pull request that adds only the folder, with the changelog and README text in its description ([Step 8](#what-the-contributor-does-phase-6)).
2. **The owner reviews and merges it.**
3. **The owner does the owner's steps** ([Step 8](#what-the-owner-does-after-merging)): `CHANGELOG.md`, the README's universe section and table, `llms.txt`, the docs pictures, a cask if wanted, the release, and the universe's `NUMBERS` line from `reserved` to `shipped`.

Until then it isn't done, however close it looks: don't hand it off, and don't call it finished to the user.

---

## Step 8: Hand-off and release

### What the contributor does (phase 6)

Nothing outside the folder. Phase 6 is what's left on the way to [complete](#when-a-universe-is-complete):
- **The trailer** is in `Promo/<Prefix>Reel.swift`, its storyboard approved (see Promo).
- **The showcase pictures**, if the universe gets a showcase page, are in `Promo/<Prefix>Showcase.swift` (a `Showcase`: its `name` and a `render()` that saves each picture). Read `DoctorClawd/Promo/DoctorShowcase.swift` as the model; `build/rendershowcase docs <name>` draws them. The roster, locations, desktop line-up and social preview aren't in it: RenderDocs draws those from `module.docs`.
- **The module's `docs`** is filled in: the desktop line-up and the social preview's title, line and cast.
- **`Tools/CheckUniverse/check.sh <Folder>` passes with no ✗.**
- **If it's going in as a pull request from a fork**, run `python3 scripts/pr-guard.py main HEAD` too, and fix what it reports.

When every box in [When a universe is complete](#when-a-universe-is-complete) is ticked, open a pull request (or, for the owner, a branch to merge) that **adds only the folder**. Put the shared text in the PR description, not in the shared files:
- the `CHANGELOG.md` entry: what the universe is, its cast and places, its ride and mechanics, in plain words;
- the README section: the universe's blurb, with Cast, Places, Weapons, Set pieces and Sides, laid out like the others';
- anything the owner should know: engine requests still open, weak spots left on purpose, the trailer's 720p file.

### What the owner does, after merging

These are public or shared, so they're the owner's, and done once the folder is on `main`:
- **`CHANGELOG.md`**, from the PR's text. Only `CHANGELOG.md` is kept current; `history/` is frozen.
- **`README.md`**: the universe's section under "The universes", with its collapsible cast-and-places pictures, the universe table, the screen-saver paragraph about transitions if it changed. The tagline and intro say "many" or "several" universes, never a number, so they need no change.
- **`llms.txt`**: the universe list, the folder and prefix, and any new mechanic.
- **The docs pictures**: `Tools/RenderDocs` draws every universe's roster, locations, desktop line-up and social preview into `docs/`, reading the line-up and preview from `module.docs`, so nothing in the tool changes. `Tools/MakeIcon` needs no change either: the app icon is one character standing on the logo.
- **A cask, if wanted**: the manifest's `cask` line. `release.sh` writes a cask for every universe that has one, from the build's list, so there's nothing else to edit.
- **The main promo and the Clawd Royale teaser**, if they should show off the new universe: they're the owner's reels, in `Tools/RenderPromo/main.swift`, along with MakeSocial's comic cover.
- **A showcase repo** (`rodclemen/<universe-name>`), if there's to be one.
- **The release**: `./release.sh` (it works out the version, see below), then the push.
- **`NUMBERS`**: the universe's line goes from `reserved` to `shipped` with the release that first carries it. From then on its number can never be reused, and its enums are append-only for good.
- **Thanks**: a contributor's name in About's "Thanks to" list (`CONTRIBUTING.md` says where).

Trailers never say how many universes there are (the end card reads "One of many universes in Clawd Clash"), so nothing needs updating when one is added. Don't add a count anywhere else either: the README and `llms.txt` say "many" or "several".

**Version numbers** (from Superclawdtural, 4.1.0, on): the first number stays at 4; it moves only by hand, for a change big enough to call a new generation of the app. Stranger Clawds was 4.0.0 under an earlier rule, where every universe raised the first number; that climbed too fast.
- **A new universe raises the middle number:** 4.1.2 → 4.2.0. It's the release where the universe's `NUMBERS` line goes from `reserved` to `shipped`.
- **Everything else raises the last one:** 4.1.2 → 4.1.3. Features, fixes, polish, docs; the CHANGELOG's Added, Changed and Fixed say which.

A release with a universe in it is a universe release, whatever else it carries. Each number counts up as far as it needs (4.1.9 → 4.1.10 → 4.1.11, newer each time), once per release rather than once per fix, and the last starts again at 0 when the middle one goes up. Nobody picks the number: `scripts/next-version.sh` reads it from the commits since the last release tag (a `shipped` line new to `NUMBERS`, else the last number), and `./release.sh` with no version uses it. Give it a version and it stops if that isn't the one. Commit prefixes still matter for the CHANGELOG and the history: `feat:` (or `feat(scope):`) for a feature, `fix:`, `docs:`, `chore:` for the rest. Run `scripts/next-version.sh` before writing the CHANGELOG's `## <version>` heading.

**After the release**, fixes and polish to the universe are later pull requests that, again, touch only its folder.

**Ask the user first** before anything public, whichever role you're in: pushing, opening a PR, creating a repo, adding a cask, releasing.

---

## Promo: the universe's trailer

Each universe has its own trailer in its folder, `Promo/<Prefix>Reel.swift`, rendered by `Tools/RenderPromo` with the app's own sprites, places and transitions, with a synthesized chiptune soundtrack. It's drawn with the tool's kit (`Tools/RenderPromo/Kit/`: `Shot`, `brawl`, `statusOf`, `agentsOf`, `windowShot`, `everyAI`, `Mix`…) and compiled only into that tool, never into the app. The template's reel has the shared shots ready to fill. **Read the Doctor Clawd trailer (`DoctorClawd/Promo/DoctorReel.swift`) as the model.**

### Structure

Use `doctorShots` as the pattern. The trailer runs about 45–50 seconds:

| Shot | Length | What |
|---|---|---|
| `intro` | ~9 s | **The signature opening**, the same one as the transition. For Doctor Clawd it's lightning, the time vortex, and the police box tumbling past; then the title (`doctorTitle`) swells out of it and the camera plunges into white. Rebuild the original's composition, beats and feel in pixel art. Don't copy frames or logos. |
| set piece | ~9.5 s | A short scene that shows the franchise off with its own cast and ride. In Doctor Clawd, Dalicks invade Christmas London, the TARDIS lands under fire, and Doctor Ten sees them off. |
| `hook` | 4 s | Shared: three busy terminals. "Three AIs. Nine agents. One very confused human." / "Sound familiar?" |
| `desktop` | ~4.6 s | `brawl(ctx, .<key>, …)`: desktop mode, with one line of in-universe copy. |
| `status` | ~4.2 s | `statusOf(...)`: four characters, one per state, with a funny aside. |
| `agents` | 4 s | `agentsOf(...)`: "Every subagent gets to be a <hero word>." |
| `window` | ~4.8 s | `windowShot(ctx, .<key>, …, at: .<defaultPlace>)`, with an in-universe pun ("It's bigger on the inside."). |
| `ais` | ~4.4 s | `everyAI(...)`: the BRING YOUR OWN AI* line-up, one character per AI (Claude, Desktop, Codex, Copilot, Qwen, Gemini, pi), with the README footnote. |
| `endcard` | ~4.2 s | The default place, the crew lined up, the title lands, "Have fun. Keep track.", "One of many universes in Clawd Clash · free for macOS", the app icon and the GitHub URL. |

### The reel: `struct <Prefix>Reel: PromoReel`

`<reel>` is a short lowercase name, like `doctor` or `files`: the `reel` line in `universe.conf`. `Tools/universes.sh` finds every folder's `Promo/<Prefix>Reel.swift` and lists it in `registeredReels`, so nothing outside the folder changes. `PromoReel` (`Tools/RenderPromo/Kit/Reel.swift`) asks for:

| Member | What it is | Default |
|---|---|---|
| `name` | Its REEL name: `REEL=<reel> build/renderpromo video promo`. | |
| `base` | The video's file name without ".mp4" (`<universe-name>-promo`); the storyboard is named after it. | |
| `small` | The GitHub-sized copy's name in `promo/720p/` (`<Universe-Name>`). | |
| `title` | The storyboard sheet's title. | |
| `universe` | The universe it's the trailer of. | |
| `shots` | The shots in order (`let <prefix>Shots: [Shot]`), with the intro and set-piece drawing and `<prefix>Title`. | |
| `beats` | The storyboard, one row per beat: time, title, what happens, on-screen text, sound. | |
| `sound(_ m: Mix)` | The score and effects. New sound effects go in an `extension Mix` next to it, like `sonic` and `exterminate`. | |
| `geminiTask` | What Gemini's terminal is busy with on the desktop (`gemini ▸ …`). | |
| `brawl` | Who's in its desktop brawl, and its caption (`BrawlCast`). The main promo plays this shot too. | |
| `window` | Its window: the place, who fights, who cheers, and the prompts on the two cards (`WindowCast`). The main promo plays this too. | |
| `softWipe` | The soft promo wipe's length. | 2.7 s |
| `poster` | The first frame GitHub shows before play: a shot and a time into it. | the end card at 2.5 s |

### The showcase: `struct <Prefix>Showcase: Showcase` (optional)

Only for a universe with a showcase page. `Promo/<Prefix>Showcase.swift`, found the same way (`registeredShowcases`), compiled only into `Tools/RenderShowcase`. `Showcase` asks for just two things: its `name` (what `build/rendershowcase docs <name>` calls it) and `render()`, which draws and saves every picture with the tool's kit. Its pictures are the universe's own icon and the strips showing its set pieces.

### Music and sound

- **Write original notes.** You can evoke the theme's *sound*: its instrumentation, tempo, mood, and signature sounds like a wheeze, a sting or thunder. Never reproduce the copyrighted melody. Doctor Clawd's storyboard puts it this way: "in the sound of the old electronic theme but our own notes".
- Line the hits up with the beats: the title landing, the ride arriving, the end card's sting.

### The routine

1. Build. The full `swiftc` command is in `Tools/RenderPromo/main.swift`'s header comment. It sources `Tools/universes.sh` and compiles the App sources, the universes (`$UNIVERSE_APP`, and `$UNIVERSE_PROMO` for the trailers), `Shared/`, the kit and `main.swift` into `build/renderpromo`.
2. `REEL=<reel> build/renderpromo storyboard promo` writes `promo/storyboard-<universe-name>.png`. **Show the storyboard to the user for approval before rendering video.** This is an approval gate.
3. `REEL=<reel> build/renderpromo frame promo 4.5` renders spot-check frames. Look at them, the intro especially.
4. `REEL=<reel> build/renderpromo check` renders every frame once.
5. `REEL=<reel> build/renderpromo video promo` writes `promo/<universe-name>-promo.mp4` at 1080p, H.264 + AAC.
6. `REEL=<reel> build/renderpromo 720p promo` writes `promo/720p/<Universe-Name>.mp4`, the copy under 10 MB for GitHub. The user uploads it by hand.

`promo/` is git-ignored apart from the main trailer and the blooper reel, so rendered videos aren't committed.

---

## Look and style

Every universe has to sit next to the others in Clawd Royale, so the art follows one house style. Read this before
drawing anything, and check your work against it at the end of every phase.

### Characters

- **Clawd in costume.** Every character is Clawd's blocky orange body (x 18…37, y 26…37) on four legs (y 38…43),
  facing right on a 72×52 canvas. The view mirrors it to face left. A costume, hair, a helmet, a prop or a creature
  body go over and round that; the four legs always show. Giants and creatures can fill the frame, but they still
  stand on four legs on the ground row.
- **Pixel art, drawn in code.** Whole pixels, flat colours (`C(0xRRGGBB)`), no gradients or blur on the body. Give
  each material two or three tones: a base, a darker shade and a lighter highlight (`suit`, `suitDark`, `stripe`).
  Light comes from the front-left: highlights on top and left edges, shade on the right and underneath.
- **Detail: the bar every character meets.** A flat costume in two blocks of colour looks unfinished next to the
  rest. In 3.7 every Star Clawds character was brought up to this, and it's the standard from now on, not a polish
  extra. Keep the silhouette, colours and props, and add the small things that make the costume real:
  - **Clothes:** folds and a shaded far side, a collar or neckline, cuffs, a belt with its buckle, pouches or a
    holster, and boots a shade apart from the legs.
  - **Armour and droids:** seams, a few rivets, plates lit along the top edge, vents or grilles, a small light, a
    scratch or two. Fewer than you think: a plate covered in rivets turns to noise at 1×.
  - **Fur, skin, scales and hair:** short strokes that follow the shape and a lit run along the top, never
    scattered single pixels. Specks read as dirt or noise; strokes read as fur.
  - **Long robes and gowns stay long.** Don't shorten them to show the legs. Hint at the four legs under the cloth
    with a soft shadow either side of each, and let the toes peep out under the hem if it suits.
  - **Mind the legs.** Knee plates plus boots plus a lit edge can turn a leg into stripes, and dark boots under a
    pale cape read as holes. Look at the legs on their own before moving on.
  - **It has to read at 1×.** Check at normal size, not only zoomed in: detail too faint to see is wasted, and
    detail too busy looks like a smudge. When in doubt, take a stroke away.
- **Don't outline the silhouette yourself.** The app adds a 1-pixel outline round every character in its AI's colour
  (white for Claude Code), so dark costumes read on a dark desktop. Use the dark `outline` colour only for lines
  inside the figure: a belt, a visor, the edge of a coat.
- **Solid or see-through, nothing in between at the edge.** The outline goes round **fully opaque** pixels only.
  Anything partly see-through counts as a glow and gets no outline. So:
  - draw the body, costume, hair, props and signs fully opaque;
  - keep see-through for what should stay soft: glows, magic, smoke, ghosts, phasing, water, speed blur;
  - where something see-through touches the silhouette, make it either solid or faint (under about 25% opacity).
    Half-opaque pixels along an edge make the outline dotted. The Necro-maintainer's smoke had exactly this.
- **Stay inside the frame, with a pixel to spare.** Anything past the canvas edge is cut off, outline and all, and a
  solid pixel on the edge itself loses its outline on that side. Keep solid art within columns 1…70 and from row 1 down, in
  **every pose at every moment**: walking, fighting, waiting, cheering, sitting, every idle habit and the whole
  signature move. Some things eat into that room:
  - the breathing bob lifts the upper body 1 px;
  - hovering, hops and the bounce habit lift the whole sprite 2 to 4 px (the engine gives back what it must, but
    only that lift, not your own raised arms);
  - raised weapons, arms, wings, tails and signature props swing out further than they rest.

  So a tall character's head should start around row 5 or lower, and long weapons, wings and tails should shorten
  or tuck in as they swing towards an edge. Set the persona's `headTop` to the head's real top row.
- **What may leave the frame on purpose:** shots, beams, thrown things, lassos and sound rings flying out; a
  character running, charging or teleporting off; lightning, birds or ships coming in from above; anything below
  the feet touching the bottom edge. Nothing of the character's own body or held props.
- **Check it:** `build/preview edges out.txt "<Universe title>"` draws everyone at 80 moments of every state and 40
  of every habit and signature move, and lists each state where solid art touches an edge, with a picture of the
  first such moment next to the report. Everything it lists should be on purpose. `build/preview cast` shows the
  outline itself: look for gaps.

### Places

- **The same pixel art**, at the same pixel size as the crew. A palette of the franchise's own (The Clawd Files:
  desaturated greens, cold blue-greys, deep blacks), with grain or halftone where it helps. Nothing painted, glossy or
  photographic.
- **The crew has to read on it.** Characters stand on the bottom `floorRows` rows, and their names and speech
  appear above them. Keep the floor and the band just above it plain and mid-to-dark, so white outlines and labels
  stand out. Put the busy detail (shelves, machinery, signs, crowds) higher up and at the sides.
- **Never a bare backdrop.** Even a place that is meant to be empty (a desert farm, a white corridor) gets its
  furniture: the buildings at a believable size, lit on the side the light comes from with a shadow on the ground,
  panels, hatches, pipes, small lights, rocks, a far-off landmark. A sky and a floor with one prop on them looks
  unfinished next to the rest.
- **Props keep their size.** Draw buildings, doors and machines at a fixed size (in `Scenes.unit(g)` steps), not as
  a fraction of the scene's height: the screen saver is many times taller than the window, and a door sized from
  the height turns into a sliver. A door stands on the floor.
- **The moving layer stays subtle:** a flicker, rain, water, a blinking light. Nothing that flashes across the
  crew or pulls the eye from them.
- **Window and screen saver.** The window shows a short strip of the place; the screen saver shows it much taller
  (`Scenes.isTall`). Check both with `build/preview place`: the strip must read on its own, and the tall version
  needs something in its upper part, not a big empty sky.
- **Text in a place** (a sign, a poster) is short and big enough to read at window size, or left out.

## House style

- **Never edit outside your folder.** Not to wire something in, not for a quick fix, not for a one-word typo in the core. If the universe needs something from the engine, it's an engine request; if you spot a bug in the core, note it for the owner. A hand-off that touches only its folder can't clash with anyone else's.
- **Writing** (comments, docs, changelog, commit messages): plain, friendly English, British spelling ("colour", "armoured"). Short sentences that explain *why*. Comments describe what you'd see on screen ("the fez, a little to the back, its tassel hanging"). Match the density and voice of the surrounding code.
- **Code:** match the existing universes exactly: file layout, naming, `private` helpers per file, `C(0xRRGGBB)` colours, no new dependencies, no image assets. Every sprite, place and effect is drawn in code.
- **Commits:** conventional commits scoped to the universe key, e.g. `feat(clawdfiles): phase 2, the core ensemble and seven more places`, with a body that says what's in it in plain words. One commit per phase, or two (stand-ins, then the art).
- **Ids are forever:** never reorder or remove enum cases once they've been committed to `main`. Only append, and keep HEM the last hero. The number in `NUMBERS` is forever too.
- **Ask before anything public:** pushing, PRs, repos, casks, releases.

## Approval gates, in order

1. **Overview:** the comparison table, viability, name, code naming. → go or no-go, and a name. Then the owner hands out the number.
2. **Roster:** the full cast tables with each character's weapon and signature move, HEM, agent-only, nemeses. → approved, or swaps.
3. **Places:** about 20 places and the homes. → approved.
4. **Mechanics and transitions:** the ride, the compaction mechanic, habits, drills, 8–15 transitions including the signature opening, and any engine requests. → approved.
5. **Plan file** written, then the branch is created and the template copied. → the user says start.
6. **Each build phase** is shown with Preview sheets. → next phase.
7. **The character audit** (end of phase 3): every character's weapon, shots, magic, motion, signature and callout checked against the source; the mismatches table. → fixes approved.
8. **The polish pass** (after phase 5): before-and-after renders of every weak spot fixed. → phase 6 can start.
9. **The promo storyboard.** → render the video.
10. **Complete:** every box in [When a universe is complete](#when-a-universe-is-complete) ticked, then the hand-off, a pull request that adds only the folder. → the owner merges and does the owner's steps.
11. **Anything public.** → explicit OK.
