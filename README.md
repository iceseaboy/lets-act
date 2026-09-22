# Let's Act

Native SwiftUI application for **iPadOS 17+ and iOS 17+**. Includes the child rehearsal experience, a protected director area, on-device import/speech services, and an optional script-understanding backend.

## Run the app

1. Open `ios/LetsAct.xcodeproj` in Xcode 16 or later.
2. Select the **LetsAct** scheme and an iPad simulator, then Run.
3. The original sample show **The Little Star** is ready to rehearse. Open the lock button to import your own script and assign roles.
4. To run on an iPad/iPhone, set your Apple development team and a unique bundle identifier in Signing & Capabilities. Microphone, local speech recognition, camera scanning and biometrics require device testing.

No third-party iOS packages or cloud credentials are needed for local rehearsal. English UI; English and Simplified Chinese script recognition presets. The app does not implement video generation, voice cloning, scoring of acting quality, or any other V1 non-goal.

## Development

```sh
swift test
node --test server/test/*.test.mjs
python3 scripts/generate_project.py   # after adding/removing Swift source files
xcodebuild -project ios/LetsAct.xcodeproj -scheme LetsAct \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```

The generated Xcode project is checked in, so no project-generation tools are needed to open it. CI runs the same end-to-end UI tests on iPad in landscape and iPhone in portrait, and preserves a separate Xcode result bundle with screenshots for each device. Tests cover parent verification, import and role assignment, off-book text hiding, relaunch persistence, draft restrictions, and background relocking.

- [Implementation, feature map and release gates](docs/implementation.md)
- [Optional parsing service setup](server/README.md)
- [Device acceptance checklist](docs/device-validation.md)

---

Let's Act is an iPad-first, iPhone-compatible interactive drama practice app for children aged 3–14.

Its purpose is simple:

> Help a child learn and master a role through interactive practice.

The product turns a static script into a guided role-learning experience:

**Script → My Role → Learn → Practice → Remember → Perform**

## Product roles

- **Child** — learns and practices one or more assigned roles.
- **Director / Parent** — imports and reviews scripts, confirms characters, assigns the child's role, configures practice, and reviews progress.

## Documents

- [Design Language](docs/design-language.md)
- [Product Specification](docs/product-spec.md)

## Product principles

1. Design language before feature density.
2. One screen, one job.
3. Child experience stays simple; complexity belongs to Director / Parent.
4. Device-first processing wherever practical.
5. AI is used to understand content, not to control the product.
6. No child voice cloning.
7. No social feed, leaderboard, or open community in V1.
8. iPad is the primary design canvas; iPhone is a responsive companion experience.
