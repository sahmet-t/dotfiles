-- ==============================================================================
-- Kısayollar (Keybinds — Hyprland 0.57+ Lua)
-- ==============================================================================

local mod = "SUPER"

-- Temel Uygulamalar
hl.bind(mod .. " + Return", hl.dsp.exec_cmd("ghostty"))
hl.bind(mod .. " + Space", hl.dsp.exec_cmd("rofi -show drun"))
hl.bind(mod .. " + E", hl.dsp.exec_cmd("nautilus"))
hl.bind(mod .. " + W", hl.dsp.exec_cmd("zen-browser"))

-- Tema, Duvar Kağıdı, Font & Odak Modu
hl.bind(mod .. " + SHIFT + T", hl.dsp.exec_cmd("~/.local/bin/theme-menu"))
hl.bind(mod .. " + B", hl.dsp.exec_cmd("pkill -SIGUSR1 waybar"))
hl.bind(mod .. " + N", hl.dsp.exec_cmd("swaync-client -t -sw"))

-- Pano Geçmişi & Ekran Görüntüsü
hl.bind(mod .. " + SHIFT + V", hl.dsp.exec_cmd('cliphist list | rofi -dmenu -p "Pano" | cliphist decode | wl-copy'))
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd("~/.local/bin/screenshot region"))
hl.bind("Print", hl.dsp.exec_cmd("~/.local/bin/screenshot full"))

-- Oturum & Kilit
hl.bind(mod .. " + Escape", hl.dsp.exec_cmd("pidof hyprlock || hyprlock"))
hl.bind(mod .. " + SHIFT + Escape", hl.dsp.exec_cmd("~/.local/bin/power-menu"))

-- Pencere Yönetimi
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mod .. " + M", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + P", hl.dsp.window.pseudo())
hl.bind(mod .. " + T", hl.dsp.layout("togglesplit"))

-- Odak Hareketi (Ok tuşları + Vim tuşları)
hl.bind(mod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + down", hl.dsp.focus({ direction = "down" }))

hl.bind(mod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + J", hl.dsp.focus({ direction = "down" }))

-- Pencere Taşıma
hl.bind(mod .. " + SHIFT + left", hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mod .. " + SHIFT + up", hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + down", hl.dsp.window.move({ direction = "down" }))

-- Çalışma Alanları (1-5) & Pencere Gönderme
for i = 1, 5 do
    hl.bind(mod .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

-- Scratchpad (Hızlı Açılır/Kapanır Gizli Alan)
hl.bind(mod .. " + minus", hl.dsp.workspace.toggle_special("scratchpad"))
hl.bind(mod .. " + SHIFT + minus", hl.dsp.window.move({ workspace = "special:scratchpad" }))

-- Fare ile Pencere Taşıma / Boyutlandırma
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop Ses & Parlaklık Tuşları
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.2 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.2 @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })
