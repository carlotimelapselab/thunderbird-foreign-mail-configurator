#!/bin/zsh
# =====================================================================
#  Aggiorna-Timelapse (macOS) - configuratore caselle estere Thunderbird
#  Scarica il profilo cifrato dal repo, lo decifra con la passphrase e
#  lo installa nel profilo Thunderbird "Timelapse Siti Esteri".
#  Eseguito online dal launcher fisso Aggiorna-Timelapse.command.
# =====================================================================
set -e
# --- non chiudere mai la finestra in silenzio: se qualcosa fallisce,
#     mostra riga ed errore e aspetta INVIO ------------------------------
ERRLINE=0; TMP=""
trap 'ERRLINE=$LINENO' ERR
trap 'c=$?; [ -n "$TMP" ] && rm -rf "$TMP" 2>/dev/null; if [ "$c" -ne 0 ]; then echo ""; echo "!!! Interrotto (codice $c), intorno alla riga $ERRLINE."; echo "    Copia queste righe e inviamele per capire il problema."; printf "Premi INVIO per chiudere..."; read -r _ </dev/tty 2>/dev/null; fi' EXIT
RAW="https://raw.githubusercontent.com/carlotimelapselab/thunderbird-foreign-mail-configurator/main"
PROFILE_REL="Profiles/qajfqcsf.Timelapse Siti Esteri"
PROFILE_NAME="Timelapse Siti Esteri"
PROFILE_DIR_NAME="qajfqcsf.Timelapse Siti Esteri"

# --- intro animata: logo MONDO + globo con i nostri paesi -----------
show_globe(){
  ( set +e
    G="$(curl -fsSL "$RAW/globe.txt" 2>/dev/null)"
    [ -z "$G" ] && exit 0
    F="$(mktemp /tmp/tl_globe.XXXXXX)"; printf '%s' "$G" > "$F"
    H=23; nf=$(( $(wc -l < "$F") / H ))
    [ "$nf" -lt 1 ] && { rm -f "$F"; exit 0; }
    # se la finestra e' troppo piccola l'animazione "ballerebbe": la salto
    cols=$(tput cols 2>/dev/null || echo 0); rows=$(tput lines 2>/dev/null || echo 0)
    if [ "${cols:-0}" -lt 78 ] || [ "${rows:-0}" -lt 24 ]; then rm -f "$F"; exit 0; fi
    printf '\033[?25l\033[2J'
    i=0
    while [ "$i" -lt "$nf" ]; do
      printf '\033[H'
      sed -n "$((i*H+1)),$((i*H+H))p" "$F"
      sleep 0.045
      i=$((i+1))
    done
    printf '\033[0m\033[?25h'
    rm -f "$F"
  ) 2>/dev/null || true
}
show_globe

echo ""
echo "=========================================================="
echo "   AGGIORNAMENTO CASELLE THUNDERBIRD (TimelapseLab)"
echo "=========================================================="
echo ""

# --- 1. Thunderbird deve essere chiuso -------------------------------
while pgrep -x thunderbird >/dev/null 2>&1; do
  echo "ATTENZIONE: chiudi completamente Thunderbird (Cmd+Q) per continuare..."
  sleep 2
done

