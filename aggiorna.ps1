# =====================================================================
#  Aggiorna-Timelapse (Windows) - configuratore caselle estere Thunderbird
#  Scarica il profilo cifrato dal repo, lo decifra con la passphrase e
#  lo installa nel profilo Thunderbird "Timelapse Siti Esteri".
#  Eseguito online dal launcher fisso Aggiorna-Timelapse.bat.
# =====================================================================
$ErrorActionPreference = 'Stop'
# --- rete di sicurezza: qualsiasi errore imprevisto NON chiude la finestra,
#     ma mostra il messaggio e aspetta INVIO ------------------------------
trap {
  Write-Host ""
  Write-Host "!!! ERRORE imprevisto: $($_.Exception.Message)" -ForegroundColor Red
  if ($_.InvocationInfo) { Write-Host ("    (riga " + $_.InvocationInfo.ScriptLineNumber + ")") -ForegroundColor DarkGray }
  Write-Host "    Copia questo messaggio e inviamelo per risolvere." -ForegroundColor Yellow
  try { Read-Host "Premi INVIO per chiudere" } catch {}
  exit 1
}
$RAW = 'https://raw.githubusercontent.com/carlotimelapselab/thunderbird-foreign-mail-configurator/main'
$ProfileRel = 'Profiles/qajfqcsf.Timelapse Siti Esteri'
$ProfileName = 'Timelapse Siti Esteri'
$ProfileDirName = 'qajfqcsf.Timelapse Siti Esteri'

function Say($m,$c='Gray'){ Write-Host $m -ForegroundColor $c }

# PBKDF2-HMAC-SHA256 compatibile con TUTTE le versioni di Windows/.NET
# (usa HMACSHA256, presente da .NET 2.0). Evita di dipendere dall'overload
# a 4 argomenti di Rfc2898DeriveBytes (che manca su .NET < 4.7.2).
Add-Type @"
using System;
using System.Security.Cryptography;
public static class TLKdf {
  static byte[] Cat(byte[] a, byte[] b){ byte[] r=new byte[a.Length+b.Length]; Array.Copy(a,r,a.Length); Array.Copy(b,0,r,a.Length,b.Length); return r; }
  public static byte[] Pbkdf2(string pass, byte[] salt, int iter, int len){
    using(var h = new HMACSHA256(System.Text.Encoding.UTF8.GetBytes(pass))){
      int hlen=32; int blocks=(len+hlen-1)/hlen; byte[] outb=new byte[blocks*hlen];
      for(int i=1;i<=blocks;i++){
        byte[] ib=BitConverter.GetBytes(i); if(BitConverter.IsLittleEndian) Array.Reverse(ib);
        byte[] u=h.ComputeHash(Cat(salt,ib)); byte[] t=(byte[])u.Clone();
        for(int j=1;j<iter;j++){ u=h.ComputeHash(u); for(int k=0;k<hlen;k++) t[k]^=u[k]; }
        Array.Copy(t,0,outb,(i-1)*hlen,hlen);
      }
      byte[] res=new byte[len]; Array.Copy(outb,res,len); return res;
    }
  }
}
"@ -ErrorAction SilentlyContinue

function Enable-Ansi {
  try {
    $vt = Add-Type -Name VTGlobe -Namespace WinTL -PassThru -MemberDefinition '
      [DllImport("kernel32.dll")] public static extern IntPtr GetStdHandle(int n);
      [DllImport("kernel32.dll")] public static extern bool GetConsoleMode(IntPtr h, out uint m);
      [DllImport("kernel32.dll")] public static extern bool SetConsoleMode(IntPtr h, uint m);'
    $h = $vt::GetStdHandle(-11); $m = 0
    [void]$vt::GetConsoleMode($h, [ref]$m)
    [void]$vt::SetConsoleMode($h, $m -bor 4)   # ENABLE_VIRTUAL_TERMINAL_PROCESSING
  } catch { }
}
function Show-Globe {
  try {
    Enable-Ansi
    $txt = (Invoke-WebRequest -Uri "$RAW/globe.txt" -UseBasicParsing -TimeoutSec 8).Content
    $lines = $txt -split "`r?`n"
    $Hh = 31
    $nf = [Math]::Floor($lines.Count / $Hh)
    if ($nf -lt 1) { return }
    try { [Console]::CursorVisible = $false } catch {}
    Clear-Host
    for ($f = 0; $f -lt $nf; $f++) {
      $sb = New-Object System.Text.StringBuilder
      for ($r = 0; $r -lt $Hh; $r++) { [void]$sb.AppendLine($lines[$f*$Hh+$r]) }
      try { [Console]::SetCursorPosition(0,0) } catch {}
      [Console]::Write($sb.ToString())
      Start-Sleep -Milliseconds 45
    }
    [Console]::Write([char]27 + "[0m")
    try { [Console]::CursorVisible = $true } catch {}
    Write-Host ""
  } catch { }
}
Show-Globe
Say ""
Say "==========================================================" 'Cyan'
Say "   AGGIORNAMENTO CASELLE THUNDERBIRD (TimelapseLab)" 'Cyan'
Say "==========================================================" 'Cyan'
Say ""

