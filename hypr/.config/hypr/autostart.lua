-- ==============================================================================
-- Başlangıç Servisleri (Autostart)
-- ==============================================================================

hl.on("hyprland.start", function()
    -- Polkit (GUI yetki pencereleri için)
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")

    -- Duvar kağıdı motoru (awww) ve son duvar kağıdını geri yükleme
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("sleep 0.5 && awww restore || true")

    -- Üst Bar ve Bildirim Merkezi
    hl.exec_cmd("waybar")
    hl.exec_cmd("swaync")

    -- Kilit, Uyku & Gece Işığı (Mavi Işık Filtresi)
    hl.exec_cmd("hypridle")
    hl.exec_cmd("hyprsunset")

    -- Pano Geçmişi (Metin ve görsel)
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Sistem tepsisi ağ yöneticisi
    hl.exec_cmd("nm-applet --indicator")
end)
