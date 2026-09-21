# Let's Act — Design Language

Version: 0.1  
Platform priority: iPadOS first, iOS compatible  
Audience: Children aged 3–14, plus Director / Parent users

---

## 1. Design intent

Let's Act should not look like:

- an AI utility;
- a PDF reader;
- a school management system;
- a professional actor tool;
- a noisy children's game.

It should feel like:

> **Apple-native restraint + children's picture-book warmth + stage-performance atmosphere.**

The interface should help a child focus on one role, one cue, and one action at a time.

---

## 2. Design keywords

Five words define the visual and interaction system:

### Soft
Rounded shapes, comfortable spacing, restrained contrast, no sharp technological styling.

### Stage
Use theatrical ideas such as spotlight, cue, curtain, cast, scene, and stage — but as subtle interaction metaphors rather than decorative clichés.

### Focus
Only one element should feel primary at any moment.

### Playful
Friendly enough for a young child without becoming visually childish for a teenager.

### Calm
Avoid gamification noise, visual overload, constant motion, and reward spam.

---

## 3. Core visual metaphor: Spotlight

The primary visual metaphor is the **stage spotlight**.

The currently relevant content should appear visually “lit”:

- active speaker;
- current line;
- current word;
- child's turn;
- current practice task.

Everything else should gently recede.

This is more important than adding illustration or decoration.

### Example

When another character speaks:

- character name becomes prominent;
- current sentence is high-contrast;
- current word is emphasized;
- inactive content reduces contrast.

When it becomes the child's turn:

- the child's role card subtly moves forward;
- the microphone state becomes visible;
- the cue label appears;
- surrounding UI becomes quieter.

---

## 4. Visual foundation

### 4.1 Background

Primary light background:

**Warm Ivory**  
Suggested starting token: `#FAF7F2`

Rationale:

- softer than pure white;
- resembles paper and scripts;
- reduces the sterile look of utility software;
- supports long reading sessions.

Dark rehearsal mode may later use a near-black such as `#171719`, but full dark mode is not required for V1.

### 4.2 Primary brand accent

**Curtain Red**  
Suggested starting token: `#E65D5D`

Use only for:

- primary CTA;
- active child role;
- progress emphasis;
- brand accents;
- important cue states.

Do not flood entire screens with red.

### 4.3 Character colors

Characters may receive automatically assigned soft identity colors:

- Lavender
- Mint
- Sky
- Peach
- Butter
- Rose

These colors exist to identify speakers, not to decorate pages.

They may be used for:

- character chips;
- avatars;
- small role indicators;
- dialogue identity markers.

They should not become page backgrounds.

---

## 5. Typography

### Child experience

Preferred family:

**SF Pro Rounded**

Why:

- familiar and native;
- friendly without being cartoonish;
- highly readable;
- suitable from early childhood through young teens.

### Director / Parent experience

Preferred family:

**SF Pro**

This creates a subtle separation:

- Child = softer and more expressive.
- Director = more utilitarian and information-dense.

The overall system must still feel unified.

### Hierarchy principles

Use a limited hierarchy:

1. Role / primary task
2. Current dialogue
3. Cue / state
4. Supporting metadata

Avoid excessive heading levels.

Dialogue text must always dominate secondary controls.

---

## 6. Shape language

Primary surfaces use large rounded cards.

Suggested corner-radius system:

- Small control: 12–16 pt
- Standard card: 20 pt
- Hero / role card: 24–28 pt

Avoid:

- tiny bordered cards everywhere;
- spreadsheet-like containers;
- dense separators.

Cards should represent meaningful objects such as:

- role;
- scene;
- practice mode;
- progress state.

---

## 7. Touch targets

Child-facing controls should prioritize generous touch areas.

Recommended minimum:

- 52–56 pt for common child actions;
- larger for primary buttons in Practice.

Primary child controls:

- Play / Pause
- Repeat
- Hint
- Continue
- Next

Secondary configuration controls belong in Director / Parent mode.

---

## 8. Motion language

Motion communicates state. It is not decoration.

Only three motion patterns are required in V1.

### 8.1 Spotlight

When speaker or line changes:

- active content gently increases prominence;
- previous content fades slightly.

No bouncing or exaggerated scaling.

### 8.2 Cue

When it becomes the child's turn:

- child role surface slightly advances;
- microphone state appears;
- a subtle cue pulse may occur once.

### 8.3 Complete

When a scene or practice block completes:

- interface settles;
- spotlight softly dims;
- optional subtle curtain-like transition.

