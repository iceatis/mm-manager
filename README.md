# 🪞 MagicMirror Manager v1.4.4

[![Shell Script](https://img.shields.io/badge/Shell_Script-100%25-brightgreen)](https://github.com/iceatis/mm-manager)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A MagicMirror Manager egy teljes körű, bash-alapú kezelőfelület Raspberry Pi eszközökhöz, amely leegyszerűsíti a MagicMirror **kliens** (csak megjelenítő) és **szerver** (önálló) módok telepítését, konfigurálását és karbantartását.

## ✨ Főbb Jellemzők

### 🏗️ Kettős Üzemmód Támogatás
- **Kliens mód**: Csak megjelenítőként működik, távoli MagicMirror szerverről jeleníti meg a tartalmat
- **Szerver mód**: Teljes értékű MagicMirror telepítés önállóként futtatva

### 🛠️ Átfogó Kezelési Funkciók
- **🔧 Telepítés & Konfiguráció**: Kliens és szerver telepítés, hálózat, kijelző beállítás
- **🚨 Monitorozás**: Watchdog szolgáltatás, hálózat figyelés, automatikus újraindítás
- **🔄 Frissítéskezelés**: npm, Node.js, MagicMirror frissítése külön parancsokkal
- **💾 Biztonsági mentés**: Konfiguráció export/import, automatikus backup
- **📊 Diagnosztika**: Rendszerállapot, logok, memóriakezelés (swap)

### 🎯 Felhasználóbarát Design
- Magyar nyelvű, konzolos menürendszer (whiptail)
- Interaktív telepítővarázsló
- Dinamikus menü a rendszer állapota alapján

## 🚀 Gyors Telepítés

### Előfeltételek
- Raspberry Pi (Raspbian/Bookworm)
- Internet kapcsolat
- sudo jogosultságok

### Telepítési lépések
```bash
# 1. Projekt letöltése
git clone https://github.com/iceatis/mm-manager.git
cd mm-manager

# 2. Futtatási jogok beállítása
chmod +x mm-manager.sh

# 3. Indítás (első futtatás telepíti a whiptail-t)
sudo ./mm-manager.sh
```

## 📖 Részletes Használati Útmutató

### 🔲 Kezdeti állapot (üres rendszer)
A program első indításakor a következő lehetőségek érhetők el:

| Menüpont | Leírás |
|----------|---------|
| 📦 Kliens telepítés | MagicMirror kliens telepítése megjelenítő módban |
| 🖥 Szerver telepítés | Teljes MagicMirror szerver telepítése |
| 🔍 Preflight ellenőrzés | Rendszerkövetelmények ellenőrzése |

### 🖥️ Kliens Üzemmód
Miután a kliens telepítve lett, a következő funkciók válnak elérhetővé:

#### Kijelző Beállítások
- Kijelző/felbontás konfiguráció
- HDMI forgatás (0°, 90°, 180°, 270°)
- Kijelző teszt és állapot információk

#### Hálózat Konfiguráció
- Fix IP cím beállítása
- DHCP konfiguráció
- Hálózati interfész kezelés

#### MagicMirror Kapcsolat
- Távoli szerver IP címének beállítása
- Port konfiguráció
- Kapcsolat tesztelése

#### Rendszer Karbantartás
- **Watchdog**: Telepítés, státusz, naplók
- **Automatikus reboot**: Napi ütemezés beállítása
- **Frissítések**: npm, Node.js, MagicMirror frissítés
- **Logolás**: Perzisztens logok, logmegtekintés
- **Memória**: Swap növelése 1024 MB-ra

#### Konfiguráció Kezelés
- Konfiguráció exportálása (backup)
- Konfiguráció importálása (visszaállítás)
- Uninstall/reset opciók

### 🖥️ Szerver Üzemmód
A szerver módban ezek a kiegészítő funkciók érhetők el:

#### Szerver Specifikus Beállítások
- Autologin engedélyezése/kikapcsolása
- Szerver watchdog kezelése
- Szerver hálózat konfiguráció
- Szerver kijelző beállítások

#### Rendszerfelügyelet
- Szerver állapot információk
- Web UI állapot (port 8080)
- Rendszerfrissítések kezelése

## 📁 Projekt Struktúra

### Fő Könyvtár
| Fájl | Leírás |
|------|---------|
| `mm-manager.sh` | Fő menürendszer és vezérlő |
| `status_overview.sh` | Rendszerállapot megjelenítő |
| `mm-state.sh` | Rendszerállapot kezelő |
| `installer_mode.sh` | Üzemmód választó |
| `install_client.sh` | Kliens telepítő |

### Funkcionális Modulok
| Könyvtár | Cél |
|----------|------|
| `server/` | Szerver specifikus scriptek |
| `updates/` | Frissítéskezelő scriptek |
| `logs/` | Naplókezelési eszközök |
| `memory/` | Memória- és swap kezelés |

### Konfigurációs Scriptek
| Script | Funkció |
|--------|----------|
| `network_config.sh` | Hálózati beállítások |
| `display_config.sh` | Kijelző konfiguráció |
| `client_connection.sh` | Szerver kapcsolat beállítás |

## 🔧 Technikai Információk

### Futtatási Környezet
- **Operációs rendszer**: Raspberry Pi OS (Bookworm)
- **Shell**: Bash 5.2+
- **Függőségek**: whiptail, nmcli (NetworkManager)

### Állapotkezelés
A program állapotát a `/var/lib/mm-manager/` könyvtárban tárolja:
- `system_mode` – aktuális üzemmód (empty/client/server)
- `display_rotation_*` – kijelző forgatási beállítások
- `display_profile` – kijelző profil

### Watchdog Rendszer
Kétféle watchdog implementáció:
1. **mm-watchdog.service** – MagicMirror folyamat figyelése
2. **Hálózati watchdog** – kapcsolat állapot nyomon követése

## 🐛 Hibaelhárítás

### Gyakori problémák és megoldások

| Probléma | Lehetséges ok | Megoldás |
|----------|---------------|----------|
| "whiptail nem található" | A csomag nincs telepítve | Automatikusan telepíti az első futtatáskor |
| "Permission denied" | Nem sudo-val futtatja | Futtassa `sudo ./mm-manager.sh` paranccsal |
| MagicMirror nem indul | Node.js/npm probléma | Frissítse npm-et és Node.js-t a menüből |
| Kijelző nem működik | Rossz HDMI konfig | Használja a "Kijelző teszt" funkciót |

### Naplózás
- Rendszernaplók: `journalctl -u mm-watchdog.service`
- MagicMirror naplók: `~/MagicMirror/logs/`
- Manager naplók: `/var/log/mm-manager/`

## 🤝 Közreműködés

Kérjük, a hozzájárulás előtt tekintse át a következőket:

### Fejlesztői környezet beállítása
```bash
# 1. Repository klónozása
git clone https://github.com/iceatis/mm-manager.git

# 2. Tesztkörnyezet létrehozása
cd mm-manager
./test_environment.sh  # (jövőbeli fejlesztés)
```

### Fejlesztési irányelvek
1. **Kódstílus**: Kövesse a meglévő kódbázis stílusát
2. **Magyar nyelv**: Minden felhasználói üzenet legyen magyarul
3. **Hibakezelés**: Minden script használja a `set -e` opciót
4. **Modularitás**: Új funkciók külön scriptekbe szervezve

### Pull Request folyamat
1. Fork a repository-t
2. Hozzon létre egy feature branch-et (`git checkout -b feature/új-funkció`)
3. Commitolja a változtatásokat (`git commit -am 'Új funkció hozzáadva'`)
4. Pusholja a branch-et (`git push origin feature/új-funkció`)
5. Hozzon létre egy Pull Request-et

## 📈 Fejlesztési Terv (v1.5.0)

### Közeljövőben tervezett funkciók
- [ ] Webes felület hozzáadása
- [ ] Távoli kezelés SSH-n keresztül
- [ ] További kijelző profilok
- [ ] Automatikus biztonsági mentések
- [ ] Tesztkörnyezet létrehozása

### Hosszú távú célok
- [ ] Több platform támogatása (nem csak Raspberry Pi)
- [ ] Docker konténer támogatás
- [ ] Plugin rendszer külső modulokhoz
- [ ] Grafikus felület (GTK/Qt)

## 📄 Licenc

Ez a projekt az MIT Licenc alatt áll - a részletekért lásd a [LICENSE](LICENSE) fájlt.

## 👏 Köszönet

- Köszönet a [MagicMirror²](https://github.com/MichMich/MagicMirror) közösségnek
- Külön köszönet minden tesztelőnek és visszajelzőnek
- Kérdésekkel és javaslatokkal keresse a GitHub Issues oldalt

---

**Projekt állapota**: 🟢 Aktív fejlesztés alatt  
**Legutóbbi frissítés**: 2026. január 28.  
**Verzió**: v1.4.4
