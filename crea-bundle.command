#!/bin/zsh
# =====================================================================
#  crea-bundle (macOS) - rigenera profilo.enc dal TUO Thunderbird
#  Da lanciare quando modifichi le caselle (nuovo dominio, firma, ecc.):
#  impacchetta il profilo, lo cifra con la passphrase e crea profilo.enc,
#  che poi carichi (push) sul repo GitHub. Tutti i PC si aggiornano.
# =====================================================================
set -e
cd "$(dirname "$0")"
PROFILE_DIR_NAME="qajfqcsf.Timelapse Siti Esteri"

echo "=========================================================="
echo "   CREA-BUNDLE - profilo Thunderbird cifrato"
echo "=========================================================="

# 1. Thunderbird deve essere chiuso
while pgrep -x thunderbird >/dev/null 2>&1; do
  echo "Chiudi Thunderbird (Cmd+Q) per continuare..."; sleep 2
done

# 2. Trova il profilo (override con PROFILO=/percorso/al/profilo)
PROF="$PROFILO"
if [ -z "$PROF" ]; then
  for R in "$HOME/Library/Thunderbird" /Volumes/*/*/Library/Thunderbird; do
    [ -d "$R" ] || continue
    C="$(find "$R/Profiles" -maxdepth 1 -type d -name "$PROFILE_DIR_NAME" 2>/dev/null | head -1)"
    [ -n "$C" ] && PROF="$C" && break
  done
fi
if [ -z "$PROF" ] || [ ! -f "$PROF/prefs.js" ]; then
  echo "Profilo non trovato. Rilancia con:  PROFILO=\"/percorso/al/profilo\" ./crea-bundle.command"
  exit 1
fi
echo "Profilo: $PROF"

# 3. Passphrase (due volte)
printf "Scegli la passphrase: "; read -rs P1 </dev/tty; echo ""
printf "Ripeti la passphrase:  "; read -rs P2 </dev/tty; echo ""
if [ -z "$P1" ] || [ "$P1" != "$P2" ]; then echo "Le passphrase non coincidono o sono vuote."; exit 1; fi

# 4. Impacchetta (pulendo i path assoluti del Mac -> portabile)
TMP="$(mktemp -d /tmp/tl_mk.XXXXXX)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/profilo"
/usr/bin/perl -ne 'print unless /^user_pref\("(mail\.root\.(imap|none)|mail\.server\.server\d+\.directory|messenger\.save\.dir)",/' \
  "$PROF/prefs.js" > "$TMP/profilo/prefs.js"
cp -f "$PROF/key4.db" "$PROF/cert9.db" "$PROF/logins.json" "$TMP/profilo/"

( cd "$TMP" && tar czf profilo.tar.gz profilo )
openssl enc -aes-256-cbc -salt -pbkdf2 -iter 200000 -md sha256 \
  -pass pass:"$P1" -in "$TMP/profilo.tar.gz" -out "./profilo.enc"

# 5. Rigenera l'animazione del globo con i paesi ATTUALMENTE installati
if command -v python3 >/dev/null 2>&1 && [ -f "./crea-globe.py" ]; then
  echo ""
  # continenti reali: serve il pacchetto global-land-mask (installato una volta)
  if ! python3 -c "import global_land_mask" >/dev/null 2>&1; then
    echo "Installo la mappa dei continenti (una volta sola)..."
    python3 -m pip install --quiet global-land-mask >/dev/null 2>&1 || \
      echo "(mappa continenti non installata: uso silhouette semplificata)"
  fi
  python3 ./crea-globe.py "$PROF/prefs.js" || echo "(globo non rigenerato)"
fi

echo ""
echo "OK -> creati ./profilo.enc e ./globe.txt"
echo "Ora pubblica su GitHub (doppio clic su setup-repo.command, oppure):"
echo "   git add profilo.enc globe.txt && git commit -m \"aggiorna\" && git push"
echo ""
printf "Premi INVIO per chiudere..."; read -r _ </dev/tty
