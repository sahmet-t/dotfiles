#!/usr/bin/env bash
# ==============================================================================
# CachyOS (No Desktop) + Hyprland Dotfiles Kurulum Scripti
# ==============================================================================
set -euo pipefail

if [[ "$EUID" -eq 0 ]]; then
    echo "Lütfen bu scripti root (sudo) olarak değil, normal kullanıcınla çalıştır."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

echo "================================================================"
echo "  CachyOS + Hyprland Dotfiles Kurulumu"
echo "================================================================"

# 0. Kurulum öncesi güvenlik snapshot'ı (Snapper mevcutsa)
if command -v snapper >/dev/null 2>&1 && sudo snapper list >/dev/null 2>&1; then
    echo "[0/6] Kurulum öncesi güvenlik snapshot'ı alınıyor..."
    sudo snapper create -d "install.sh oncesi" || true
fi

# 1. Klasörü ~/.dotfiles konumuna taşı / senkronize et
if [[ "$SCRIPT_DIR" != "$DOTFILES_DIR" ]]; then
    echo "[1/6] Dotfiles klasörü $DOTFILES_DIR konumuna kopyalanıyor..."
    mkdir -p "$DOTFILES_DIR"
    cp -a "$SCRIPT_DIR/." "$DOTFILES_DIR/"
else
    echo "[1/6] Zaten $DOTFILES_DIR konumundan çalışıyor."
fi

# 2. Resmi CachyOS / Arch Paketleri (tamamı hazır binary)
echo "[2/6] Resmi çekirdek ve masaüstü paketleri kuruluyor..."
PACMAN_PKGS=(
    # Giriş Ekranı (No Desktop kurulumu için)
    sddm

    # Hyprland & Masaüstü Bileşenleri
    hyprland waybar rofi swaync awww hyprlock hypridle hyprsunset
    hyprshot satty cliphist wl-clipboard brightnessctl
    polkit-gnome xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    libnotify xdg-user-dirs pipewire-pulse wireplumber bluez bluez-utils

    # Günlük GUI Araçları & Terminal
    ghostty btop nautilus gvfs gvfs-mtp gnome-keyring gsettings-desktop-schemas
    loupe celluloid sushi 7zip gnome-calculator pear-desktop playerctl
    nm-connection-editor network-manager-applet
    adw-gtk-theme qt6ct qt6-wayland

    # Dotfiles & AUR Derleme Altyapısı
    stow git base-devel

    # Tema Motoru & Fontlar
    matugen ttf-jetbrains-mono-nerd inter-font noto-fonts noto-fonts-emoji
    ttf-ibm-plex ttf-fira-sans otf-geist-mono-nerd ttf-cascadia-code-nerd ttf-iosevkaterm-nerd
)
sudo pacman -Syu --needed "${PACMAN_PKGS[@]}"

# 3. Sistem Servisleri, Dual-Boot Saati & Bildirim Çakışma Kontrolü
echo "[3/6] SDDM, Bluetooth ve dual-boot saati ayarlanıyor..."
# Not: TTY içindeyken ekranı kesmemek için sddm yalnızca 'enable' yapılır (reboot sonrası açılır)
sudo systemctl enable sddm || true
sudo systemctl enable --now bluetooth || true

# Dual-Boot Windows 11 ile saat kaymasını önle
sudo timedatectl set-local-rtc 1 --adjust-system-clock || true

# swaync ile D-Bus üzerinde çakışabilecek bildirim servislerini kontrol et (No Desktop'ta sessizce geçer)
CONFLICT_DAEMONS=()
for pkg in mako dunst; do
    if pacman -Qq "$pkg" >/dev/null 2>&1; then
        CONFLICT_DAEMONS+=("$pkg")
    fi
