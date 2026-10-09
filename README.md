# fedora-setup

Post-install scripts for my GNOME desktop (X570 / Ryzen 7 3700X / RX 5700 XT).
Two flavours — pick the one matching the installed distro:

| Script | Distro | Why |
|---|---|---|
| `setup-debian.sh` | **Debian 13 GNOME** (primary) | Officially supported by Claude Desktop (Linux beta) |
| `setup.sh` | Fedora Workstation | Kept for when Claude Desktop supports Fedora |

```bash
git clone https://github.com/gasperv/fedora-setup && cd fedora-setup
chmod +x *.sh
./setup-debian.sh       # or ./setup.sh on Fedora
```

Options (both): `SKIP_GAMING=1`. Debian only: `NO_BACKPORTS=1`, `NO_CLAUDE=1`.

Debian installer tip: leave the **root password empty** so your user gets sudo.

## Newer packages on Debian
- **Backports** (`<codename>-backports`): newer kernel, firmware and Mesa built for stable. Enabled by default.
- **Flathub**: GUI apps always at latest (Heroic, Bottles, Zed, ImHex, Android Studio, …).
- Not used: testing/sid — breaks too often for a daily driver.

Update everything: `sudo apt update && sudo apt full-upgrade && flatpak update`

## What it does
- Debian: contrib/non-free/non-free-firmware, backports, i386 arch, AMD firmware + Mesa (VA-API, Vulkan, 32-bit)
- Fedora: RPM Fusion, full ffmpeg, freeworld VA-API/VDPAU, COPRs (LACT, onedriver)
- Chrome repo; Debian also: Claude Desktop repo (key fingerprint verified), Cowork VM prereqs, Claude Code CLI
- CLI/dev tools, GNOME Tweaks + Extension Manager, GSConnect, Remmina, FileZilla, EasyEffects, OpenRGB
- Steam, MangoHud, GameMode, Heroic, Bottles, ProtonUp-Qt
- Zed, ImHex, jadx, Android Studio, FSearch, Satty, TeamSpeak (Flatpak)
- JetBrainsMono Nerd Font, Slovenian keyboard, Europe/Ljubljana, dark mode, flat mouse accel
- firewalld + `lan-mode` in `~/.local/bin`

Re-runnable; failed steps are listed at the end instead of aborting.

## LAN party
```bash
lan-mode on     # wired NIC -> firewalld "trusted" zone (hosting + discovery)
lan-mode off    # back to default
```

## Windows → Linux swaps
| Windows | Linux |
|---|---|
| Equalizer APO, AMD Noise Suppression | EasyEffects |
| Everything | FSearch |
| ShareX | Satty / GNOME screenshot |
| RTSS | MangoHud |
| AMD Software | CoreCtrl (Debian) / LACT (Fedora) |
| WizTree | Baobab |
| WinSCP | Nautilus `sftp://`, FileZilla |
| mRemoteNG, Royal TS, UltraVNC | Remmina |
| ADB AppControl | adb / UAD-ng |
| Phone Link | GSConnect |
| OneDrive | onedriver |

## Manual
- AnythingLLM: AppImage from anythingllm.com
- Das Keyboard Q: check Linux support
