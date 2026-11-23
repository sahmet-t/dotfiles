# dotfiles

CachyOS (`No Desktop`) için Hyprland 0.57+ (Lua) yapılandırması. Kullanıcı ayarları GNU Stow ile yönetilir; güç profilleri, `sched-ext` ve SDDM giriş ekranı `system/` altındaki kurucu ile uygulanır.

## Bileşenler

| Alan | Araç |
| :--- | :--- |
| Dağıtım | CachyOS (`linux-cachyos`, Limine, Btrfs + Snapper) |
| Pencere Yöneticisi | Hyprland 0.57+ (Lua) |
| Giriş Ekranı | SDDM (`hypr-minimal`, özel Qt6 QML teması) |
| Üst Bar & Bildirim | Waybar, SwayNC |
| Başlatıcı & Pano | Rofi (Wayland), `cliphist` |
| Terminal & Editör | Ghostty, `micro`, `btop` |
| Duvar Kağıdı & Tema | `awww`, Matugen 4.2 (`scheme-fidelity`) |
| Ekran Görüntüsü | `grim`, `slurp`, `satty` |
| Günlük Araçlar | Zen Browser, Nautilus, Loupe, Celluloid, Pear Desktop |
| Güç & Zamanlayıcı | `scx_lavd --autopower`, `power-profiles-daemon` |
| Paket Yönetimi | `pacman`, `paru` |

## Mimari

- **Tema ve Font Senkronizasyonu (`Super + Shift + T`):** Beş palet (`Catppuccin Mocha`, `Everforest`, `Gruvbox Dark`, `Kanagawa`, `Rosé Pine`) veya duvar kağıdından Matugen ile üretilen renkler; Hyprland, Waybar, Rofi, SwayNC, Ghostty, `btop`, `micro`, GTK3/GTK4 (Libadwaita 1.10+), Pear Desktop ve SDDM'e tek script üzerinden uygulanır.
- **Priz / Pil Otomasyonu:** `udev`, `systemd` ve `power-mode-sys` ile güç kaynağı değiştiğinde donanım ve oturum ayarları otomatik güncellenir. Prizde `balanced` (240 Hz, efektler açık); pilde `power-saver` (60 Hz, CPU boost, blur ve animasyonlar kapalı, AMD ABM ve `pcie_aspm` aktif).
- **Temiz Çalışma Ağacı:** Tema ve font değiştiricilerin üzerine yazdığı 12 dosya `git update-index --skip-worktree` ile işaretlidir; görsel değişiklikler `git status` çıktısında görünmez.

## Kurulum

> Ekran (`eDP-1`, 2560×1440 @ 240 Hz, ölçek `1.25`) ve güç profilleri HP Omen 17-db0015nt (Ryzen 7 8845HS / Radeon 780M) için ayarlıdır. Farklı bir makinede kurmadan önce [`hyprland.lua`](hypr/.config/hypr/hyprland.lua) ve [`system/`](system/) dosyalarını gözden geçirin.

```bash
git clone https://github.com/sahmet-t/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
chmod +x install.sh && ./install.sh
```

Sistem seviyesi güç otomasyonu, `scx_lavd` ve SDDM teması için:

```bash
sudo ~/.dotfiles/system/apply-system.sh
```

## Kısayollar

| Kısayol | İşlev |
| :--- | :--- |
| `Super + Enter` | Terminal (Ghostty) |
| `Super + Space` | Uygulama başlatıcı (Rofi) |
| `Super + W` / `Super + E` | Zen Browser / Nautilus |
| `Super + Shift + T` | Tema, duvar kağıdı ve font menüsü |
| `Super + Shift + S` / `Print` | Bölge / Tam ekran görüntüsü (Satty) |
| `Super + Shift + V` | Pano geçmişi |
| `Super + N` / `Super + B` | Bildirim merkezi / Waybar gizle-göster |
| `Super + Q` / `F` / `V` | Kapat / Tam ekran / Floating |
| `Super + 1..5` / `Super + -` | Çalışma alanları / Scratchpad |
| `Super + Esc` / `Super + Shift + Esc` | Kilitle (`hyprlock`) / Güç menüsü |

## Dizin Yapısı

```text
.
├── btop/               # Ghostty TTY renklerini devralan btop yapılandırması
├── ghostty/            # Terminal ayarları, tema ve font kancaları
├── gtk/                # GTK3 ve GTK4/Libadwaita renk tanımları
├── hypr/               # Hyprland Lua config, hyprlock, hypridle, hyprsunset
├── matugen/            # Duvar kağıdından renk üretimi için şablonlar
├── micro/              # ANSI-16 Ghostty uyumlu editör teması ve ayarları
├── paru/               # AUR yardımcısı yapılandırması
├── rofi/               # Başlatıcı ve menü teması
├── scripts/            # ~/.local/bin altındaki yardımcı scriptler
├── swaync/             # Bildirim merkezi
├── themes/             # Hazır tema paletleri (palette.env)
├── waybar/             # Üst bar modülleri ve stili
├── system/             # /etc, /usr/local/bin, paket listeleri ve SDDM teması
└── install.sh          # Stow ve kullanıcı ortamı kurucusu
```

## Belgeler & Lisans

- [Kurulum Rehberi](KURULUM_REHBERI.md)
- [Paket Yönetimi](PAKET_YONETIMI.md)
- [MIT Lisansı](LICENSE)
