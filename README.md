# iOS 27 audio patch — Open WebUI (build 0.11.4)

Patch that makes Open WebUI **voice mode (call)** work on iPhone with iOS 27. Without the patch, TTS audio is not played at all; early patch versions were audible but full of crackling/popping artifacts. This version (v10) fixes both problems: audio plays clean, and the microphone works during the conversation.

Italian version: [README.it.md](README.it.md)

## The problem

On iOS/Safari, Open WebUI's call feature hits two walls:

1. **Autoplay policy** — `#audioElement.play()` called outside a user gesture is blocked → no audio at all.
2. **Audio session quality** — while the microphone is capturing, WebKit routes output through the low-quality "communication" path → crackling during TTS playback. Forcing a `playback`-only session instead makes `getUserMedia` fail with `InvalidStateError`.

## How v10 works

- **Unlock on first tap**: `AudioContext` created/resumed + native silent priming of `#audioElement`, inside the user gesture.
- **`speech-recognition` session** when voice mode is activated (automatic fallback to `play-and-record` if not accepted), restored to `playback` when the call ends.
- **Clean Web Audio playback**: full-file `decodeAudioData` → `BufferSource` → destination (no streaming, no artifacts).
- **Microphone paused during TTS playback** and resumed right after — this is what eliminates crackling (barge-in is disabled while the answer is playing).
- **Remote diagnostics**: small `GET /d?...` beacons visible in the server access log.

## Repository contents

```
ios-audio-unlock.js                 bootstrap to append at the end of the chunk (alone it is NOT enough)
patched/DUmjoMyK.js.patched-v10     full patched chunk for build 0.11.4 (bootstrap + the 4 edits already applied)
scripts/RIMETTI-patch-audio-v10.bat copies the patched file over the active chunk (Windows, this install)
scripts/RIPRISTINA-patch-audio-v10.bat restores the original chunk from .orig
README.md / README.it.md            documentation in English / Italian
```

## Usage

**Option A — ready-made patched file (easiest).** In your Open WebUI frontend chunks folder (`.../site-packages/open_webui/frontend/_app/immutable/chunks/`), copy `patched/DUmjoMyK.js.patched-v10` over the active chunk `DUmjoMyK.js`. The `.bat` scripts do exactly this for the reference install path `D:\open-webui`; adjust the paths if your installation is elsewhere. Keep a backup of the original chunk before overwriting.

**Option B — manual patch on a fresh build.** Find the chunk containing the voice-mode handler (search for `Permission denied when accessing media devices`), apply these 4 edits, then append the content of `ios-audio-unlock.js` at the end of the file. Chunk names change with every rebuild, so re-locate them after upgrades.

1. **Voice-mode click handler** — add unlock + session before `getUserMedia`:
   ```js
   // before: try{let Pt=await navigator.mediaDevices.getUserMedia({audio:!0});...
   // after:  try{window.__owUnlock&&window.__owUnlock(document.getElementById("audioElement"));
   //         if("audioSession"in navigator)try{navigator.audioSession.type="speech-recognition"}catch(e){try{navigator.audioSession.type="play-and-record"}catch(e2){}};
   //         let Pt=await navigator.mediaDevices.getUserMedia({audio:!0});...
   ```
2. **Error catch** — show the exception name (and beacon): `catch(__e){_t.error(...+" ["+((__e&&__e.name)||"?")+"]");fetch("/d?e="+((__e&&__e.name)||"?"))}`
3. **Call stop handler** — restore session at the beginning: `if("audioSession"in navigator)try{navigator.audioSession.type="playback"}catch(e){};`
4. **TTS playback function** — replace the element `play()` block with the Web Audio route (full decode → BufferSource → destination), pausing mic tracks during playback and restarting recording on end; native element as fallback. See the patched file for the exact code.

After patching: **fully quit Safari** and reopen in a private window (or clear site data) — Vite chunks are served with "immutable" cache, so an open tab keeps running the old copy. The patch is tied to build **0.11.4**; every upgrade rebuilds the frontend and requires re-applying it to the new chunk.

## Diagnostic markers (server log)

| Marker | Meaning |
|---|---|
| `GET /d?s=Y` | `navigator.audioSession` supported when voice mode is activated |
| `GET /d?t=sr` / `?t=pr` | session type actually set (speech-recognition / play-and-record) |
| `GET /d?e=<name>` | getUserMedia error with exception name |
| `GET /d?w=ok` | Web Audio playback started |
| `GET /d?r=<error>` | microphone restart after playback failed |

## Version history

| Version | Idea | Result |
|---|---|---|
| v1 (0.11.3) | unlock + Web Audio API playback | audible but crackling |
| v2 (0.11.3) | unlock + silent priming only, native playback | clean, but no playback in iOS 27 call mode |
| v3 | global bootstrap, `playback` session | `InvalidStateError` on getUserMedia |
| v4 | `play-and-record` during call, immediate restore | syntax bug; then silent capture |
| v5 | `play-and-record` for the whole call, restore at stop | call works, playback muted (communication routing) |
| v6 | priming inside the voice-mode tap gesture | play() succeeds but audio not audible during call |
| v7 | + remote diagnostics via logged fetches | confirmed `p=ok` with silence → routing issue, not policy |
| v8 | clean Web Audio playback (full decode) | **audible** but still crackling |
| v9 | `speech-recognition` session during call | still crackling |
| **v10** | mic paused during playback + restart after | **works, clean audio** ✅ |