Avoid:

- coin bursts;
- treasure chests;
- constant confetti;
- aggressive streak effects;
- looping attention animations.

---

## 9. Sonic UI

Sound is part of the product language because rehearsal is audio-first.

Use a small sonic vocabulary:

### Start
A short, quiet stage-bell style sound.

### Cue
A subtle signal when the child's line begins.

### Complete
A restrained applause texture or tonal resolution.

Rules:

- sound effects must never compete with dialogue;
- all sonic UI must be optional;
- sound should feel theatrical, not arcade-like.

---

## 10. Child experience principles

### One Screen, One Job

A Child screen should not expose:

- script editing;
- voice configuration;
- model settings;
- OCR controls;
- analytics;
- complex scene management.

Practice should expose only what the child needs now.

### Primary child concepts

The child should mainly understand three things:

- **My Role**
- **Practice**
- **Progress**

Avoid requiring the child to understand:

- project;
- script object;
- cast management;
- OCR;
- AI;
- parsing;
- document structure.

---

## 11. Director / Parent experience principles

Director / Parent owns complexity.

They can:

- create a show;
- import a script;
- review OCR;
- review scenes and characters;
- assign one or more roles;
- configure practice;
- review progress.

The Director / Parent experience may use:

- sidebar navigation;
- denser cards;
- structured lists;
- editor states.

On iPad, `NavigationSplitView` is preferred for this mode.

---

## 12. Child home

If one active role exists, the home screen should effectively be the role.

Example information hierarchy:

- Show name
- “You are playing”
- Role name
- Current scene
- Lines remaining
- Continue Practice
- Progress

The child should not land on a project-management dashboard.

---

## 13. Practice Player

The Practice Player is the central product surface.

### iPad landscape

Recommended layout:

- compact cast / scene context area;
- dominant dialogue area;
- large current speaker;
- current line;
- word-level highlight;
- prominent “Your turn” state;
- bottom practice controls.

### iPhone

Use the same conceptual model in a single-column layout.

Do not redesign the product around iPhone first and scale it up for iPad.

---

## 14. Dialogue rendering

Dialogue should feel performative rather than document-like.

### Current line

- highest text contrast;
- comfortably large type;
- generous line spacing;
- centered or visually isolated.

### Current word

Emphasize using typography and/or underline rather than bright karaoke colors.

Possible states:

- already spoken: reduced contrast;
- current word: strong weight / underline;
- upcoming words: normal contrast.

This creates word-by-word guidance without making the UI look like a karaoke machine.

---

## 15. Age adaptation

The product serves 3–14 year olds, but should not create three entirely different brands.

### Ages 3–6

Prioritize:

- voice;
- icons;
- large actions;
- minimal text;
- repeat-after-me;
- role recognition.

### Ages 7–10

Prioritize:

- read-along;
- cue practice;
- gradual memorization;
- simple progress.

### Ages 11–14

Prioritize:

- cleaner, less juvenile presentation;
- scene-level rehearsal;
- off-book practice;
- more precise feedback.

The visual system stays consistent; density and explanation level adapt.

---

## 16. Progress language

Avoid game-economy language.

Do not use:

- XP;
- coins;
- gems;
- loot;
- competitive leaderboard.

Use learning states instead:

- New
- Learning
- Remembered
- Mastered

For scenes:

- Needs Practice
- Practicing
- Ready

Progress should describe real readiness, not engagement tricks.

---

## 17. Parent gate

Director / Parent mode should be protected from accidental child access.

Preferred options:

- Face ID / Touch ID where appropriate;
- Apple-style parental gate;
- simple adult verification fallback.

Child mode should be the default runtime mode on a shared iPad.

---

## 18. Accessibility

V1 design requirements:

- Dynamic Type support;
- VoiceOver labels;
- high-contrast text states;
- color must never be the only state indicator;
- captions remain available when audio is used;
- large touch targets;
- reduce-motion support.

---

## 19. Design anti-patterns

Do not introduce:

- neon AI gradients;
- chatbot-first UI;
- generic sparkle icons everywhere;
- persistent AI assistant bubbles;
- excessive badges;
- dense settings in practice;
- social engagement counters;
- achievement spam;
- cartoon mascots as a dependency for comprehension.

Let’s Act should feel like a beautifully designed learning tool that happens to use AI.

---

## 20. Design system summary

The visual system can be summarized as:

> **A calm digital stage where the child’s current role and current line are always in the spotlight.**

Every design decision should be evaluated against this sentence.
