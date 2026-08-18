#!/bin/zsh
# ====================================================================
#  Aggiorna-Timelapse (macOS) - LAUNCHER FISSO
#  Lascia questo file sul Mac. Doppio clic per aggiornare le caselle:
#  scarica ed esegue lo script piu' recente dal repo GitHub.
# ====================================================================
U="https://raw.githubusercontent.com/carlotimelapselab/thunderbird-foreign-mail-configurator/main/aggiorna.command"
T="/tmp/tl_aggiorna.command"
echo "Scarico l'aggiornamento piu' recente..."
if ! curl -fsSL "$U" -o "$T"; then
  echo ""; echo "Impossibile scaricare. Controlla la connessione a Internet."
  printf "Premi INVIO per chiudere..."; read -r _ </dev/tty; exit 1
fi
zsh "$T"