done
if [[ ${#CONFLICT_DAEMONS[@]} -gt 0 ]]; then
    echo "UYARI: swaync ile çakışabilecek bildirim servisleri bulundu: ${CONFLICT_DAEMONS[*]}"
    read -r -p "Kaldırılsın mı? [E/h] " ans || ans="h"
    if [[ "${ans:-E}" =~ ^[EeYy]?$ ]]; then
        sudo pacman -Rns --noconfirm "${CONFLICT_DAEMONS[@]}" || true
    fi
fi

# 4. Mevcut Config Yedekleme, XDG Dizinleri, GNU Stow & Varsayılan Tema
# Not: Bu adım AUR'dan önce yapılır ki en kötü senaryoda bile masaüstü %100 hazır olsun.
echo "[4/6] Ayarlar GNU Stow ile bağlanıyor ve Everforest teması uygulanıyor..."
xdg-user-dirs-update >/dev/null 2>&1 || true
PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || true)"
PICTURES_DIR="${PICTURES_DIR:-$HOME/Pictures}"

mkdir -p "$BACKUP_DIR" "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share/applications" \
         "$PICTURES_DIR/Wallpapers" "$PICTURES_DIR/Screenshots"

for dir in hypr waybar rofi swaync ghostty btop paru matugen gtk-3.0 gtk-4.0; do
    if [[ -e "$HOME/.config/$dir" && ! -L "$HOME/.config/$dir" ]]; then
        mv "$HOME/.config/$dir" "$BACKUP_DIR/"
    fi
done

# Ventoy (exFAT) USB'den kopyalanınca tüm dosyalar 755 gelebilir; izinleri temizle
find "$DOTFILES_DIR" -not -path "$DOTFILES_DIR/.git/*" -type f -exec chmod 644 {} +
chmod +x "$DOTFILES_DIR/scripts/.local/bin/"*
chmod +x "$DOTFILES_DIR/scripts/.local/share/nautilus/scripts/"* 2>/dev/null || true
chmod +x "$DOTFILES_DIR/install.sh"

cd "$DOTFILES_DIR"
stow --restow --target="$HOME" hypr waybar rofi swaync ghostty btop micro paru gtk matugen themes scripts

# GTK Koyu Tema, İmleç & Varsayılan Terminal / MIME Eşleştirmeleri
if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' || true
    gsettings set org.gnome.desktop.interface font-name 'Inter 10.5' || true
    gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 10.5' || true
    gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita' || true
    gsettings set org.gnome.desktop.default-applications.terminal exec 'ghostty' || true
    gsettings set org.gnome.desktop.default-applications.terminal exec-arg '-e' || true
fi

if command -v xdg-mime >/dev/null 2>&1; then
    xdg-mime default org.gnome.Loupe.desktop image/png image/jpeg image/webp image/gif image/bmp image/avif image/svg+xml || true
    xdg-mime default io.github.celluloid_player.Celluloid.desktop video/mp4 video/x-matroska video/webm video/quicktime video/x-msvideo audio/mpeg audio/flac audio/ogg audio/wav audio/mp4 audio/x-opus+ogg || true
    xdg-mime default zen.desktop application/pdf || true
fi

# Yerel Git Deposu & skip-worktree
if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
    git init -b main
    git add .
    git -c user.name="Dotfiles User" -c user.email="user@localhost" commit -m "feat: initial CachyOS and Hyprland dotfiles" || true
fi

# Üretilen renk/font dosyalarının tema değişikliklerinde git status'ü kirletmesini önle
GENERATED_FILES=(
    "hypr/.config/hypr/colors.lua"
    "hypr/.config/hypr/colors.conf"
    "waybar/.config/waybar/colors.css"
    "waybar/.config/waybar/font.css"
    "rofi/.config/rofi/colors.rasi"
    "rofi/.config/rofi/font.rasi"
    "swaync/.config/swaync/colors.css"
    "swaync/.config/swaync/font.css"
    "ghostty/.config/ghostty/theme"
    "ghostty/.config/ghostty/font"
    "gtk/.config/gtk-3.0/colors.css"
    "gtk/.config/gtk-4.0/colors.css"
)
git update-index --skip-worktree "${GENERATED_FILES[@]}" || true

"$HOME/.local/bin/theme-apply" --preset everforest || true

# 5. Ek / AUR Paketleri (paru — en sonda, masaüstü zaten güvende)
echo "[5/6] Ek ve AUR paketleri kuruluyor..."
if ! command -v paru >/dev/null 2>&1; then
    sudo pacman -S --needed paru || true
fi

if command -v paru >/dev/null 2>&1; then
    echo ">>> Hazır binary paketler kuruluyor: zen-browser-bin, overskride-bin, maplemono-nf..."
    paru -S --needed --skipreview zen-browser-bin overskride-bin maplemono-nf \
        || echo "UYARI: zen-browser-bin / overskride-bin / maplemono-nf kurulamadı; masaüstü açılınca elle kurabilirsin."

    echo ""
    echo "================================================================"
    echo "  BİLGİ: Sıradaki paket 'pwvucontrol' kaynak koddan (Rust) derlenecek."
    echo "  Bu işlem 2-4 dakika sürebilir ve arada sessiz kalabilir."
    echo "  Sistem DONMADI — lütfen Ctrl+C yapmadan bitmesini bekle!"
    echo "================================================================"
    echo ""
    paru -S --needed --skipreview pwvucontrol \
        || echo "UYARI: pwvucontrol kurulamadı; masaüstü açılınca 'paru -S pwvucontrol' ile deneyebilirsin."
else
    echo "UYARI: paru bulunamadı. Şu paketleri daha sonra elle kurabilirsin:"
    echo "  zen-browser-bin overskride-bin pwvucontrol"
fi

# 6. Tamamlandı
echo ""
echo "[6/6] Kurulum tamamlandı!"
echo "================================================================"
echo "  Her şey hazır!"
echo "  - Şimdi 'reboot' yazıp sistemi yeniden başlat."
echo "  - SDDM giriş ekranında 'Hyprland' oturumunu seç."
echo "  - İlk açılışta 'hyprctl configerrors' ile config hatası olmadığını doğrula."
echo "  - Tema / Duvar Kağıdı / Font Menüsü     : Super + Shift + T"
echo "  - Güç Menüsü (Kapat/Yeniden Başlat/Çık) : Super + Shift + Escape"
echo "  - Üst Barı Gizle / Göster               : Super + B"
echo "  - Duvar kağıtlarını şuraya koy          : $PICTURES_DIR/Wallpapers"
echo "================================================================"
