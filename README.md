# iOS 27 audio patch — Open WebUI (build 0.11.4)

Patch that makes Open WebUI **voice mode (call)** work on iPhone with iOS 27. Without the patch, TTS audio is not played at all; early patch versions were audible but full of crackling/popping artifacts. This version (v10) fixes both problems: audio plays clean, and the microphone works during the conversation.

Italian version: [README.it.md](README.it.md)

## The problem

On iOS/Safari, Open WebUI's call feature hits two walls:

1. **Autoplay policy** — `#audioElement.play()` called outside a user gesture is blocked → no audio at all.
2. **Audio session quality** — while the microphone is capturing, WebKit routes output through the low-quality "communication" path → crackling during TTS playback. Forcing a `playback`-only session instead makes `getUserMedia` fail with `InvalidStateError`.

## How v10 works

- **Unlock on first tap**: `AudioContext` created/resumed + native silent priming of `#audioElement`, inside the user gesture (see [`ios-audio-unlock.js`](ios-audio-unlock.js)).
- **`speech-recognition` session** when voice mode is activated (automatic fallback to `play-and-record` if not accepted), restored to `playback` when the call ends.
- **Clean Web Audio playback**: full-file `decodeAudioData` → `BufferSource` → destination (no streaming, no artifacts).
- **Microphone paused during TTS playback** and resumed right after — this is what eliminates crackling (barge-in is disabled while the answer is playing).
- **Remote diagnostics**: small `GET /d?...` beacons visible in the server access log to see what actually happens on the device.

## The 4 patch points (chunk `DUmjoMyK.js`)

1. Voice-mode click handler: priming + session type setting before `getUserMedia`.
2. Error catch: exception name appended to the toast (`[NotAllowedError]`, `[InvalidStateError]`, …) + diagnostic beacon.
3. Call stop handler: restores `audioSession.type = "playback"`.
4. TTS playback function: Web Audio route with mic pause during playback, native element as fallback, beacon on success/failure.

Plus the bootstrap appended at the end of the chunk (`ios-audio-unlock.js`).

## Diagnostic markers (server log)

| Marker | Meaning |
|---|---|
| `GET /d?s=Y` | `navigator.audioSession` supported when voice mode is activated |
| `GET /d?t=sr` / `?t=pr` | session type actually set (speech-recognition / play-and-record) |
| `GET /d?e=<name>` | getUserMedia error with exception name |
| `GET /d?w=ok` | Web Audio playback started |
| `GET /d?r=<error>` | microphone restart after playback failed |

## Caveats

- Vite chunks are served with "immutable" cache: after patching, fully quit Safari and reopen in a private window (or clear site data), otherwise the device keeps running the old copy.
- Every Open WebUI upgrade rebuilds the frontend and chunk hashes change → the patch must be re-applied to the new equivalent chunk. This patch is tied to build **0.11.4**.

## Version history

| Version | Idea | Result |
|---|---|---|
| v1 (0.11.3) | unlock + Web Audio API playback | audible but crackling |
| v2 (0.11.3) | unlock + silent priming only, native playback | clean, but no playback in iOS 27 call mode |
| v3 | global bootstrap, `playback` session | `InvalidStateError` on getUserMedia |
| v4 | `play-and-record` during call, immediate restore | syntax bug (if inside comma chain); then silent capture |
| v5 | `play-and-record` for the whole call, restore at stop | call works, playback muted (communication routing) |
| v6 | priming of `#audioElement` inside the voice-mode tap gesture | play() succeeds but audio not audible during call |
| v7 | + remote diagnostics via logged fetches | confirmed `p=ok` with silence → routing issue, not policy |
| v8 | clean Web Audio playback (full decode) | **audible** but still crackling |
| v9 | `speech-recognition` session during call | still crackling |
| **v10** | mic paused during playback + restart after | **works, clean audio** ✅ |
