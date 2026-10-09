#!/usr/bin/env bash
# Fedora Workstation post-install for the X570 / Ryzen 3700X / RX 5700 XT desktop.
# Usage: ./setup.sh            (full run)
#        SKIP_GAMING=1 ./setup.sh   (skip Steam/gaming bits)
# Safe to re-run. Failing steps are reported at the end instead of aborting.

set -uo pipefail

[[ $EUID -eq 0 ]] && { echo "Run as your normal user (script uses sudo itself)."; exit 1; }
sudo -v || exit 1
while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &

FAILED=()
step() { echo -e "\n\033[1;34m==> $1\033[0m"; }
run()  { "$@" || { echo -e "\033[1;31m  ! failed: $*\033[0m"; FAILED+=("$*"); }; }

FEDORA=$(rpm -E %fedora)

# --------------------------------------------------------------------------
step "dnf tuning"
grep -q '^max_parallel_downloads' /etc/dnf/dnf.conf || \
  echo 'max_parallel_downloads=10' | sudo tee -a /etc/dnf/dnf.conf >/dev/null

step "System update"
run sudo dnf upgrade -y --refresh

# --------------------------------------------------------------------------
step "RPM Fusion (free + nonfree)"
run sudo dnf install -y \
  "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA}.noarch.rpm" \
  "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA}.noarch.rpm"

step "Multimedia codecs + AMD hardware video decode"
run sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing
run sudo dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld
run sudo dnf swap -y mesa-vdpau-drivers mesa-vdpau-drivers-freeworld
run sudo dnf install -y libva-utils

step "Flathub"
run flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# --------------------------------------------------------------------------
step "Google Chrome repo"
run sudo dnf install -y fedora-workstation-repositories
run sudo dnf config-manager setopt google-chrome.enabled=1

step "COPRs: LACT (GPU control), onedriver (OneDrive)"
run sudo dnf copr enable -y ilyaz/LACT
run sudo dnf copr enable -y jstaf/onedriver

# --------------------------------------------------------------------------
step "Core packages"
PKGS=(
  # shell / cli
  git zsh fzf zoxide ripgrep fd-find bat btop fastfetch tldr unzip p7zip p7zip-plugins
  # dev
  nodejs python3-pip java-17-openjdk-devel android-tools gcc make
  # desktop / GNOME
  gnome-tweaks gnome-extensions-app gnome-shell-extension-appindicator
  google-chrome-stable vlc qbittorrent remmina remmina-plugins-rdp remmina-plugins-vnc
  filezilla baobab file-roller
  # audio (Equalizer APO + AMD noise suppression replacement)
  easyeffects lsp-plugins-lv2
  # hardware
  openrgb lact onedriver
  # btrfs snapshots (Fedora default fs)
  btrfs-assistant snapper
)
run sudo dnf install -y "${PKGS[@]}"
run sudo systemctl enable --now lactd

# --------------------------------------------------------------------------
if [[ -z "${SKIP_GAMING:-}" ]]; then
  step "Gaming"
  run sudo dnf install -y steam steam-devices mangohud gamemode goverlay
  run sudo usermod -aG gamemode "$USER"
fi

# --------------------------------------------------------------------------
step "Flatpaks"
FLATPAKS=(
  com.mattjakeman.ExtensionManager   # GNOME extensions
  com.github.tchx84.Flatseal         # flatpak permissions
  com.heroicgameslauncher.hgl        # GOG / Epic
  com.usebottles.bottles             # Wine prefixes (CoD 2003, misc)
  net.davidotek.pupgui2              # ProtonUp-Qt (GE-Proton)
  dev.zed.Zed
  net.werwolv.ImHex
  com.github.skylot.jadx
  com.google.AndroidStudio
  io.github.cboxdoerfer.FSearch      # Everything replacement
  com.gabm.satty                     # ShareX-style annotate
  com.teamspeak.TeamSpeak
)
for f in "${FLATPAKS[@]}"; do run flatpak install -y --noninteractive flathub "$f"; done

# --------------------------------------------------------------------------
step "JetBrainsMono Nerd Font"
FONT_DIR="$HOME/.local/share/fonts/JetBrainsMonoNF"
if [[ ! -d "$FONT_DIR" ]]; then
  mkdir -p "$FONT_DIR"
  TMP=$(mktemp -d)
  run curl -fL -o "$TMP/jbm.zip" \
    https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
  [[ -f "$TMP/jbm.zip" ]] && unzip -oq "$TMP/jbm.zip" -d "$FONT_DIR" && fc-cache -f >/dev/null
  rm -rf "$TMP"
fi

# --------------------------------------------------------------------------
step "Locale / GNOME defaults"
run sudo timedatectl set-timezone Europe/Ljubljana
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'si')]"
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 11'
gsettings set org.gnome.mutter center-new-windows true
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
gsettings set org.gnome.desktop.peripherals.mouse accel-profile 'flat'   # no mouse accel (gaming)

step "zoxide in bash"
grep -q 'zoxide init' "$HOME/.bashrc" || echo 'eval "$(zoxide init bash)"' >> "$HOME/.bashrc"

# --------------------------------------------------------------------------
step "LAN-mode helper -> ~/.local/bin/lan-mode"
mkdir -p "$HOME/.local/bin"
install -m 755 "$(dirname "$0")/lan-mode.sh" "$HOME/.local/bin/lan-mode" 2>/dev/null \
  || echo "  (lan-mode.sh not next to setup.sh, skipped)"

# --------------------------------------------------------------------------
step "Cleanup"
run sudo dnf autoremove -y
run flatpak uninstall -y --unused

echo
if ((${#FAILED[@]})); then
  echo -e "\033[1;33mDone with ${#FAILED[@]} failed step(s):\033[0m"
  printf '  - %s\n' "${FAILED[@]}"
else
  echo -e "\033[1;32mAll done.\033[0m"
fi
echo "Reboot recommended (group membership, codecs, GPU daemon)."
