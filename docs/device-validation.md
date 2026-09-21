# Device acceptance checklist

Run on an iPad in landscape and portrait, and an iPhone in portrait. Automated tests cannot establish microphone quality, camera OCR accuracy or suitability for children.

## Local flow

- Launch offline. Verify the original sample and all five modes are available.
- Director gate: authenticate, cancel, fail the question, succeed; background the app and verify child mode on return.
- Import photographed pages and an existing photo, an ordinary text PDF, a scanned PDF and pasted English/Chinese text. Verify extracted text remains editable and no cloud connection occurs by default.
- Rename scenes, fix attribution, merge aliases, split a character, change dialogue to lyrics, move a line to another scene, reorder and remove noise.
- Select two roles, confirm, return to child mode and verify both roles belong to the child.
- Save a draft, kill/relaunch, confirm it remains a draft and cannot enter rehearsal.
- Delete a show and relaunch; verify it is gone.

## Rehearsal and learning

- Listen: each character has an identifiable voice; the visible word follows actual speech.
- Read: other voices play; own line remains visible; success advances.
- Repeat: demonstration comes first; retry/continue stays under the learner’s control.
- Practice: verify both text-visible and text-hidden settings.
- Off Book: no full child line leaks through text or VoiceOver; reveal first word, three words, then full line.
- A paraphrase such as “Go away” for “Get out of here” does not pass as memorized.
- Manual Next and hinted/read/repeated lines never earn mastery. Three unprompted successes across two sessions do.
- Edit a learned line and verify its progress resets.
- Finish a scene and return to progress. Replay and reopen mid-scene to verify the bookmark.

## Interruptions and privacy

- Deny microphone and speech permissions; verify manual practice remains usable.
- Test a language/device without on-device speech support; verify no cloud fallback and a helpful message.
- Disconnect headphones, receive an interruption, background/lock the device and navigate away during TTS and recognition. Audio must stop and no stale callback may advance a later line.
- Try a long silence, slow delivery, background noise and a wrong line; retry must work without duplicate attempts.
- Inspect application files/network traffic: no saved recordings/transcripts or microphone uploads.
- Configure the optional HTTPS parser; cancel upload consent, then grant it. Only approved text goes out. Try invalid token, network timeout, malformed provider output and unavailable provider; local parsing remains available.

## Accessibility and distribution

- Largest Dynamic Type, VoiceOver and Reduce Motion; check player controls remain reachable on smaller iPhones.
- Check contrast on physical displays, particularly red CTA text and inactive cast labels.
- Validate deployed privacy policy, provider retention and App Store privacy answers; the bundled manifest includes optional uploaded script content conservatively.
- Set the final bundle ID, signing team, production authorization and deployment settings before Archive/TestFlight.

Record device, OS, locale, date, result and any defects in the PR. Leave unchecked until actually exercised.
