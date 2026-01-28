# MagicMirror Kiosk Manager – Project Documentation

## 🎯 Projekt célja

A MagicMirror Kiosk Manager célja egy **stabil, karbantartható, újratelepíthető**
MagicMirror kliens környezet biztosítása Raspberry Pi eszközökön
(Pi 3 / 4 / 5, Bookworm OS).

A rendszer **menüvezérelt**, headless környezetben is használható,
és kifejezetten **kioszk / signage** célra optimalizált.

---

## 🧠 Fő tervezési elvek

### 1️⃣ Raspi-config UX minta követése
- művelet után azonnali visszajelzés
- **nincs „rejtett state” a fejlécben**
- reboot mindig **külön menüpont**

### 2️⃣ Systemd + Cron helyes használata
- Watchdog: **systemd által felügyelt**
- Időzített reboot: **USER crontab**, nem root
- sudo környezetben is **helyes user feloldás**

### 3️⃣ Kijelzőkezelés Xorg alatt
- `.xinitrc` generálás install során
- Kedei 800×480 fix csak akkor aktiválódik, ha kiválasztott
- nincs globális xrandr hack

### 4️⃣ Átlátható állapotkezelés
- „fut-e most” ≠ „systemd kezeli-e”
- watchdog státusz: **enabled / failed / missing**
- reboot státusz: **cron alapján**

---

## 🛠 Kritikus tanulságok (lessons learned)

### ❗ sudo + $HOME csapda
- systemd service generáláskor **SOHA nem használunk `$HOME`**
- mindig: `SUDO_USER` + `~user`

### ❗ cron user-keveredés
- reboot cron **nem kerülhet root crontabba**
- mindig explicit: `crontab -u USER`

### ❗ watchdog működési modell
- rövid életű script + `Restart=always`
- státuszt **nem `is-active` alapján** mérjük

---

## 📦 Fő komponensek

| Komponens | Funkció |
|---------|--------|
| `mm-manager.sh` | főmenü |
| `installer_mode.sh` | progress + live log telepítés |
| `install_client.sh` | MagicMirror kliens |
| `mm-watchdog.sh` | kliens felügyelet |
| `status_overview.sh` | rendszer állapot |
| `scheduled_reboot_*.sh` | időzített reboot |

---

## 🔖 Verziózás

### v1.2.1 (stabil)
- watchdog véglegesítve
- cron reboot user-fix
- kijelzőkezelés stabil
- UX raspi-config kompatibilis

---

## 🚀 Jövőbeli irányok (nem része a stabilnak)
- preflight check
- státusz ikon bővítés
- image build támogatás
- Pi Zero külön profil (újragondolva)

---

## 📌 Megjegyzés
Ez a dokumentum **szándékosan részletes**.
Célja, hogy **6–12 hónap múlva is érthető legyen**, mi miért így működik.
