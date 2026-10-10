# Patch audio iOS 27 — Open WebUI (build 0.11.4)

Patch che rende funzionante la **modalità vocale (call)** di Open WebUI su iPhone con iOS 27. Senza patch l'audio TTS non viene riprodotto; le prime versioni della patch erano udibili ma pieni di scoppiettii. La v10 risolve entrambi i problemi: audio pulito e microfono funzionante durante la conversazione.

Versione inglese: [README.md](README.md)

## Il problema

Su iOS/Safari la call feature di Open WebUI ha due blocchi:

1. **Autoplay policy**: `#audioElement.play()` chiamato fuori da un gesto utente viene bloccato → nessun audio.
2. **Qualità della sessione audio**: mentre il microfono cattura, WebKit instrada l'uscita nel percorso "comunicazione" (bassa qualità) → scoppiettii nella riproduzione TTS. Forzare una sessione solo `playback`, invece, fa fallire `getUserMedia` con `InvalidStateError`.

## Come funziona la v10

- **Unlock al primo tap**: `AudioContext` creato/resumed + priming silenzioso nativo su `#audioElement`, dentro il gesto utente.
- **Sessione `speech-recognition`** quando si attiva la voice mode (fallback automatico a `play-and-record` se non accettata), ripristino a `playback` alla chiusura della call.
- **Riproduzione Web Audio pulita**: `decodeAudioData` del file completo → `BufferSource` → destination (niente streaming, niente artefatti).
- **Microfono in pausa durante la riproduzione TTS** e riaperto subito dopo: è questo che elimina gli scoppiettii (barge-in disabilitato mentre l'audio suona).
- **Diagnosi remota**: piccoli `GET /d?...` visibili nel log del server.

## Contenuto del repo

```
ios-audio-unlock.js                 bootstrap da appendere alla fine del chunk (da solo NON basta)
patched/DUmjoMyK.js.patched-v10     chunk completo già patchato per il build 0.11.4 (bootstrap + i 4 edit)
scripts/RIMETTI-patch-audio-v10.bat copia il file patchato sul chunk attivo (Windows, installazione di riferimento)
scripts/RIPRISTINA-patch-audio-v10.bat ripristina il chunk originale dal .orig
README.md / README.it.md            documentazione in inglese / italiano
```

## Uso

**Opzione A — file patchato pronto (più semplice).** Nella cartella chunks del frontend (`.../site-packages/open_webui/frontend/_app/immutable/chunks/`), copia `patched/DUmjoMyK.js.patched-v10` sopra il chunk attivo `DUmjoMyK.js`. I `.bat` fanno esattamente questo per il percorso di installazione di riferimento `D:\open-webui`; adatta i percorsi se la tua installazione è altrove. Tieni un backup del chunk originale prima di sovrascrivere.

**Opzione B — patch manuale su un build nuovo.** Trova il chunk che contiene l'handler della voice mode (cerca `Permission denied when accessing media devices`), applica i 4 edit seguenti e appenda il contenuto di `ios-audio-unlock.js` alla fine del file. I nomi dei chunk cambiano a ogni rebuild, quindi vanno riindividuati dopo gli upgrade.

1. **Handler click voice mode** — aggiungi unlock + sessione prima di `getUserMedia`:
   ```js
   // prima: try{let Pt=await navigator.mediaDevices.getUserMedia({audio:!0});...
   // dopo:  try{window.__owUnlock&&window.__owUnlock(document.getElementById("audioElement"));
   //         if("audioSession"in navigator)try{navigator.audioSession.type="speech-recognition"}catch(e){try{navigator.audioSession.type="play-and-record"}catch(e2){}};
   //         let Pt=await navigator.mediaDevices.getUserMedia({audio:!0});...
   ```
2. **Catch errore** — mostra il nome dell'eccezione (e beacon): `catch(__e){_t.error(...+" ["+((__e&&__e.name)||"?")+"]");fetch("/d?e="+((__e&&__e.name)||"?"))}`
3. **Handler di stop della call** — ripristina la sessione all'inizio: `if("audioSession"in navigator)try{navigator.audioSession.type="playback"}catch(e){};`
4. **Funzione di riproduzione TTS** — sostituisci il blocco `play()` dell'elemento con il percorso Web Audio (decode completo → BufferSource → destination), mettendo in pausa i track del microfono durante la riproduzione e riavviando la registrazione alla fine; l'elemento nativo resta come fallback. Il codice esatto è nel file patchato.

Dopo la patch: **chiudere completamente Safari** e riaprire in finestra privata (o svuotare i dati sito) — i chunk Vite sono serviti con cache "immutable", quindi un tab aperto continua a eseguire la copia vecchia. La patch è legata al build **0.11.4**; ogni upgrade rebuilta il frontend e richiede di riapplicarla al nuovo chunk.

## Marker di diagnosi (log server)

| Marker | Significato |
|---|---|
| `GET /d?s=Y` | `navigator.audioSession` supportata quando si attiva la voice mode |
| `GET /d?t=sr` / `?t=pr` | tipo di sessione impostato (speech-recognition / play-and-record) |
| `GET /d?e=<nome>` | errore getUserMedia con nome eccezione |
| `GET /d?w=ok` | riproduzione Web Audio partita |
| `GET /d?r=<errore>` | restart microfono post-riproduzione fallito |

## Storico versioni

| Versione | Idea | Esito |
|---|---|---|
| v1 (0.11.3) | unlock + Web Audio API per la riproduzione | udibile ma scoppiettii |
| v2 (0.11.3) | solo unlock + priming silenzioso, playback nativo | pulita ma su iOS 27 call mode non riproduceva |
| v3 | bootstrap globale, sessione `playback` | `InvalidStateError` su getUserMedia |
| v4 | `play-and-record` durante call, ripristino immediato | bug sintassi; poi capture silenzioso |
| v5 | `play-and-record` per tutta la call, ripristino allo stop | call funzionante, playback muto (routing comunicazione) |
| v6 | priming dentro il gesto del tap voice mode | play() ok ma audio non udibile durante call |
| v7 | + diagnosi remota via fetch loggati | confermato `p=ok` con silenzio → routing, non policy |
| v8 | riproduzione Web Audio pulita (decode completo) | **udibile** ma scoppiettii |
| v9 | sessione `speech-recognition` durante call | ancora scoppiettii |
| **v10** | mic in pausa durante la riproduzione + restart dopo | **funziona, audio pulito** ✅ |
