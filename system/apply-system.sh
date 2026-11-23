#!/usr/bin/env bash
# ==============================================================================
# apply-system.sh — HP Omen (Ryzen 7 8845HS) sched-ext & Güç Sistem Kurulumu
# Kullanım: sudo ~/.dotfiles/system/apply-system.sh
# ==============================================================================
set -euo pipefail

if [[ "$EUID" -ne 0 ]]; then
    echo "Bu script root olarak çalıştırılmalı: sudo $0" >&2
    exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET_USER="${1:-${SUDO_USER:-}}"

if [[ -z "$TARGET_USER" || "$TARGET_USER" == "root" ]]; then
    echo "Hedef kullanıcı belirlenemedi. Örnek kullanım: sudo $0 [kullanici_adi]" >&2
    exit 1
fi

if ! TARGET_UID="$(id -u "$TARGET_USER" 2>/dev/null)"; then
    echo "Kullanıcı bulunamadı: $TARGET_USER" >&2
    exit 1
fi

echo "[1/6] Güç & sched-ext sistem dosyaları kuruluyor (kullanıcı: ${TARGET_USER}, uid: ${TARGET_UID})..."
install -Dm644 "$SCRIPT_DIR/scx_loader.toml" /etc/scx_loader.toml

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

sed -e "s|@TARGET_USER@|${TARGET_USER}|g" \
    -e "s|@TARGET_UID@|${TARGET_UID}|g" \
    "$SCRIPT_DIR/power-mode-sys" > "$tmp_dir/power-mode-sys"
install -Dm755 "$tmp_dir/power-mode-sys" /usr/local/bin/power-mode-sys

install -Dm644 "$SCRIPT_DIR/99-power-mode.rules" /etc/udev/rules.d/99-power-mode.rules
install -Dm644 "$SCRIPT_DIR/power-mode-sync.service" /etc/systemd/system/power-mode-sync.service

# sudoers dosyasını önce geçici konumda visudo ile doğrula
sed -e "s|@TARGET_USER@|${TARGET_USER}|g" \
    "$SCRIPT_DIR/sudoers-power-mode" > "$tmp_dir/sudoers-power-mode"
chmod 440 "$tmp_dir/sudoers-power-mode"
visudo -cf "$tmp_dir/sudoers-power-mode"
install -Dm440 -o root -g root "$tmp_dir/sudoers-power-mode" /etc/sudoers.d/power-mode

echo "[2/6] SDDM teması (hypr-minimal) kuruluyor..."
if [[ -d "$SCRIPT_DIR/sddm/themes/hypr-minimal" ]]; then
    SDDM_THEME_DST="/usr/share/sddm/themes/hypr-minimal"
    SDDM_STATE_DIR="/var/lib/sddm-hypr-theme"

    install -d -m755 "$SDDM_THEME_DST/icons"
    install -Dm644 "$SCRIPT_DIR/sddm/themes/hypr-minimal/metadata.desktop" "$SDDM_THEME_DST/metadata.desktop"
    install -Dm644 "$SCRIPT_DIR/sddm/themes/hypr-minimal/theme.conf" "$SDDM_THEME_DST/theme.conf"
    install -Dm644 "$SCRIPT_DIR/sddm/themes/hypr-minimal/Main.qml" "$SDDM_THEME_DST/Main.qml"
    for svg in "$SCRIPT_DIR/sddm/themes/hypr-minimal/icons/"*.svg; do
        install -Dm644 "$svg" "$SDDM_THEME_DST/icons/$(basename "$svg")"
    done
    install -Dm644 "$SCRIPT_DIR/sddm/10-theme.conf" /etc/sddm.conf.d/10-theme.conf

    # Dinamik renk/font/duvar kağıdı verisi (kullanıcı yazar, sddm okur — runtime'da sudo gerekmez)
    install -d -m755 -o "$TARGET_USER" -g sddm "$SDDM_STATE_DIR"
    ln -sfn "$SDDM_STATE_DIR/theme.conf.user" "$SDDM_THEME_DST/theme.conf.user"

    TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
    if [[ -n "$TARGET_HOME" && -x "$TARGET_HOME/.local/bin/sddm-theme-sync" ]]; then
        sudo -u "$TARGET_USER" -H "$TARGET_HOME/.local/bin/sddm-theme-sync" || true
    fi
fi

echo "[3/6] systemd ve udev yeniden yükleniyor..."
systemctl daemon-reload
udevadm control --reload-rules

echo "[4/6] ananicy-cpp devre dışı bırakılıyor (scx_lavd ile çakışmayı önlemek için)..."
systemctl disable --now ananicy-cpp.service 2>/dev/null || true

echo "[5/6] power-profiles-daemon, scx_loader, power-mode-sync ve paccache.timer etkinleştiriliyor..."
systemctl enable --now power-profiles-daemon.service
systemctl enable --now scx_loader.service
systemctl enable power-mode-sync.service
systemctl enable --now paccache.timer 2>/dev/null || true

# scx_loader.toml değiştiyse temiz yeniden başlat
systemctl restart scx_loader.service
sleep 1

echo "[6/6] Mevcut güç kaynağına göre ilk senkronizasyon çalıştırılıyor..."
/usr/local/bin/power-mode-sys auto

echo "=== DOĞRULAMA ==="
echo "Güç Profili   : $(powerprofilesctl get 2>/dev/null || echo '?')"
echo "ACPI Profili  : $(cat /sys/firmware/acpi/platform_profile 2>/dev/null || echo '?')"
echo "EPP           : $(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null || echo '?')"
echo "CPU Boost     : $(cat /sys/devices/system/cpu/cpufreq/boost 2>/dev/null || echo '?')"
echo "sched_ext     : $(cat /sys/kernel/sched_ext/state 2>/dev/null || echo '?') ($(cat /sys/kernel/sched_ext/root/ops 2>/dev/null || echo '-'))"
echo "scxctl        : $(scxctl get 2>/dev/null || echo '?')"
echo "ananicy-cpp   : $(systemctl is-active ananicy-cpp.service 2>/dev/null || true)"
echo "SDDM Teması   : $(grep -E '^Current=' /etc/sddm.conf.d/10-theme.conf 2>/dev/null | cut -d= -f2 || echo '?')"
