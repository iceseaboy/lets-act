# Let's Act — Product Specification

Version: 0.1  
Primary platform: iPadOS  
Secondary platform: iOS  
Target age: 3–14

---

## 1. Product definition

Let's Act helps children learn and master a role in a play, musical, or drama activity through interactive practice.

The core transformation is:

> **Static script → interactive role-learning experience**

The child journey is:

**Script → My Role → Learn → Practice → Remember → Perform**

The product is not intended to be a general script-writing tool or professional production-management suite.

---

## 2. Product roles

There are only two product roles.

### 2.1 Child

The Child:

- learns one or more assigned roles;
- listens to scenes;
- reads along;
- repeats lines;
- practices cues;
- rehearses against other characters;
- gradually removes prompts;
- works toward performing off-book.

### 2.2 Director / Parent

Director and Parent are one permission model.

They:

- create shows;
- import scripts;
- review OCR output;
- review AI script structure;
- confirm characters;
- assign one or more roles to the child;
- configure practice;
- review learning progress.

A teacher can later use the same Director role with expanded multi-child management.

---

## 3. Core product object

The top-level user object is a **Show**, not a Script.

Example:

- Alice in Wonderland
- Frozen Jr.
- The Lion King Jr.

A Show contains:

- Script
- Scenes
- Characters
- Child roles
- Practice configuration
- Progress

---

## 4. Core data model

### Show

```text
Show
├── Script
├── Scenes[]
├── Characters[]
├── ChildRoles[]
└── PracticeProgress
```

### ScriptUnit

Every script must be normalized into structured units.

Suggested fields:

```json
{
  "id": "unit_001",
  "type": "dialogue",
  "sceneId": "scene_03",
  "characterId": "alice",
  "text": "Where are you going?",
  "order": 18
}
```

Supported `type` values from Day 1:

- `scene_heading`
- `dialogue`
- `stage_direction`
- `song`
- `lyrics`

Support for songs and lyrics is required in the schema even if pitch training is not included in V1.

### Child roles

Use:

```text
childRoles: [CharacterID]
```

Do not use a single-role-only structure.

Children frequently play multiple small roles in school productions.

---

## 5. Information architecture

### Child

```text
Home
└── My Role
    ├── Learn
    ├── Practice
    └── Progress
```

### Director / Parent

```text
Shows
└── Show
    ├── Script
    ├── Characters
    ├── Child Role
    ├── Practice Settings
    └── Progress
```

Avoid a large tab bar.

Director mode on iPad should prefer a split-view navigation pattern.

---

## 6. Show creation

Director / Parent can create a Show using:

### V1

- Camera scan
- Photo library
- PDF import
- Paste text
- Manual text entry

### Later

- Word
- Final Draft
- Fountain
- Web import

---

## 7. Camera and OCR pipeline

Recommended pipeline:

```text
Camera / Photos
    ↓
Apple VisionKit / Vision
    ↓
Raw OCR text
    ↓
Script understanding model
    ↓
Structured script
    ↓
Director review
```

OCR should be device-first where practical.

The product must never treat OCR output as final without a review step.

---

## 8. Script Review

Director / Parent must be able to:

- edit recognized text;
- change speaker attribution;
- merge incorrectly split characters;
- separate incorrectly merged characters;
- move dialogue to a scene;
- edit scene headings;
- delete OCR noise;
- add missing lines;
- change a ScriptUnit type.

Product rule:

> **AI proposes. Director confirms.**

---

## 9. Script intelligence

AI script processing should identify:

- scenes;
- scene headings;
- characters;
- dialogue;
- stage directions;
- songs;
- lyrics;
- likely character aliases.

Example alias case:

- WHITE RABBIT
- RABBIT
- WHITE RABBIT 1

The model may suggest a merge, but Director / Parent confirms it.

---

## 10. Character review and role assignment

After parsing, present:

- character name;
- line count;
- scenes appearing in.

