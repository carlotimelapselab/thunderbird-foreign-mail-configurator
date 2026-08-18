#!/usr/bin/env python3
# =====================================================================
#  crea-globe.py - genera globe.txt: logo colorato "TIMELAPSE MONDO"
#  (TIMELAPSE bianco, MONDO blu) sopra un GLOBO TERRESTRE che ruota, con
#  i continenti reali disegnati in verde e i paesi dei domini installati
#  illuminati in giallo.
#  Uso: python3 crea-globe.py [percorso/prefs.js]
#  Domini senza coordinate -> segnalati: aggiungile nel dizionario COORD.
#
#  Richiede il pacchetto Python "global-land-mask" (continenti reali).
#  Installa una volta:  pip3 install global-land-mask
#  Se non e' installato, il globo usa comunque una silhouette semplificata.
# =====================================================================
import sys, re, math

ESC=chr(27)
WHITE=ESC+"[1;37m"; BLUE=ESC+"[38;5;68m"; RESET=ESC+"[0m"
GREEN =ESC+"[38;2;40;225;130m"   # continenti (lato illuminato)
DGREEN=ESC+"[38;2;18;110;66m"    # continenti lato notte + bordo del globo
MARK  =ESC+"[1;38;2;255;235;40m" # paesi con un dominio installato (giallo)

TL=[' _____ ___ __  __ ___ _      _   ___  ___ ___', '|_   _|_ _|  \\/  | __| |    /_\\ | _ \\/ __| __|', '  | |  | || |\\/| | _|| |__ / _ \\|  _/\\__ \\ _|', '  |_| |___|_|  |_|___|____/_/ \\_\\_|  |___/___|']
MO=[' __  __  ___  _  _ ___   ___', '|  \\/  |/ _ \\| \\| |   \\ / _ \\', '| |\\/| | (_) | .` | |) | (_) |', '|_|  |_|\\___/|_|\\_|___/ \\___/']

COORD = {
'ad':(42.5,1.5),'af':(33.9,67.7),'africa':(2.0,21.0),'ag':(17.1,-61.8),'al':(41.2,20.0),
'am':(40.1,45.0),'ar':(-34.0,-64.0),'ba':(44.0,18.0),'bg':(42.7,25.5),'bh':(26.0,50.5),
'bi':(-3.4,29.9),'bj':(9.3,2.3),'bo':(-16.3,-63.6),'by':(53.7,27.9),'bz':(17.2,-88.5),
'ci':(7.5,-5.5),'cm':(5.7,12.7),'cr':(9.7,-83.7),'cv':(16.0,-24.0),'cy':(35.1,33.4),
'cz':(49.8,15.5),'dj':(11.8,42.6),'ec':(-1.8,-78.2),'ee':(58.6,25.0),'et':(9.1,40.5),
'fo':(62.0,-6.8),'ga':(-0.8,11.6),'gd':(12.1,-61.7),'ge':(42.3,43.4),'gg':(49.45,-2.58),
'gl':(71.7,-42.6),'gm':(13.4,-15.3),'gt':(15.8,-90.2),'gw':(11.8,-15.2),'gy':(4.9,-58.9),
'hk':(22.3,114.2),'hr':(45.1,15.2),'id':(-0.8,113.9),'ie':(53.4,-8.2),'im':(54.2,-4.5),
'iq':(33.2,43.7),'is':(64.9,-19.0),'je':(49.2,-2.13),'jp':(36.2,138.2),'ke':(0.0,37.9),
'kg':(41.2,74.8),'kr':(36.5,127.9),'ky':(19.3,-81.2),'kz':(48.0,66.9),'la':(19.9,102.5),
'lk':(7.9,80.8),'lt':(55.2,23.9),'lu':(49.8,6.1),'lv':(56.9,24.6),'ly':(26.3,17.2),
'md':(47.4,28.4),'mg':(-18.8,46.9),'mk':(41.6,21.7),'ml':(17.6,-4.0),'mn':(46.9,103.8),
'mt':(35.9,14.4),'mu':(-20.3,57.6),'mw':(-13.3,34.3),'ng':(9.1,8.7),'nz':(-41.0,174.0),
'pa':(8.5,-80.8),'pe':(-9.2,-75.0),'pk':(30.4,69.3),'qa':(25.4,51.2),'rs':(44.0,21.0),
'sb':(-9.6,160.2),'sd':(12.9,30.2),'si':(46.2,15.0),'sl':(8.5,-11.8),'sm':(43.9,12.5),
'sn':(14.5,-14.5),'so':(5.2,46.2),'tg':(8.6,0.8),'tj':(38.9,71.3),'tl':(-8.9,125.7),
'to':(-21.2,-175.2),'tw':(23.7,121.0),'tz':(-6.4,34.9),'ug':(1.4,32.3),'uy':(-32.5,-55.8),
'uz':(41.4,63.6),'vc':(13.0,-61.2),'vu':(-15.4,166.9),'yt':(-12.8,45.2),
'corfu':(39.6,19.8),'corsica':(42.0,9.0),'crete':(35.2,24.8),
'org.ua':(49.0,32.0),'ua':(49.0,32.0),
}

