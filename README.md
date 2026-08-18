# Thunderbird — Configuratore caselle estere (TimelapseLab)

Sistema di **installazione e aggiornamento** delle caselle `info@timelapse.*` in
Thunderbird, con **password già incluse**. Ogni PC ha un piccolo *launcher fisso*;
la logica e i dati stanno **online in questo repo**. Modifichi qui una volta →
tutti i computer si aggiornano al prossimo lancio.

## Come funziona

- `profilo.enc` — il profilo Thunderbird completo (account, nomi, firme, **password**),
  **cifrato AES-256** con una passphrase. È sicuro anche se il repo è pubblico:
  senza passphrase non è leggibile.
- `aggiorna.ps1` / `aggiorna.command` — lo script che scarica `profilo.enc`, chiede la
  passphrase, lo decifra e installa il profilo (Windows / macOS).
- `launcher/Aggiorna-Timelapse.bat` / `.command` — il **file fisso** da mettere su ogni PC:
  scarica ed esegue lo script online più recente.
- `crea-bundle.command` — (solo tu, su Mac) rigenera `profilo.enc` dopo che hai
  modificato le caselle nel tuo Thunderbird.

## Setup iniziale del repo (una volta)

Carica su GitHub, nel branch `main`, tutti questi file mantenendo la struttura:

```
aggiorna.ps1
aggiorna.command
crea-bundle.command
crea-globe.py
profilo.enc
globe.txt
setup-repo.command
launcher/Aggiorna-Timelapse.bat
launcher/Aggiorna-Timelapse.command
README.md
```

## Animazione (logo + globo)

All'avvio l'updater mostra un'intro ASCII: il logo **TIMELAPSE** (bianco) **MONDO**
(blu) sopra un **globo terrestre** che ruota, con i **continenti reali** disegnati in
verde e **illuminati in giallo i paesi dove abbiamo un dominio**.
I fotogrammi sono generati da `crea-globe.py` → `globe.txt` (72 frame, 31 righe l'uno).
La mappa dei continenti usa il pacchetto Python `global-land-mask`, che `crea-bundle.command`
installa automaticamente la prima volta (se manca, il globo usa una silhouette semplificata).

- **Ogni volta che aggiungi/togli caselle**, `crea-bundle.command` **rigenera** anche
  `globe.txt` dai domini realmente installati: i nuovi paesi si accendono da soli.
- Se un dominio ha un ccTLD **nuovo** senza coordinate, `crea-globe.py` te lo **segnala**:
  aggiungi la riga `'xx':(lat,lon),` nel dizionario `COORD` dentro `crea-globe.py` e rilancia.
- L'animazione richiede un terminale che supporti i colori (Windows Terminal / PowerShell
  su Win10+, Terminale macOS). Se non è supportata, viene semplicemente saltata.

> La passphrase **non** va messa nel repo. La condividi con i colleghi a voce / in un
> canale sicuro (una sola volta).

## Sui PC dei colleghi (una volta)

1. Copia sul PC il launcher giusto: **Windows** → `Aggiorna-Timelapse.bat`,
   **Mac** → `Aggiorna-Timelapse.command` (rendilo eseguibile: `chmod +x Aggiorna-Timelapse.command`).
2. Assicurati che Thunderbird sia stato **aperto almeno una volta** (così esiste il suo profilo).
3. **Chiudi Thunderbird.**

## Per installare / aggiornare (ogni volta)

1. Chiudi Thunderbird.
2. Doppio clic sul launcher.
   - Windows: se compare "Windows ha protetto il PC" → *Ulteriori informazioni* → *Esegui comunque*.
   - Mac: la prima volta, **tasto destro → Apri** (per superare Gatekeeper).
3. Inserisci la **passphrase** quando richiesta.
4. Riapri Thunderbird. Al primo accesso a un server può chiedere **una volta** di
   accettare il certificato: accetta. La password **non** viene chiesta.

## Quando modifichi qualcosa (solo tu, sul Mac principale)

1. Modifica le caselle nel tuo Thunderbird (nuovo dominio, firma, ecc.) e **chiudilo**.
2. Doppio clic su `crea-bundle.command` → inserisci la passphrase → crea `profilo.enc`.
   - Se il profilo è su un disco esterno, lancia così:
     `PROFILO="/Volumes/.../Profiles/qajfqcsf.Timelapse Siti Esteri" ./crea-bundle.command`
3. Push su GitHub: `git add profilo.enc && git commit -m "aggiorna" && git push`.
4. I colleghi rilanciano il loro launcher: prendono la versione nuova.

## Note

- **Non serve reinstallare il launcher** quando cambi qualcosa: il launcher è fisso e
  scarica sempre l'ultima versione online.
- Sul **tuo** Mac (profilo su disco esterno) l'aggiornamento automatico non serve: è già
  configurato. Se un giorno vuoi usarci anche lui, lancia l'updater con
  `TB_DIR="/Volumes/.../Library/Thunderbird"`.
- **Sicurezza:** la passphrase protegge TUTTE le password delle caselle. Se cambi la
  passphrase, rigenera `profilo.enc` con `crea-bundle` e comunica la nuova ai colleghi.
- Requisiti: Windows 10 1803+ (per `tar` e .NET), macOS con Thunderbird installato.
- Ogni installazione fa un **backup** dei file esistenti (`.bak-<data>`).
