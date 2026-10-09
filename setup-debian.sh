#!/usr/bin/env bash
# Debian 13 (GNOME) post-install for the X570 / Ryzen 3700X / RX 5700 XT desktop.
# Stable base + newer kernel/firmware/Mesa from backports + newer apps from Flathub.
#
# Usage: ./setup-debian.sh
#   SKIP_GAMING=1   skip Steam/gaming bits
#   NO_BACKPORTS=1  stay on plain stable kernel/Mesa
#   NO_CLAUDE=1     skip Claude Desktop + Claude Code
# Safe to re-run. Failing steps are reported at the end instead of aborting.
# Full output is logged to ~/setup-logs/setup-debian-<timestamp>.log (colours stripped),
# failed steps also go to ~/setup-logs/latest-failed.txt.
#
# Install tip: leave the ROOT password EMPTY in the Debian installer so your user gets sudo.

set -uo pipefail

[[ $EUID -eq 0 ]] && { echo "Run as your normal user (script uses sudo itself)."; exit 1; }
sudo -v || { echo "Your user has no sudo. As root run: usermod -aG sudo $USER  (then log out/in)"; exit 1; }
while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &

LOG_DIR="$HOME/setup-logs"; mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/setup-debian-$(date +%Y%m%d-%H%M%S).log"
ln -sf "$LOG" "$LOG_DIR/latest.log"
# terminal keeps colours, log file gets plain text
exec > >(tee >(sed -u -r 's/\x1b\[[0-9;]*[A-Za-z]//g' >> "$LOG")) 2>&1
echo "Logging to $LOG"

FAILED=()
step() { echo -e "\n\033[1;34m==> $1\033[0m"; }
run()  { "$@" || { echo -e "\033[1;31m  ! failed: $*\033[0m"; FAILED+=("$*"); }; }
APT="sudo DEBIAN_FRONTEND=noninteractive apt-get -y"
# install a list; if the batch fails, retry one by one so one missing package doesn't block the rest
apt_try() {
  $APT install "$@" && return
  for p in "$@"; do $APT install "$p" || { echo -e "\033[1;31m  ! failed: $p\033[0m"; FAILED+=("apt: $p"); }; done
}

. /etc/os-release
CODENAME=$VERSION_CODENAME
echo "Debian $VERSION_ID ($CODENAME)"

# --------------------------------------------------------------------------
step "Enable contrib / non-free / non-free-firmware"
if [[ -f /etc/apt/sources.list.d/debian.sources ]]; then
  sudo sed -i -E 's/^Components:.*/Components: main contrib non-free non-free-firmware/' /etc/apt/sources.list.d/debian.sources
else
  sudo sed -i -E "/^deb .*${CODENAME}/ s/ main.*$/ main contrib non-free non-free-firmware/" /etc/apt/sources.list
fi

if [[ -z "${NO_BACKPORTS:-}" ]]; then
  step "Enable ${CODENAME}-backports (newer kernel, firmware, Mesa)"
  sudo tee /etc/apt/sources.list.d/backports.sources >/dev/null <<EOF
Types: deb
URIs: http://deb.debian.org/debian
Suites: ${CODENAME}-backports
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
fi

step "32-bit support (Steam/Wine)"
sudo dpkg --add-architecture i386

step "System update"
run $APT update
run $APT full-upgrade

# --------------------------------------------------------------------------
step "Firmware + GPU stack"
BP=(); [[ -z "${NO_BACKPORTS:-}" ]] && BP=(-t "${CODENAME}-backports")
# -t backports: takes the backports version where one exists, stable otherwise
run $APT install "${BP[@]}" linux-image-amd64 linux-headers-amd64 \
  firmware-amd-graphics firmware-linux-nonfree amd64-microcode
run $APT install "${BP[@]}" mesa-vulkan-drivers libgl1-mesa-dri libglx-mesa0 \
  mesa-va-drivers mesa-vdpau-drivers vainfo vulkan-tools \
  mesa-vulkan-drivers:i386 libgl1-mesa-dri:i386 libglx-mesa0:i386

# --------------------------------------------------------------------------
step "Third-party repos: Google Chrome"
sudo install -d -m 0755 /etc/apt/keyrings
# keep the key armored (.asc): Debian 13's apt verifies with sqv, and Google signs with
# several (sub)keys - the full armored file must be present
run sudo curl -fsSLo /etc/apt/keyrings/google-chrome.asc https://dl.google.com/linux/linux_signing_key.pub
sudo rm -f /etc/apt/keyrings/google-chrome.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.asc] https://dl.google.com/linux/chrome/deb/ stable main" \
  | sudo tee /etc/apt/sources.list.d/google-chrome.list >/dev/null

if [[ -z "${NO_CLAUDE:-}" ]]; then
  step "Third-party repos: Claude Desktop (official Debian repo)"
  KEY=/usr/share/keyrings/claude-desktop-archive-keyring.asc
  run sudo curl -fsSLo "$KEY" https://downloads.claude.ai/claude-desktop/key.asc
  if gpg --show-keys "$KEY" 2>/dev/null | tr -d ' ' | grep -q 31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE; then
    echo "deb [arch=amd64,arm64 signed-by=$KEY] https://downloads.claude.ai/claude-desktop/apt/stable stable main" \
      | sudo tee /etc/apt/sources.list.d/claude-desktop.list >/dev/null
  else
    echo "  ! Claude signing key fingerprint mismatch - repo NOT added"; FAILED+=("claude key verify")
  fi