# --- geometria del globo (compatta: sta in un terminale 80x24) -------
W,H=40,19; Rh,Rv=18.0,9.0; cx,cy=19.5,9.0
Lg=(-0.5,0.45,0.74); _ln=math.sqrt(sum(c*c for c in Lg)); Lg=tuple(c/_ln for c in Lg)

# --- mappa dei continenti reali --------------------------------------
try:
    from global_land_mask import globe as _gl
    def is_land(lat,lon):
        if lon>180: lon-=360
        if lon<-180: lon+=360
        return bool(_gl.is_land(lat,lon))
except Exception:
    # fallback grezzo (rettangoli continentali) se il pacchetto manca
    _BOX=[(-56,15,-82,-34),(7,83,-170,-52),(35,71,-11,60),(-35,37,-18,52),
          (5,55,45,150),(-45,10,95,155),(-47,-10,112,179)]
    def is_land(lat,lon):
        if lon>180: lon-=360
        for a,b,c,d in _BOX:
            if a<=lat<=b and c<=lon<=d: return True
        return False

# --- logo -------------------------------------------------------------
TLw=max(len(l) for l in TL); MOw=max(len(l) for l in MO)
LOGO_VIS=TLw+2+MOw
WF=max(LOGO_VIS,W)
GPAD=(WF-W)//2
LPAD=(WF-LOGO_VIS)//2

def logo_lines():
    # compatto: solo le 4 righe del logo (niente righe vuote) per stare in 80x24
    out=[]
    for i in range(len(TL)):
        vis=(" "*LPAD)+WHITE+TL[i].ljust(TLw)+RESET+"  "+BLUE+MO[i].ljust(MOw)+RESET
        out.append(vis)
    return out
LOGO=logo_lines(); LH=len(LOGO)

def keys_from_prefs(path):
    t=open(path,encoding="utf-8",errors="ignore").read(); ks=set()
    for mm in re.findall(r'useremail", "info@([a-z0-9.\-]+)"', t):
        if mm.startswith("timelapse."): ks.add(mm.split(".",1)[1])
        elif mm.startswith("timelapse-") and mm.endswith(".gr"): ks.add(mm[len("timelapse-"):-3])
        elif mm.startswith("timelapse-") and "." in mm: ks.add(mm[len("timelapse-"):].split(".")[0])
    return ks

def globe(theta,pts):
    ct,st=math.cos(theta),math.sin(theta)
    ch=[[" "]*W for _ in range(H)]
    co=[[None]*W for _ in range(H)]
    for row in range(H):
        for col in range(W):
            u=(col-cx)/Rh; v=(cy-row)/Rv; d=u*u+v*v
            if d>1.0: continue
            z=math.sqrt(1-d)
            Gx=u*ct-z*st; Gy=v; Gz=u*st+z*ct
            lat=math.degrees(math.asin(max(-1.0,min(1.0,Gy))))
            lon=math.degrees(math.atan2(Gx,Gz))
            b=u*Lg[0]+v*Lg[1]+z*Lg[2]
            rim=d>0.93
            if is_land(lat,lon):
                if b>0.15: ch[row][col]="#"; co[row][col]=GREEN
                else:      ch[row][col]="+"; co[row][col]=DGREEN
            elif rim:
                ch[row][col]=":"; co[row][col]=DGREEN
    # paesi installati -> marcatori gialli
    for lat,lon in pts:
        la=math.radians(lat); lo=math.radians(lon)
        Gx=math.cos(la)*math.sin(lo); Gy=math.sin(la); Gz=math.cos(la)*math.cos(lo)
        Vx=Gx*ct+Gz*st; Vz=-Gx*st+Gz*ct
        if Vz<=0.03: continue
        c=int(round(cx+Vx*Rh)); r=int(round(cy-Gy*Rv))
        if 0<=r<H and 0<=c<W:
            ch[r][c]="@"; co[r][c]=MARK
    # rendering con colori a run
    lines=[]
    for r in range(H):
        s=[" "*GPAD]; cur=None
        for c in range(W):
            k=co[r][c]
            if k!=cur:
                s.append(RESET if k is None else k); cur=k
            s.append(ch[r][c])
        if cur is not None: s.append(RESET)
        lines.append("".join(s))
    return lines

def render(keys):
    pts=[]; missing=[]
    for k in sorted(keys):
        pts.append(COORD[k]) if k in COORD else missing.append(k)
    N=72; out=[]
    for i in range(N):
        out.append("\n".join(LOGO+globe(2*math.pi*i/N,pts)))
    open("globe.txt","w").write("".join(fr+"\n" for fr in out))
    return len(pts),missing,LH+H

if __name__=="__main__":
    keys = keys_from_prefs(sys.argv[1]) if len(sys.argv)>1 else set(COORD.keys())
    n,missing,fh = render(keys)
    print("globe.txt creato: %d paesi illuminati, %d righe per frame (72 frame), larghezza %d colonne." % (n,fh,WF))
    if missing:
        print("ATTENZIONE - domini SENZA coordinate (non illuminati):", ", ".join(missing))
        print("Aggiungi le coordinate nel dizionario COORD dentro crea-globe.py e rilancia.")