# --- 1. Thunderbird deve essere chiuso -------------------------------
while (Get-Process -Name 'thunderbird' -ErrorAction SilentlyContinue) {
  Say "ATTENZIONE: chiudi completamente Thunderbird per continuare..." 'Yellow'
  Start-Sleep -Seconds 2
}

# --- 2. Passphrase ---------------------------------------------------
# NB: input in chiaro (non a pallini) apposta, cosi' l'INCOLLA funziona su
# tutte le console di Windows (con i pallini l'incolla infila un solo carattere).
Say "Inserisci la passphrase e premi INVIO (la puoi INCOLLARE con Ctrl+V o clic destro):" 'Gray'
$PASS = (Read-Host "Passphrase").Trim()
if ([string]::IsNullOrEmpty($PASS)) { Say "Passphrase vuota. Annullo." 'Red'; Read-Host "INVIO per uscire"; exit 1 }

# --- 3. Scarica il bundle cifrato ------------------------------------
$tmp = Join-Path $env:TEMP ('tl_tb_' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
$enc = Join-Path $tmp 'profilo.enc'
Say "Scarico il profilo cifrato..." 'Gray'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri "$RAW/profilo.enc" -OutFile $enc -UseBasicParsing

# --- 4. Decifra (AES-256-CBC, PBKDF2-SHA256, iter 200000, formato openssl) ---
$bytes = [IO.File]::ReadAllBytes($enc)
if ($bytes.Length -lt 16 -or ([Text.Encoding]::ASCII.GetString($bytes,0,8)) -ne 'Salted__') {
  Say "File non valido (manca header)." 'Red'; Read-Host "INVIO per uscire"; exit 1
}
$salt = [byte[]]$bytes[8..15]
$ct   = [byte[]]$bytes[16..($bytes.Length-1)]
# derivazione chiave: metodo nativo veloce se disponibile, altrimenti fallback compatibile
$keyiv = $null
try {
  $kdf = New-Object System.Security.Cryptography.Rfc2898DeriveBytes(
           $PASS, $salt, 200000, [System.Security.Cryptography.HashAlgorithmName]::SHA256)
  $keyiv = $kdf.GetBytes(48)
} catch {
  Say "Derivo la chiave in modalita' compatibile..." 'Gray'
  $keyiv = [TLKdf]::Pbkdf2($PASS, $salt, 200000, 48)
}
$aes = [System.Security.Cryptography.Aes]::Create()
$aes.KeySize = 256; $aes.Mode = 'CBC'; $aes.Padding = 'PKCS7'
$aes.Key = [byte[]]($keyiv[0..31]); $aes.IV = [byte[]]($keyiv[32..47])
try {
  $dec = $aes.CreateDecryptor()
  $plain = $dec.TransformFinalBlock([byte[]]$ct, 0, $ct.Length)
} catch {
  Say "Passphrase errata o file corrotto." 'Red'; Read-Host "INVIO per uscire"; exit 1
}
$targz = Join-Path $tmp 'profilo.tar.gz'
[IO.File]::WriteAllBytes($targz, $plain)

# --- 5. Estrai (tar e' presente su Windows 10 1803+) -----------------
Say "Estraggo la configurazione..." 'Gray'
& tar.exe -xzf $targz -C $tmp
$src = Join-Path $tmp 'profilo'
if (-not (Test-Path (Join-Path $src 'prefs.js'))) { Say "Estrazione fallita." 'Red'; Read-Host "INVIO per uscire"; exit 1 }

# --- 6. Installa i file nel profilo ----------------------------------
$tbDir  = Join-Path $env:APPDATA 'Thunderbird'
$target = Join-Path $tbDir ('Profiles\' + $ProfileDirName)
New-Item -ItemType Directory -Force -Path $target | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
foreach ($f in 'prefs.js','logins.json','key4.db','cert9.db') {
  $p = Join-Path $target $f
  if (Test-Path $p) { Copy-Item $p "$p.bak-$stamp" -Force }
}
Copy-Item (Join-Path $src '*') $target -Recurse -Force
foreach ($f in 'pkcs11.txt','compatibility.ini','parent.lock','lock') {
  $p = Join-Path $target $f; if (Test-Path $p) { Remove-Item $p -Force -ErrorAction SilentlyContinue }
}
Say "OK, profilo installato (nomi, firme e password inclusi)." 'Green'

# --- 7. Registra il profilo in profiles.ini (robusto cross-macchina) -
$ini = Join-Path $tbDir 'profiles.ini'
if (Test-Path $ini) { Copy-Item $ini "$ini.bak-$stamp" -Force }

# parser INI a sezioni ordinate
function Read-Ini($path) {
  $sections = New-Object System.Collections.ArrayList
  $cur = [ordered]@{ Name=''; Lines=(New-Object System.Collections.ArrayList) }
  if (Test-Path $path) {
    foreach ($ln in [IO.File]::ReadAllLines($path)) {
      if ($ln -match '^\s*\[(.+?)\]\s*$') {
        if ($cur.Name -ne '' -or $cur.Lines.Count -gt 0) { [void]$sections.Add($cur) }
        $cur = [ordered]@{ Name=$Matches[1]; Lines=(New-Object System.Collections.ArrayList) }
      } else { [void]$cur.Lines.Add($ln) }
    }
  }
  if ($cur.Name -ne '' -or $cur.Lines.Count -gt 0) { [void]$sections.Add($cur) }
  return ,$sections
}
function Get-Key($sec,$k){ foreach($l in $sec.Lines){ if($l -match "^$([regex]::Escape($k))=(.*)$"){ return $Matches[1] } } return $null }
function Set-Key($sec,$k,$v){
  for($i=0;$i -lt $sec.Lines.Count;$i++){ if($sec.Lines[$i] -match "^$([regex]::Escape($k))="){ $sec.Lines[$i]="$k=$v"; return } }
  [void]$sec.Lines.Add("$k=$v")
}
function Del-Key($sec,$k){
  $new=New-Object System.Collections.ArrayList
  foreach($l in $sec.Lines){ if($l -notmatch "^$([regex]::Escape($k))="){ [void]$new.Add($l) } }
  $sec.Lines=$new
}

$secs = Read-Ini $ini
# General
$gen = $secs | Where-Object { $_.Name -eq 'General' } | Select-Object -First 1
if (-not $gen) { $gen = [ordered]@{ Name='General'; Lines=(New-Object System.Collections.ArrayList) }; [void]$secs.Insert(0,$gen) }
Set-Key $gen 'StartWithLastProfile' '1'
Set-Key $gen 'Version' '2'
# repoint ogni [Install*]
foreach ($s in $secs) { if ($s.Name -match '^Install[0-9A-Fa-f]+$') { Set-Key $s 'Default' $ProfileRel; Set-Key $s 'Locked' '1' } }
# profilo nostro + rimuovi Default dagli altri
$found=$null; $maxidx=-1
foreach ($s in $secs) {
  if ($s.Name -match '^Profile(\d+)$') {
    if ([int]$Matches[1] -gt $maxidx) { $maxidx=[int]$Matches[1] }
    if ((Get-Key $s 'Path') -eq $ProfileRel) { $found=$s } else { Del-Key $s 'Default' }
  }
}
if (-not $found) { $found=[ordered]@{ Name=('Profile'+($maxidx+1)); Lines=(New-Object System.Collections.ArrayList) }; [void]$secs.Add($found) }
Set-Key $found 'Name' $ProfileName
Set-Key $found 'IsRelative' '1'
Set-Key $found 'Path' $ProfileRel
Set-Key $found 'Default' '1'
# scrivi
$sb = New-Object System.Text.StringBuilder
foreach ($s in $secs) {
  if ($s.Name -ne '') { [void]$sb.AppendLine("[$($s.Name)]") }
  foreach ($l in $s.Lines) { if ($l.Trim() -ne '') { [void]$sb.AppendLine($l) } }
  [void]$sb.AppendLine('')
}
[IO.File]::WriteAllText($ini, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))

# installs.ini legacy: se esiste, repunta tutte le sezioni
$insf = Join-Path $tbDir 'installs.ini'
if (Test-Path $insf) {
  Copy-Item $insf "$insf.bak-$stamp" -Force
  $isecs = Read-Ini $insf
  foreach ($s in $isecs) { if ($s.Name -ne '') { Set-Key $s 'Default' $ProfileRel; Set-Key $s 'Locked' '1' } }
  $sb2 = New-Object System.Text.StringBuilder
  foreach ($s in $isecs) { if ($s.Name -ne '') { [void]$sb2.AppendLine("[$($s.Name)]") }; foreach ($l in $s.Lines) { if ($l.Trim() -ne '') { [void]$sb2.AppendLine($l) } }; [void]$sb2.AppendLine('') }
  [IO.File]::WriteAllText($insf, $sb2.ToString(), (New-Object System.Text.UTF8Encoding($false)))
}

Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
Say ""
Say "==========================================================" 'Cyan'
Say "   FATTO! Puoi aprire Thunderbird." 'Green'
Say "==========================================================" 'Cyan'
Say "Al primo avvio potrebbe chiedere UNA volta di accettare il" 'Gray'
Say "certificato del server: accetta e prosegui." 'Gray'
Say ""
Read-Host "Premi INVIO per chiudere"
