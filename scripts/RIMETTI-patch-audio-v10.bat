@echo off
rem ============================================================
rem  RIMETTE la patch audio v10 - build 0.11.4 (chunk DUmjoMyK.js).
rem  iOS 27: unlock al primo tap + sessione speech-recognition
rem  durante la call + playback Web Audio pulito con mic in pausa
rem  mentre la TTS viene riprodotta.
rem  DOPO: chiudi completamente Safari e riapri in finestra privata
rem  (i chunk Vite sono "immutable": senza cache nuova il telefono
rem  continua a eseguire il file vecchio).
rem ============================================================
title Rimetti patch audio v10 (build 0.11.4)
setlocal
set "CHUNKS=D:\open-webui\.venv\Lib\site-packages\open_webui\frontend\_app\immutable\chunks"
copy /Y "%CHUNKS%\DUmjoMyK.js.patched-v10" "%CHUNKS%\DUmjoMyK.js"
if %errorlevel%==0 (
    echo.
    echo PATCH v10 RIMESSA: chunk attivo = versione patchata.
) else (
    echo ERRORE: file .patched-v10 non trovato.
)
echo.
pause
endlocal
