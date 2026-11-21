-- ==============================================================================
-- Çalışma Alanları (Workspaces)
-- 1: Tarayıcı / Araştırma  |  2: Geliştirme / AI  |  3: Notlar / 2. Beyin
-- 4: Medya / Odak          |  5: Genel / Deneme
-- ==============================================================================

hl.workspace_rule({ workspace = "1", default = true })
hl.workspace_rule({ workspace = "2" })
hl.workspace_rule({ workspace = "3" })
hl.workspace_rule({ workspace = "4" })
hl.workspace_rule({ workspace = "5" })
hl.workspace_rule({ workspace = "special:scratchpad", gaps_out = 40 })
