# Patch audio iOS 27 — Open WebUI (build 0.11.4)

Documentazione della patch che rende funzionante la **modalità vocale (call)** su iPhone con iOS 27: senza patch l'audio non viene riprodotto; con le prime versioni si sentivano scoppiettii. La v10 risolve entrambi i problemi.

## Problema

Su iOS/Safari, la call feature di Open WebUI ha due blocchi:

1. **Autoplay policy**: `#audioElement.play()` chiamato fuori da un gesto utente viene bloccato → nessun audio.
2. **Sessione audio**: durante la registrazione del microfono WebKit usa il percorso "comunicazione" (bassa qualità) → scoppiettii nella riproduzione TTS. Se la sessione è forzatamente `playback`, invece, `getUserMedia` fallisce con `InvalidStateError`.

## Patch v10 (attuale) — comportamento

- **Unlock al primo tap**: `AudioContext` creato/resumed + priming silenzioso nativo su `#audioElement` dentro il gesto.
- **Sessione `speech-recognition`** quando si attiva la voice mode (fallback automatico a `play-and-record` se non accettata), ripristino a `playback` alla chiusura della call.
- **Riproduzione TTS via Web Audio pulita**: `decodeAudioData` del file completo → `BufferSource` → destination (niente streaming = niente artefatti).
- **Microfono in pausa durante la riproduzione** TTS e riaperto subito dopo: è questo che elimina gli scoppiettii (barge-in disabilitato mentre l'audio suona).
- **Diagnosi remota**: piccoli `GET /d?...` nel log del server per verificare cosa succede sul dispositivo.

## File nella cartella chunks

```
...\open_webui\frontend\_app\immutable\chunks\DUmjoMyK.js            ← chunk attivo (v10 applicata)
...\chunks\DUmjoMyK.js.orig                                          ← backup originale build 0.11.4
...\chunks\DUmjoMyK.js.patched-v10                                  ← file patchato v10
```

Riferimenti storici (build 0.11.3, chunk `zKJlHFgk.js`) lasciati nella stessa cartella come `.orig`/`.patched`/`.patched-v2`, più i bat vecchi in `vecchio-build-0.11.3\`.

## Uso

- `RIMETTI-patch-audio-v10.bat` → rimette la patch sul chunk attivo
- `RIPRISTINA-patch-audio-v10.bat` → ripristina l'originale

⚠️ Dopo ogni modifica: **chiudere completamente Safari** e riaprire in finestra privata. I chunk Vite sono serviti con cache "immutable": un tab aperto continua a eseguire la copia in memoria, anche in privato se non svuoti i dati sito.

⚠️ Ad ogni upgrade di Open WebUI il frontend viene rebuilt: i nomi dei chunk cambiano hash → la patch va riapplicata al nuovo chunk equivalente (la v10 è legata al build 0.11.4).

## Marker di diagnosi (log server)

| Marker | Significato |
|---|---|
| `GET /d?s=Y` | `navigator.audioSession` supportata al tap voice mode |
| `GET /d?t=sr` / `?t=pr` | tipo di sessione impostato (speech-recognition / play-and-record) |
| `GET /d?e=<nome>` | errore getUserMedia con nome eccezione |
| `GET /d?w=ok` | riproduzione Web Audio partita |
| `GET /d?r=<errore>` | restart microfono post-riproduzione fallito |

## Storico versioni

| Versione | Idea | Esito |
|---|---|---|
| v1 (0.11.3) | unlock + Web Audio API per la riproduzione | audio ok ma **scoppiettii** |
| v2 (0.11.3) | solo unlock + priming silenzioso, playback nativo | pulita ma su iOS 27 call mode non riproduceva |
| v3 | bootstrap globale, sessione `playback` | `InvalidStateError` su getUserMedia |
| v4 | `play-and-record` durante call, ripristino immediato | bug sintassi (if in catena a virgole) → chunk rotto; poi capture silenzioso |
| v5 | `play-and-record` per tutta la call, ripristino allo stop | call funzionante, playback muto (routing comunicazione) |
| v6 | priming dell'`#audioElement` dentro il gesto del tap voice mode | play() ok ma audio non udibile durante call |
| v7 | + diagnosi remota via fetch loggati | confermato `p=ok` con silenzio → routing, non policy |
| v8 | riproduzione Web Audio pulita (decode completo) | **audio udibile** ma scoppiettii |
| v9 | sessione `speech-recognition` durante call | ancora scoppiettii |
| **v10** | mic in pausa durante la riproduzione + restart dopo | **funziona, audio pulito** ✅ |

## GitHub

Repo: https://github.com/Francopolato/openwebui-ios27-audio-patch

