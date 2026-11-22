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

echo "[1/5] Sistem dosyaları kuruluyor..."
install -Dm644 "$SCRIPT_DIR/scx_loader.toml" /etc/scx_loader.toml
install -Dm755 "$SCRIPT_DIR/power-mode-sys" /usr/local/bin/power-mode-sys
install -Dm644 "$SCRIPT_DIR/99-power-mode.rules" /etc/udev/rules.d/99-power-mode.rules
install -Dm644 "$SCRIPT_DIR/power-mode-sync.service" /etc/systemd/system/power-mode-sync.service

# sudoers dosyasını önce geçici konumda visudo ile doğrula
tmp_sudoers="$(mktemp)"
trap 'rm -f "$tmp_sudoers"' EXIT
install -m440 "$SCRIPT_DIR/sudoers-power-mode" "$tmp_sudoers"
visudo -cf "$tmp_sudoers"
install -Dm440 -o root -g root "$tmp_sudoers" /etc/sudoers.d/power-mode

echo "[2/5] systemd ve udev yeniden yükleniyor..."
systemctl daemon-reload
udevadm control --reload-rules

echo "[3/5] ananicy-cpp devre dışı bırakılıyor (scx_lavd ile çakışmayı önlemek için)..."
systemctl disable --now ananicy-cpp.service 2>/dev/null || true

echo "[4/5] power-profiles-daemon, scx_loader ve power-mode-sync etkinleştiriliyor..."
systemctl enable --now power-profiles-daemon.service
systemctl enable --now scx_loader.service
systemctl enable power-mode-sync.service

# scx_loader.toml değiştiyse temiz yeniden başlat
systemctl restart scx_loader.service
sleep 1

echo "[5/5] Mevcut güç kaynağına göre ilk senkronizasyon çalıştırılıyor..."
/usr/local/bin/power-mode-sys auto

echo "=== DOĞRULAMA ==="
echo "Güç Profili   : $(powerprofilesctl get 2>/dev/null || echo '?')"
echo "ACPI Profili  : $(cat /sys/firmware/acpi/platform_profile 2>/dev/null || echo '?')"
echo "EPP           : $(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null || echo '?')"
echo "CPU Boost     : $(cat /sys/devices/system/cpu/cpufreq/boost 2>/dev/null || echo '?')"
echo "sched_ext     : $(cat /sys/kernel/sched_ext/state 2>/dev/null || echo '?') ($(cat /sys/kernel/sched_ext/root/ops 2>/dev/null || echo '-'))"
echo "scxctl        : $(scxctl get 2>/dev/null || echo '?')"
echo "ananicy-cpp   : $(systemctl is-active ananicy-cpp.service 2>/dev/null || true)"
