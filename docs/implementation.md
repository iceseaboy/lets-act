# Native V1 implementation

The original `design-language.md` and `product-spec.md` remain the requirements. This implementation targets iPad first and adapts to iPhone, using SwiftUI and iOS 17 as the deployment floor.

## Design implementation

`StageStyle.swift` defines warm ivory `#FAF7F2`, curtain red `#E65D5D`, dark text and six soft cast identity colors. Child pages use rounded system typography, 56-point controls and 20–28-point surfaces. The home centers one active show and its assigned roles. The player gives the active line the largest surface, with a cast rail on iPad and one column on iPhone. Underlined, heavier current words avoid multicolor karaoke. Reduced Motion disables line transitions; dialogue scales with Dynamic Type. Speaker names, text state and labels accompany color.

The illustration is a lightweight SwiftUI spotlight, not a remotely loaded dependency. The demonstration story is original sample content. No copyrighted show scripts are bundled.

## Feature map

| V1 requirement | Implementation |
| --- | --- |
| Create show / text import | Parent gate → Create a show → name and editable text |
| Camera scan | VisionKit document camera, multi-page capture |
| Photos | System PhotosPicker, multi-image import |
| PDF | PDFKit text extraction; Vision OCR for pages without text |
| OCR review | Editable text before structure; preserved original extracted text |
| AI script parsing | Optional authenticated HTTPS Node service, Responses strict JSON output, schema validation and bounded retry |
| Offline parsing | Conservative scene/speaker parser, always requiring director review |
| Script review | Edit text/type/speaker/scene; add/delete/reorder units; edit scene headings |
| Cast review | Names, line and scene counts, per-role system voices, confirmed merges, manual splits |
| Role assignment | Multiple assigned roles via `childRoles` array |
| Listen | All characters spoken by native TTS, word-range highlighting |
| Read | Other voices spoken; full child line; on-device recognition |
| Repeat | Child-line demonstration, own turn, retry/continue |
| Practice | Scene partner voices; own turn; optional full text |
| Off Book | Hidden child lines; first word → three words → full line hints |
| Progress | Local exact-word comparison; New/Learning/Remembered/Mastered; scene readiness |
| Parent gate | Device owner authentication with multiplication fallback; background closes director mode and pending verification |
| Persistence | Versioned atomic JSON, device file protection, load failure preserves original data |

An unavailable or denied recognition service falls back to manual Next. **Manual Next never claims success or mastery.** Skipping through a scene counts as completing its playback, not mastering its lines.

## Architecture

- `Core/`: Foundation-only models, validation, offline parser, matcher and mode state machine. The same sources are built by SwiftPM tests and the iOS app.
- `Services/`: Apple OCR/PDF/TTS/Speech adapters, rehearsal controller, storage and cloud parser client.
- `Design/`: visual tokens and shared components.
- `Views/`: child home, player, import, director, script editor, settings and progress.
- `server/`: optional text-only parsing service with no package dependencies.
- `scripts/generate_project.py`: deterministic Xcode project generator, with checked-in output.

## Behavioral details

Script matching normalizes case, width, accents and punctuation, preserves word order, and uses token edit distance. CJK ideographs are compared individually. Three-word-or-shorter cues require exact normalized matches; longer lines use age thresholds of 0.80 / 0.88 / 0.94. This is rehearsal assistance, not a pronunciation or acting assessment.

Mastery defaults to three successful unprompted attempts across two sessions. A new session starts on entering a player. Read/repeat/full-text practice/hints/demonstrations cannot earn unprompted credit. Every save reconciles progress: editing a line’s text, type or speaker clears that line’s old progress; deleting or moving a bookmarked line clears the stale position. Settings can raise mastery thresholds. Persisted attempts contain only date, session ID, score, success and prompt status: no transcript or audio.

Recognition always requires on-device support. It never silently invokes cloud transcription. A 1.8-second quiet interval after a changed transcript ends a turn, with a 45-second upper bound. Younger children may need to retry if a long thinking pause ends a turn. Interruption, app inactivity and headphone removal stop audio; resuming restarts the current line. Voice selection uses installed voices, with pitch differences as a fallback where voice inventory is limited.

The sample opens ready to practice. Imported shows are drafts until an adult explicitly confirms. Local heuristics do not claim to understand arbitrary script typography; ambiguous passages are reviewed and corrected by the director. AI proposals also remain drafts.

## Verification and release status

Verified on 2026-09-22 at code commit `b6245ff`: 13 Swift core tests and 6 Node service tests passed. The iOS Simulator build and all 5 UI tests passed on both iPad (landscape) and iPhone (portrait). The UI suite covers the real parent question/keyboard, rejected answers, text import, multiple roles, entering Off Book, hidden text, draft and confirmed-show persistence, and background relocking. Xcode results and screenshots are attached to [CI run 35670167607](https://github.com/iceseaboy/lets-act/actions/runs/35670167607). This is simulator validation; it does not substitute for the physical-device checklist.

This is an implementation for development and device evaluation, **not an App Store submission or signed installable IPA**. No Apple signing identity, provisioning profile, cloud deployment, real provider key or TestFlight access was supplied. Before release, complete `device-validation.md`, exercise the real parsing provider, review the app’s privacy labels/manifest against the deployed service, and replace private-pilot shared-token service authorization if enabling cloud parsing publicly.

No video generation, acting coach, voice cloning, public sharing or billing is included because those are outside the written V1 scope. UI localization beyond English, iCloud sync, backups/export UI and production multi-account cloud infrastructure are also not implemented.

## API references used

- [Apple on-device recognition requirement](https://developer.apple.com/documentation/speech/sfspeechrecognitionrequest/requiresondevicerecognition)
- [Apple TTS word-range callback](https://developer.apple.com/documentation/avfaudio/avspeechsynthesizerdelegate/speechsynthesizer(_:willspeakrangeofspeechstring:utterance:))
- [OpenAI structured outputs](https://developers.openai.com/api/docs/guides/structured-outputs)