Director / Parent chooses:

> Who is the child playing?

One or multiple roles may be selected.

Once selected, those roles are treated as the child's lines in practice.

All other roles are played by the app.

---

## 11. Practice Player

The Practice Player is the central product engine.

It operates on structured ScriptUnits, not raw PDF pages.

V1 includes five modes.

---

## 12. Practice Mode 1 — Listen

Purpose:

> Understand the scene before speaking.

Behavior:

- app performs all characters;
- each character has a distinct voice;
- current speaker is highlighted;
- current line is visually dominant;
- words are highlighted in sync with speech.

The child does not need to speak.

---

## 13. Practice Mode 2 — Read

Purpose:

> Practice the child’s own lines while retaining full text support.

Behavior:

- app performs all other characters;
- when the child’s cue arrives, full child dialogue is shown;
- microphone listening begins;
- app detects completion;
- scene continues.

---

## 14. Practice Mode 3 — Repeat

Purpose:

> Learn difficult lines by imitation.

Behavior:

1. app demonstrates the child’s line;
2. playback pauses;
3. “Your turn” appears;
4. child repeats;
5. recognition checks the attempt;
6. user can repeat again or continue.

This mode is especially important for younger children and second-language learners.

---

## 15. Practice Mode 4 — Practice

Purpose:

> Rehearse the scene with the app as scene partner.

Behavior:

- app performs every non-child role;
- child performs assigned role(s);
- child lines may remain visible;
- app advances based on turn detection;
- Repeat and Hint remain available.

This is expected to be the most frequently used mode.

---

## 16. Practice Mode 5 — Off Book

Purpose:

> Perform without reading the child’s full lines.

Behavior:

- other characters perform normally;
- child dialogue is hidden;
- “Your turn” appears;
- Hint reveals progressively.

Suggested Hint ladder:

1. first word;
2. first 3 words;
3. full line.

The product should not fail the child aggressively for needing a hint.

---

## 17. Word-level subtitle guidance

Required V1 capability.

States:

- spoken words: lower contrast;
- current word: high emphasis;
- upcoming words: standard contrast.

Avoid strong multi-color karaoke styling.

For system TTS, word-range callbacks can drive synchronization without a separate model.

---

## 18. Speech recognition behavior

Speech recognition supports:

- start-of-speech detection;
- end-of-speech detection;
- transcript generation;
- local comparison to target line;
- cue advancement.

The product is a rehearsal tool, not a pronunciation examination.

Child-facing feedback should be simple:

- Got it
- Almost
- Let’s try again

Do not expose raw recognition confidence to the child.

---

## 19. Line matching

Default line learning is script-exact, not semantic paraphrase.

Example:

Target:

> Get out of here!

Child:

> Go away!

The meaning is similar, but the line should not be considered memorized.

Why:

The learning objective is to master the assigned script, not generate semantically equivalent dialogue.

Line matching may use:

- token normalization;
- punctuation normalization;
- edit distance;
- missing-word analysis;
- word order;
- speech confidence.

This can be deterministic and local.

---

## 20. Age adaptation

Director / Parent selects an age range rather than exact date of birth:

- 3–6
- 7–10
- 11–14

Age range can influence:

- interface density;
- amount of visible text;
- line-matching tolerance;
- feedback wording;
- default practice mode.

Avoid collecting exact birthday unless later required for a justified feature.

---

## 21. Progress model

Line states:

- New
- Learning
- Remembered
- Mastered

Scene states:

- Needs Practice
- Practicing
- Ready

A line should not become Mastered after one correct attempt.

Suggested V1 rule:

> 3 successful low-prompt attempts across at least 2 sessions.

Exact threshold should remain configurable for testing.

---

## 22. Child home

If one active Show / role is assigned, Child home should directly center on it.

Recommended content:

- show name;
- “You are playing”;
- role name;
- current scene;
- lines remaining;
- Continue Practice;
- progress.

Do not present a project-management dashboard.

