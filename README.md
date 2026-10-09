# fedora-setup

Post-install for my Fedora Workstation desktop (X570 / Ryzen 7 3700X / RX 5700 XT).

```bash
git clone <this repo> && cd fedora-setup
chmod +x setup.sh lan-mode.sh
./setup.sh              # or: SKIP_GAMING=1 ./setup.sh
```

## What it does
- dnf parallel downloads, full upgrade
- RPM Fusion, full ffmpeg, AMD VA-API/VDPAU freeworld drivers
- Flathub, Chrome repo, COPRs: LACT (GPU), onedriver
- CLI/dev tools, GNOME Tweaks + Extension Manager, Remmina, FileZilla, EasyEffects, OpenRGB
- Steam, MangoHud, GameMode, Heroic, Bottles, ProtonUp-Qt
- Zed, ImHex, jadx, Android Studio, FSearch, Satty, TeamSpeak (Flatpak)
- JetBrainsMono Nerd Font, Slovenian keyboard, Europe/Ljubljana, dark mode, flat mouse accel
- Installs `lan-mode` to `~/.local/bin`

Re-runnable; failed steps are listed at the end instead of aborting.

## LAN party
```bash
lan-mode on     # wired NIC -> firewalld "trusted" zone (hosting + discovery)
lan-mode off    # back to default
```

## Windows → Linux swaps
| Windows | Fedora |
|---|---|
| Equalizer APO, AMD Noise Suppression | EasyEffects |
| Everything | FSearch |
| ShareX | Satty / GNOME screenshot |
| RTSS | MangoHud |
| AMD Software | LACT |
| WizTree | Baobab |
| WinSCP | Nautilus `sftp://`, FileZilla |
| mRemoteNG, Royal TS, UltraVNC | Remmina |
| ADB AppControl | adb / UAD-ng |
| Phone Link | GSConnect |
| OneDrive | onedriver |

## Manual
- AnythingLLM: AppImage from anythingllm.com
- GSConnect: install via Extension Manager
- Das Keyboard Q: check Linux support
