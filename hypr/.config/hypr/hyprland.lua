-- ==============================================================================
-- Hyprland Ana Yapılandırma (0.57+ Lua) — CachyOS AI-Assisted DIY
-- ==============================================================================

if package and package.loaded then
    package.loaded["colors"] = nil
end
local colors = require("colors")

-- Ekran (HP Omen 17.3" 2560x1440 @ 240Hz — port adını `hyprctl monitors` ile doğrula)
hl.monitor({
    output = "eDP-1",
    mode = "2560x1440@240",
    position = "0x0",
    scale = 1.25,
})

-- Diğer / harici ekranlar için varsayılan
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1,
})

-- Ortam Değişkenleri (Saf AMD Radeon 780M + Wayland)
hl.env("XCURSOR_THEME", "Adwaita")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("SDL_VIDEODRIVER", "wayland,x11")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Genel Görünüm, Dekorasyon, Giriş & Sistem Ayarları
hl.config({
    xwayland = {
        force_zero_scaling = true,
    },

    general = {
        gaps_in = 5,
        gaps_out = 10,
        border_size = 2,
        col = {
            active_border = {
                colors = { colors.accent, colors.accent_alt },
                angle = 45,
            },
            inactive_border = colors.border_inactive,
        },
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 12,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 0.96,

        shadow = {
            enabled = true,
            range = 16,
            render_power = 3,
            color = "rgba(00000044)",
        },

        blur = {
            enabled = true,
            size = 6,
            passes = 2,
            new_optimizations = true,
            ignore_opacity = true,
            vibrancy = 0.16,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
        smart_split = false,
    },

    input = {
        kb_layout = "tr",
        follow_mouse = 1,
        sensitivity = 0,

        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
            drag_lock = false,
            disable_while_typing = true,
        },
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        background_color = colors.bg,
        focus_on_activate = true,
    },

    debug = {
        vfr = true,
    },
})

-- Akıcı, Göz Yormayan Animasyonlar
hl.curve("calmOut", {
    type = "bezier",
    points = { { 0.22, 1.0 }, { 0.36, 1.0 } },
})
hl.curve("calmInOut", {
    type = "bezier",
    points = { { 0.45, 0.0 }, { 0.55, 1.0 } },
})
hl.curve("softPop", {
    type = "bezier",
    points = { { 0.16, 1.0 }, { 0.3, 1.0 } },
})

hl.animation({ leaf = "windows", enabled = true, speed = 4.5, bezier = "calmOut", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "calmOut", style = "popin 85%" })
hl.animation({ leaf = "border", enabled = true, speed = 6, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "calmInOut" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4.5, bezier = "calmOut", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "softPop", style = "slidevert" })

-- Touchpad Hareketleri (3 parmakla çalışma alanı geçişi)
hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

-- Modüler dosyaları yükle (hyprctl reload'da güncel kalması için önbelleği temizle)
require("autostart")
for _, mod in ipairs({ "workspaces", "keybinds", "windowrules" }) do
    if package and package.loaded then
        package.loaded[mod] = nil
    end
    require(mod)
end