fi
run $APT update

# --------------------------------------------------------------------------
step "Core packages"
apt_try \
  git zsh fzf zoxide ripgrep fd-find bat btop fastfetch tealdeer unzip p7zip-full curl wget \
  nodejs npm python3-pip python3-venv default-jdk adb fastboot build-essential \
  gnome-tweaks gnome-shell-extension-manager gnome-shell-extension-appindicator \
  gnome-shell-extension-gsconnect gnome-software-plugin-flatpak flatpak \
  google-chrome-stable vlc qbittorrent remmina remmina-plugin-rdp remmina-plugin-vnc \
  filezilla baobab file-roller \
  easyeffects lsp-plugins-lv2 \
  openrgb corectrl \
  timeshift firewalld \
  gnome-shell-extension-dashtodock \
  fonts-noto-core fonts-noto-cjk fonts-noto-color-emoji fonts-liberation \
  fonts-jetbrains-mono fonts-firacode

[[ -z "${NO_CLAUDE:-}" ]] && apt_try claude-desktop qemu-system-x86 ovmf virtiofsd

# --------------------------------------------------------------------------
if [[ -z "${SKIP_GAMING:-}" ]]; then
  step "Gaming"
  echo steam steam/question select "I AGREE" | sudo debconf-set-selections
  echo steam steam/license note '' | sudo debconf-set-selections
  apt_try steam-installer steam-devices mangohud mangohud:i386 gamemode
  run sudo usermod -aG gamemode "$USER"
fi

# --------------------------------------------------------------------------
if [[ -z "${NO_CLAUDE:-}" ]]; then
  step "Claude: Cowork VM prerequisites + Claude Code CLI"
  run sudo usermod -aG kvm "$USER"
  echo vhost_vsock | sudo tee /etc/modules-load.d/vhost_vsock.conf >/dev/null
  sudo modprobe vhost_vsock 2>/dev/null || true
  command -v claude >/dev/null || run bash -c 'curl -fsSL https://claude.ai/install.sh | bash'
fi

# --------------------------------------------------------------------------
step "Flathub + Flatpaks (always-latest apps)"
run sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
FLATPAKS=(
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
  io.github.jstaf.onedriver          # OneDrive (may not exist; non-fatal)
)
for f in "${FLATPAKS[@]}"; do run sudo flatpak install -y --noninteractive flathub "$f"; done

# --------------------------------------------------------------------------
step "JetBrainsMono Nerd Font"
FONT_DIR="$HOME/.local/share/fonts/JetBrainsMonoNF"
if ! ls "$FONT_DIR"/*.ttf >/dev/null 2>&1; then   # retry if an earlier download failed
  mkdir -p "$FONT_DIR"; TMP=$(mktemp -d)
  run curl -fL -o "$TMP/jbm.zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
  [[ -f "$TMP/jbm.zip" ]] && unzip -oq "$TMP/jbm.zip" -d "$FONT_DIR" && fc-cache -f >/dev/null
  rm -rf "$TMP"
fi

# --------------------------------------------------------------------------
step "Locale / GNOME defaults"
run sudo timedatectl set-timezone Europe/Ljubljana
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'si')]"
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
# "Nerd Font Mono" = strict fixed width; the plain "Nerd Font" variant breaks terminal spacing
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font Mono 11'
gsettings set org.gnome.desktop.interface font-antialiasing 'rgba'
gsettings set org.gnome.desktop.interface font-hinting 'slight'
# sharp XWayland apps (Electron/Chrome) when fractional scaling is used
gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer','xwayland-native-scaling']"
gnome-extensions enable dash-to-dock@micxgx.gmail.com 2>/dev/null \
  || echo "  (Dash to Dock: log out/in, then enable it in Extension Manager)"
gsettings set org.gnome.mutter center-new-windows true
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
gsettings set org.gnome.desktop.peripherals.mouse accel-profile 'flat'

step "Shell bits"
grep -q 'zoxide init' "$HOME/.bashrc" || echo 'eval "$(zoxide init bash)"' >> "$HOME/.bashrc"
grep -q 'alias fd=' "$HOME/.bashrc"   || echo 'alias fd=fdfind; alias bat=batcat' >> "$HOME/.bashrc"

# --------------------------------------------------------------------------
step "Firewall + LAN-mode helper"
run sudo systemctl enable --now firewalld
mkdir -p "$HOME/.local/bin"
install -m 755 "$(dirname "$0")/lan-mode.sh" "$HOME/.local/bin/lan-mode" 2>/dev/null \
  || echo "  (lan-mode.sh not next to this script, skipped)"

# --------------------------------------------------------------------------
step "Cleanup"
run $APT autoremove
run sudo flatpak uninstall -y --unused

echo
if ((${#FAILED[@]})); then
  echo -e "\033[1;33mDone with ${#FAILED[@]} failed step(s):\033[0m"; printf '  - %s\n' "${FAILED[@]}"
  printf '%s\n' "${FAILED[@]}" > "$LOG_DIR/latest-failed.txt"
else
  echo -e "\033[1;32mAll done.\033[0m"
  : > "$LOG_DIR/latest-failed.txt"
fi
echo "Full log: $LOG   (errors: grep -inE 'fail|error|^E:' $LOG)"
echo "Reboot now (new kernel from backports, kvm/gamemode groups)."
echo "Keep stable+backports updated with:  sudo apt update && sudo apt full-upgrade && flatpak update"
