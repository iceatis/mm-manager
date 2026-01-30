# 📘 MagicMirror Manager
## README – v1.4.5 (Enterprise Release)

---

## 🧭 Áttekintés

A **MagicMirror Manager (mm-manager)** egy **CLI-alapú üzemeltetési és menedzsment rendszer**, amely a MagicMirror² környezet **telepítését, karbantartását és felügyeletét** teszi lehetővé **grafikus felület nélkül is**, enterprise-szemlélettel.

A v1.4.5 kiadás a **Server mód teljes körű használhatóságát** zárja le, különös hangsúlyt fektetve a:

- konfiguráció integritására
- modul láthatóságra
- kontrollált beavatkozásokra
- üzemeltetési biztonságra

---

## 🎯 Fő jellemzők

- Client és Server mód különválasztva
- Whiptail-alapú főmenü
- CLI-alapú al-eszközök (audit, config, modulkezelés)
- Watchdog támogatás
- Backup / restore (server)
- Node.js / npm / MagicMirror frissítések
- Enterprise-safe működés (nincs rejtett automatizmus)

---

## 🧩 Üzemmódok

### 🔹 Client mód
Klasszikus MagicMirror kliens (kijelzővel).

### 🔹 Server mód
Standalone MagicMirror szerver:
- Web UI
- API / Remote Control
- modul- és config-központú üzemeltetés
- kijelző opcionális

A két mód **funkcionálisan elkülönül**, de **azonos eszközkészletre épül**.

---

## 🧑‍💻 Client mód – Funkciók

### 📋 Rendszer
- Rendszerállapot
- Preflight ellenőrzés
- Uninstall / Reset

### 🖥 Megjelenítés
- Felbontás és forgatás
- HDMI státusz
- Kijelző teszt

### 🌐 Hálózat
- Fix IP
- MagicMirror szerver kapcsolat

### 🛠 Watchdog
- Telepítés / frissítés
- Státusz
- Log megtekintés

### 🔄 Frissítések
- Node.js (NVM-alapú)
- npm
- MagicMirror²
- Frissítési állapot összegzés

### 💾 Rendszer
- Persistent logolás
- Swap növelés (1024 MB)
- Swap információ
- Újraindítás

---

## 🧑‍💼 Server mód – Funkciók

### 📋 Rendszer
- Szerver állapot
- IP cím, Web UI státusz

### 🖥 Megjelenítés (opcionális)
- X / HDMI státusz
- Driver felismerés (KMS / FKMS)
- Felbontás és forgatás

### 🌐 Hálózat
- Fix IP
- hálózati beállítások

### 🔐 Autologin
- Engedélyezés / letiltás

### 👁 Watchdog
- Telepítés
- Státusz
- Élő log
- Letiltás

### ⏰ Automatikus reboot
- Engedélyezés / kikapcsolás

---

## 🧩 Server MagicMirror menü (v1.4.5 újdonság)

### 1️⃣ config.js szerkesztés (server)
Biztonságos szerkesztés, verziózott backup, sanity check.

### 2️⃣ Modulok állapota (audit)
Read-only audit eszköz terminálos kimenettel.

### 3️⃣ Modul telepítés / eltávolítás
Git-alapú modulkezelés, kontrollált npm futtatással.

---

## ⚠️ Known behaviors

- Non-login shell környezet (NVM explicit betöltés)
- Audit eszközök Enter-re várnak
- Nincs automatikus MagicMirror restart

---

## 📦 Verzióinformáció

- Verzió: **v1.4.5**
- Típus: **Enterprise / Server-ready release**