---

## 23. Director home

Director / Parent sees:

- Shows;
- assigned child roles;
- script status;
- scene count;
- progress;
- Edit Script;
- Practice Settings.

Complexity is intentionally placed here rather than in Child mode.

---

## 24. Parent gate

Director / Parent mode must be protected.

Preferred:

- Face ID / Touch ID where available;
- Apple-style adult gate fallback.

Child mode is the default operating state on a shared device.

---

# 25. Model and technology mapping

The architectural principle is:

> **Device first. AI where it provides unique value.**

AI should understand content; deterministic product logic should run the learning experience.

---

## 25.1 Camera scanning

**Technology:** Apple VisionKit

Use for:

- live document capture;
- camera text scanning;
- page capture UX.

No large language model required.

---

## 25.2 OCR

**Technology:** Apple Vision

Use for:

- on-device text recognition;
- page text extraction where practical.

Cloud OCR should be a fallback, not the default architecture.

---

## 25.3 PDF text extraction

**Technology:** PDFKit

If the PDF already contains a text layer, extract it directly instead of OCR.

Fallback to page OCR when required.

---

## 25.4 Script parsing

**Recommended model class:** cost-efficient structured-output language model.

Primary responsibilities:

- scene detection;
- character detection;
- dialogue attribution;
- stage-direction classification;
- song / lyric classification;
- alias suggestions;
- OCR ambiguity cleanup suggestions.

Implementation requirement:

- strict structured JSON output;
- schema validation;
- retry on invalid structure;
- never directly overwrite the user-reviewed source.

Do not use the highest-cost reasoning model by default.

A stronger model may be used only as a fallback for unusually complex or corrupted scripts.

---

## 25.5 TTS — default

**Technology:** Apple `AVSpeechSynthesizer`

Use for:

- character voices;
- Listen mode;
- Repeat demonstrations;
- Practice scene partners;
- word-range speech callbacks.

Advantages:

- low latency;
- device-native;
- privacy-friendly;
- no per-token cloud cost;
- works well with word-level UI synchronization.

---

## 25.6 TTS — premium / expressive

**Optional cloud model:** expressive neural TTS.

Use only when product testing shows native voices are insufficiently theatrical.

Possible use cases:

- more expressive character delivery;
- differentiated speaking styles;
- theatrical tone.

This is an enhancement, not a V1 dependency.

---

## 25.7 Speech recognition — default

**Technology:** Apple Speech framework / SpeechAnalyzer where available.

Use for:

- child speech transcription;
- turn detection;
- line matching.

Default audio policy:

- process locally where supported;
- do not retain recordings by default;
- do not upload child voice by default.

---

## 25.8 Speech recognition — cloud fallback

Optional cloud transcription may be offered as an explicit enhanced-recognition mode.

Requirements:

- Director / Parent opt-in;
- clear disclosure;
- minimize retention;
- do not make cloud processing a hidden default.

---

## 25.9 Line accuracy

**Technology:** local deterministic algorithm.

Possible implementation:

- text normalization;
- token comparison;
- Levenshtein distance;
- omission detection;
- insertion detection;
- word-order checks;
- confidence weighting.

No LLM is required for the normal path.

---

## 25.10 AI semantic feedback

Not required for V1.

If later introduced, it may help distinguish:

- recognition error;
- near-exact line;
- meaningful omission.

It must not replace the requirement to learn the actual scripted line.

---

## 25.11 Realtime AI acting coach

**Not V1.**

Potential future feature:

> “Try that line again, but more surprised.”

This would move the product from role memorization into acting instruction.

It should be treated as a separate product layer and validated independently.

---

## 26. Child voice policy

Product boundary:

> **Let’s Act does not clone children’s voices.**

Do not:

- train custom child voices;
- imitate a specific child's voice;
- generate synthetic speech that impersonates the child.

The app may use adult / stylized synthetic cast voices for scene partners.

---