# --- 2. Passphrase (letta dal terminale) -----------------------------
printf "Inserisci la passphrase (puoi incollarla con Cmd+V): "
read -rs PASS </dev/tty
echo ""
# rimuove spazi/ritorni a capo accidentali in testa e in coda
PASS="${PASS#"${PASS%%[![:space:]]*}"}"
PASS="${PASS%"${PASS##*[![:space:]]}"}"
if [ -z "$PASS" ]; then echo "Passphrase vuota. Annullo."; exit 1; fi

# --- 3. Cartella Thunderbird (override con TB_DIR se serve) -----------
TB_DIR="${TB_DIR:-$HOME/Library/Thunderbird}"
if [ ! -d "$TB_DIR" ]; then mkdir -p "$TB_DIR"; fi
echo "Cartella Thunderbird: $TB_DIR"

# --- 4. Scarica e decifra --------------------------------------------
TMP="$(mktemp -d /tmp/tl_tb.XXXXXX)"
echo "Scarico il profilo cifrato..."
curl -fsSL "$RAW/profilo.enc" -o "$TMP/profilo.enc"
echo "Decifro..."
if ! openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 -md sha256 \
     -pass pass:"$PASS" -in "$TMP/profilo.enc" -out "$TMP/profilo.tar.gz" 2>/dev/null; then
  echo "Passphrase errata o file corrotto."; exit 1
fi

# --- 5. Estrai -------------------------------------------------------
tar xzf "$TMP/profilo.tar.gz" -C "$TMP"
SRC="$TMP/profilo"
if [ ! -f "$SRC/prefs.js" ]; then echo "Estrazione fallita."; exit 1; fi

# --- 6. Installa i file nel profilo ----------------------------------
TARGET="$TB_DIR/Profiles/$PROFILE_DIR_NAME"
mkdir -p "$TARGET"
STAMP="$(date +%Y%m%d-%H%M%S)"
for f in prefs.js logins.json key4.db cert9.db; do
  [ -f "$TARGET/$f" ] && cp -p "$TARGET/$f" "$TARGET/$f.bak-$STAMP"
done
cp -f "$SRC/"* "$TARGET/"
rm -f "$TARGET/pkcs11.txt" "$TARGET/compatibility.ini" "$TARGET/parent.lock" "$TARGET/lock"
echo "OK, profilo installato (nomi, firme e password inclusi)."

# --- 7. Registra il profilo in profiles.ini --------------------------
INI="$TB_DIR/profiles.ini"
[ -f "$INI" ] && cp -p "$INI" "$INI.bak-$STAMP"
cat > "$TMP/fixini.pl" <<'PERL'
#!/usr/bin/perl
use strict; use warnings;
my ($file,$ppath,$pname)=@ARGV;
my @lines = -e $file ? do { open my $fh,'<',$file or die $!; <$fh> } : ();
my @sec; my $cur={name=>'',lines=>[]};
for my $l (@lines){
  if($l =~ /^\s*\[([^\]]+)\]\s*$/){ push @sec,$cur if $cur->{name} ne '' || @{$cur->{lines}}; $cur={name=>$1,lines=>[]}; }
  else { push @{$cur->{lines}}, $l; }
}
push @sec,$cur if $cur->{name} ne '' || @{$cur->{lines}};
sub getk{my($s,$k)=@_; for(@{$s->{lines}}){return $1 if /^\Q$k\E=(.*?)\s*$/} undef}
sub setk{my($s,$k,$v)=@_; for(@{$s->{lines}}){ if(/^\Q$k\E=/){$_="$k=$v\n";return} } push @{$s->{lines}},"$k=$v\n"}
my ($gen)=grep {$_->{name} eq 'General'} @sec;
if(!$gen){ $gen={name=>'General',lines=>[]}; unshift @sec,$gen; }
setk($gen,'StartWithLastProfile','1'); setk($gen,'Version','2');
for my $s (@sec){ if($s->{name}=~/^Install[0-9A-Fa-f]+$/){ setk($s,'Default',$ppath); setk($s,'Locked','1'); } }
my $found; my $maxidx=-1;
for my $s (@sec){
  if($s->{name}=~/^Profile(\d+)$/){ $maxidx=$1 if $1>$maxidx;
    my $p=getk($s,'Path');
    if(defined $p && $p eq $ppath){ $found=$s; } else { @{$s->{lines}}=grep{ !/^Default=/ } @{$s->{lines}}; }
  }
}
if(!$found){ my $s={name=>'Profile'.($maxidx+1),lines=>[]}; push @sec,$s; $found=$s; }
setk($found,'Name',$pname); setk($found,'IsRelative','1'); setk($found,'Path',$ppath); setk($found,'Default','1');
my $out='';
for my $s (@sec){ $out.="[$s->{name}]\n" if $s->{name} ne ''; $out.=join('',grep{ /\S/ } @{$s->{lines}}); $out.="\n"; }
open my $w,'>',$file or die $!; print $w $out; close $w;
PERL
/usr/bin/perl "$TMP/fixini.pl" "$INI" "$PROFILE_REL" "$PROFILE_NAME"

# installs.ini legacy
INSF="$TB_DIR/installs.ini"
if [ -f "$INSF" ]; then
  cp -p "$INSF" "$INSF.bak-$STAMP"
  /usr/bin/perl -0777 -i -pe 's/(\[[0-9A-Fa-f]+\][^\[]*?Default=)[^\r\n]*/${1}'"$PROFILE_REL"'/g' "$INSF" 2>/dev/null || true
fi

echo ""
echo "=========================================================="
echo "   FATTO! Puoi aprire Thunderbird."
echo "=========================================================="
echo "Al primo avvio potrebbe chiedere UNA volta di accettare il"
echo "certificato del server: accetta e prosegui."
echo ""
printf "Premi INVIO per chiudere..."
read -r _ </dev/tty
