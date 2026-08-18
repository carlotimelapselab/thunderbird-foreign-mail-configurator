@echo off
rem ====================================================================
rem  Aggiorna-Timelapse (Windows) - LAUNCHER FISSO
rem  Lascia questo file sul PC. Doppio clic per aggiornare le caselle:
rem  scarica ed esegue lo script piu' recente dal repo GitHub.
rem ====================================================================
setlocal
set "URL=https://raw.githubusercontent.com/carlotimelapselab/thunderbird-foreign-mail-configurator/main/aggiorna.ps1"
set "PS=%TEMP%\tl_aggiorna.ps1"
echo Scarico l'aggiornamento piu' recente...
powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; try{Invoke-WebRequest '%URL%' -OutFile '%PS%' -UseBasicParsing}catch{Write-Host ('Errore download: ' + $_.Exception.Message) -ForegroundColor Red; exit 1}"
if errorlevel 1 ( echo. & echo Impossibile scaricare. Controlla la connessione a Internet. & echo. & pause & exit /b 1 )
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS%"
del "%PS%" >nul 2>&1
endlocal
