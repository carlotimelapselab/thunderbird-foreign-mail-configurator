#!/bin/zsh
# =====================================================================
#  setup-repo (macOS) - carica/aggiorna i file sul repo GitHub
#  Mettilo nella STESSA cartella dove hai estratto i file del repo
#  (aggiorna.ps1, profilo.enc, launcher/, ...). Doppio clic per pubblicare.
#  Riusabile: rilancialo ogni volta che vuoi aggiornare il repo.
# =====================================================================
cd "$(dirname "$0")"
REPO_URL="https://github.com/carlotimelapselab/thunderbird-foreign-mail-configurator.git"
MSG="${1:-Aggiorna configuratore caselle Thunderbird}"

echo "=========================================================="
echo "   PUBBLICAZIONE REPO su GitHub"
echo "   $REPO_URL"
echo "=========================================================="

if ! command -v git >/dev/null 2>&1; then
  echo "git non e' installato. Installa gli strumenti da riga di comando:"
  echo "   xcode-select --install"
  printf "Premi INVIO per chiudere..."; read -r _ </dev/tty; exit 1
fi

# .gitignore (evita file inutili/backup)
cat > .gitignore <<'G'
.DS_Store
*.bak-*
tl_*
G

# se e' presente 'gh' autenticato, configura le credenziali git
if command -v gh >/dev/null 2>&1; then
  gh auth setup-git >/dev/null 2>&1 || true
fi

# init / remote
if [ ! -d .git ]; then
  git init -q
fi
if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "$REPO_URL"
else
  git remote add origin "$REPO_URL"
fi

git add -A
git commit -q -m "$MSG" 2>/dev/null || echo "(nessuna modifica nuova da salvare)"
git branch -M main 2>/dev/null || true

echo ""
echo "Invio a GitHub (push)..."
if git push -u origin main 2>/tmp/tl_gitpush.err; then
  echo ""; echo "FATTO. Repo pubblicato/aggiornato."
else
  if grep -qiE 'rejected|fetch first|non-fast-forward|unrelated' /tmp/tl_gitpush.err; then
    echo "Il repo remoto ha gia' dei file: li unisco e riprovo..."
    git pull --rebase origin main --allow-unrelated-histories 2>/dev/null \
      || git pull --no-rebase --no-edit origin main --allow-unrelated-histories
    if git push -u origin main; then
      echo ""; echo "FATTO. Repo pubblicato/aggiornato."
    else
      echo "Push ancora fallito. Vedi messaggio sopra."
    fi
  else
    echo "--- Errore durante il push ---"
    cat /tmp/tl_gitpush.err
    echo ""
    echo "Probabile problema di autenticazione GitHub. Opzioni:"
    echo "  * Installa/usa 'gh':   brew install gh && gh auth login"
    echo "  * Oppure quando chiede la password, incolla un Personal Access Token"
    echo "    (GitHub -> Settings -> Developer settings -> Tokens)."
    echo "Poi rilancia questo script."
  fi
fi
echo ""
printf "Premi INVIO per chiudere..."; read -r _ </dev/tty
