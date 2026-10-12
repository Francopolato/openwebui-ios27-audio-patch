@echo off
rem ============================================================
rem  RIPRISTINA il chunk DUmjoMyK.js del build 0.11.4 allo stato
rem  originale, annullando la patch audio v16 per iOS 27.
rem  Copia il file .orig sopra quello patchato.
rem  Dopo: chiudi completamente Safari e riapri in finestra privata.
rem ============================================================
title Ripristina patch audio v16 (build 0.11.4)
setlocal
set "CHUNKS=D:\open-webui\.venv\Lib\site-packages\open_webui\frontend\_app\immutable\chunks"
copy /Y "%CHUNKS%\DUmjoMyK.js.orig" "%CHUNKS%\DUmjoMyK.js"
if %errorlevel%==0 (
    echo.
    echo RIPRISTINO COMPLETATO: chunk attivo tornato originale.
) else (
    echo ERRORE: file .orig non trovato.
)
echo.
pause
endlocal