## 27. Privacy architecture

Default principles:

### Local first

Prefer on-device processing for:

- OCR;
- speech recognition;
- line comparison;
- progress;
- playback state.

### Do not retain child audio by default

Practice should work without building an archive of the child’s recordings.

### Cloud AI receives only what is necessary

For script understanding, send script text rather than child voice.

### Explicit opt-in for enhanced cloud speech

Do not silently upload microphone data.

---

## 28. V1 scope

V1 consists of 14 product capabilities:

1. Create Show
2. Camera Scan
3. Photo Import
4. PDF Import
5. Text / Paste Import
6. OCR Review
7. AI Script Parsing
8. Character Detection
9. Assign Child Role(s)
10. Listen
11. Read
12. Repeat
13. Practice
14. Off Book + Progress Tracking

---

## 29. Explicit V1 non-goals

V1 does **not** include:

- AI free chat;
- AI acting coach;
- emotion scoring;
- acting-quality scoring;
- pronunciation curriculum;
- singing pitch scoring;
- harmony analysis;
- dance instruction;
- AI performance-video generation;
- realtime multiplayer video rehearsal;
- social feed;
- public profiles;
- public content community;
- competitive leaderboard;
- script generation;
- automatic script rewriting;
- child voice cloning.

---

## 30. Musical theatre boundary

V1 schema supports:

- Song
- Lyrics

V1 interaction may:

- display lyrics;
- read or play through lyrics;
- support repeat practice.

Later versions may add:

- backing tracks;
- guide vocals;
- tempo control;
- pitch tracking;
- rhythm tracking;
- harmony practice.

Do not block the data architecture from supporting musicals later.

---

## 31. Director flow

```text
Create Show
    ↓
Import / Scan Script
    ↓
OCR / Text Extraction
    ↓
AI Structure
    ↓
Review Script
    ↓
Review Characters
    ↓
Assign Child Role(s)
    ↓
Ready to Practice
```

Target product KPI:

> **Time to First Practice < 3 minutes** for a normal short child script.

---

## 32. Child flow

```text
My Role
   ↓
Listen
   ↓
Read
   ↓
Repeat
   ↓
Practice
   ↓
Off Book
   ↓
Ready to Perform
```

This sequence is recommended, not locked.

The child may enter Practice directly.

---

## 33. iPad and iPhone strategy

### iPad

Primary design canvas.

Priority:

- landscape Practice Player;
- side-by-side context;
- large dialogue space;
- generous controls.

### iPhone

Responsive companion layout.

Use:

- single-column content;
- collapsed cast context;
- same practice engine;
- same data model.

Do not create an iPhone-first UI and merely stretch it to iPad.

---

## 34. Product metrics

### 34.1 Time to First Practice

How long from opening a new paper / PDF script to beginning usable practice.

V1 target:

**< 3 minutes**

### 34.2 Practice Completion

Measure whether the child completes scenes, not merely opens the app.

### 34.3 Off-book Rate

Suggested North Star:

```text
Mastered child lines / total assigned child lines
```

This directly measures the product's learning outcome.

---

## 35. Architecture summary

```text
iPad / iPhone
│
├── VisionKit
├── Vision OCR
├── PDFKit
├── Apple Speech
├── AVSpeechSynthesizer
├── Local line-matching engine
├── Local progress engine
│
└── Cloud API
    └── Script Intelligence Model
        ├── structure
        ├── characters
        ├── dialogue
        ├── scenes
        ├── stage directions
        └── songs / lyrics
```

Optional future services:

```text
Expressive TTS
Enhanced cloud transcription
Realtime acting coach
Video generation
```

---

## 36. Product principle summary

The defining principle is:

> **AI handles complexity behind the scenes; the child experiences a simple interactive rehearsal partner.**

The left side of the product may be technically complex:

- OCR
- parsing
- structured data
- character inference
- speech technology

The Child should experience only:

> **“Let’s practice my part.”**
