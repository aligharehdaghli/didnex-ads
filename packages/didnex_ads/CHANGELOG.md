## 3.3.0

- Simple direct configuration with optional default Didnex origin.
- Full example covers all 11 formats, no-fill, lifecycle and manifests.
- Fullscreen lookup errors return false/null; inline missing scope renders a fallback.
- Play Integrity is optional: didnex.enablePlayIntegrity=true opts in.
- Host Gradle/AGP/Kotlin versions remain authoritative.

## 3.3.0

- Inherit the host AGP/Kotlin toolchain; support modern AGP 9 and built-in Kotlin.
- Require Flutter 3.44 / Dart 3.12, Android 24+, Java 17; update video_player and url_launcher.
- Return no-fill on service outages by default, bound request lifetimes, and back off repeated failures.
- Catch detached player futures and host callbacks; keep native preferences and larger JSON decoding off the UI thread.
- Explicit strictErrors opt-in for integration diagnostics.

## 2.0.0

- Playable templates with native Flutter rendering.
- Real adaptive MP4 source selection using native coarse network state.
- Redacted local SDK Inspector for debug/test devices.
- Existing direct/server, hosted rewards, consent and push APIs preserved.
- Mobile build/device validation remains required; no store/package publication claimed.

## 0.3.0 — 2026-10-22

- Rename the package and public types to Didnex, retaining all nine formats and existing server protocol.
- Provide a generated standalone madar_ads 0.2.2 compatibility distribution from the same source.

## 0.2.1 — 2026-10-22

- Forward coarse mobile/tablet/unknown form factor with optional explicit override.
- Keep all nine formats and full-screen/reward behavior; no device identifier added.
- Update publisher proxy to 2.2 for device-class forwarding and validation.

## 0.2.0 — 2026-10-22

- Nine typed formats and explicit SDK capabilities.
- One-use full-screen loader/show API for interstitial, app-open and rewarded formats.
- Optional reward offer, ordered timed playback, authenticated server claim and validated applied receipt.
- Independent image/video media parsing, preloaded renderer, runtime example format selection.
- Complete publisher backend, atomic digital reward SQL and integration guide.

## 0.1.0

- Installable Flutter package for Android/iOS: banner/native image and inline video.
- Publisher proxy authentication; no server API key in the app.
- Typed responses, HTTPS checks, bounded network reads and timeouts.
- Continuous viewability, lifecycle/route checks, signed and deduplicated events.
- Video controls, actual playback quartiles, expiry and cleanup.
- No-fill/error/loaded callbacks, diagnostic mode and experiment token forwarding.
- Unit/widget tests, runnable example, Persian integration guide and verification script.
- Replaces the earlier image-only source snippet; the legacy Dart file re-exports this package.
