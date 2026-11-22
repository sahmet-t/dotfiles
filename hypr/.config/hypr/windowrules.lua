-- ==============================================================================
-- Pencere Kuralları (Hyprland 0.57+ Lua)
-- ==============================================================================

-- Ses Kontrolü (pwvucontrol) — Ortada şık yüzer pencere
hl.window_rule({
    name = "float-pwvucontrol",
    match = { class = "^(com\\.saivert\\.pwvucontrol|org\\.pulseaudio\\.pavucontrol)$" },
    float = true,
    center = true,
    size = { 760, 520 },
})

-- Bluetooth (Overskride)
hl.window_rule({
    name = "float-overskride",
    match = { class = "^(io\\.github\\.kaii_lb\\.Overskride)$" },
    float = true,
    center = true,
    size = { 720, 520 },
})

-- Ağ Bağlantı Düzenleyici
hl.window_rule({
    name = "float-nm-editor",
    match = { class = "^(nm-connection-editor)$" },
    float = true,
    center = true,
    size = { 640, 480 },
})

-- Tema & Sistem Ayar Araçları
hl.window_rule({
    name = "float-system-tools",
    match = { class = "^(nwg-look|qt6ct|cachyos-hello)$" },
    float = true,
    center = true,
    size = { 860, 600 },
})

-- Ekran Görüntüsü İşaretleme (Satty)
hl.window_rule({
    name = "float-satty",
    match = { class = "^(com\\.gabm\\.satty)$" },
    float = true,
    center = true,
})

-- Nautilus (Dosya Yöneticisi) — Ghostty ile uyumlu hafif buzlu cam saydamlığı
hl.window_rule({
    name = "nautilus-opacity",
    match = { class = "^(org\\.gnome\\.Nautilus)$" },
    opacity = "0.94 0.91",
})

-- Hesap Makinesi (GNOME Calculator)
hl.window_rule({
    name = "float-calculator",
    match = { class = "^(org\\.gnome\\.Calculator)$" },
    float = true,
    center = true,
    size = { 420, 560 },
})

-- Nautilus Hızlı Önizleme (Sushi — Space tuşu)
hl.window_rule({
    name = "float-sushi",
    match = { class = "^(org\\.gnome\\.NautilusPreviewer)$" },
    float = true,
    center = true,
})

-- Pear Desktop (YouTube Music) — Ghostty & Nautilus ile uyumlu buzlu cam saydamlığı
hl.window_rule({
    name = "pear-desktop-opacity",
    match = { class = "^(com\\.github\\.th-ch\\.youtube-music|pear-desktop)$" },
    opacity = "0.94 0.91",
})
