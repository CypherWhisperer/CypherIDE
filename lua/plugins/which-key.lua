-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- lua/plugins/which-key.lua
-- WHICH-KEY — Keymap Discovery Popup
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- which-key intercepts partially-typed key sequences and pops up a menu
-- showing all possible completions. This is the "cheat sheet" you described:
--
--   Press <leader>        → popup shows: [g]it, [l]sp, [f]ormat, [w]save, etc.
--   Press <leader>g       → popup shows: [s]tatus, [c]ommit, [p]ush, etc.
--
-- It reads the `desc` fields from vim.keymap.set() calls — which every module
-- in this config provides — so the popup is automatically populated from the
-- existing keymap infrastructure. No manual registration needed for most keys.
--
-- GROUP LABELS (defined below) give human-friendly names to prefix keys like
-- <leader>h (git hunk), <leader>t (toggles), etc. so the popup says
-- "Git Hunks" instead of just showing the raw key characters.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

return {
  "folke/which-key.nvim",

  -- Load slightly after startup — which-key only activates when you start
  -- typing a key sequence, so there's no benefit to loading it at file-open.
  --event = "VeryLazy",

  config = function()
    local wk = require("which-key")
    local K  = require("cide-keymaps")

    wk.setup({
      -- ── POPUP APPEARANCE ───────────────────────────────────────────────
      -- Preset: "helix" gives a clean two-column layout similar to what you
      -- described seeing in AstroNvim. Other options: "classic", "modern".
      preset = "helix",

      plugins = {
        -- Show spelling suggestions when pressing z= on a misspelled word.
        spelling = {
          enabled    = true,
          suggestions = 20,
        },
        -- Show which-key for Neovim's built-in presets (g, z, <C-w>, etc.).
        -- These are Vim's own keymaps — which-key can document them too.
        presets = {
          operators    = true,   -- d, y, c, etc.
          motions      = true,   -- gg, G, w, b, etc.
          text_objects = true,   -- after d/y/c: iw, is, ip, etc.
          windows      = true,   -- <C-w> split management
          nav          = true,   -- <C-f>, <C-b>, etc.
          z            = true,   -- folds and scrolling
          g            = true,   -- go-to commands
        },
      },

      -- ── POPUP DELAY ────────────────────────────────────────────────────
      -- How long to wait after you stop typing before showing the popup.
      -- Reads from vim.opt.timeoutlen (set to 500ms in cide-options.lua).
      -- You can override here if you want which-key specifically to show
      -- faster or slower than the general key timeout.
      delay = function(ctx)
        -- Show immediately for <leader> (you almost always want to browse it).
        -- Use the global timeoutlen for other prefixes.
        return ctx.plugin and 0 or vim.o.timeoutlen
      end,

      -- ── ICONS ──────────────────────────────────────────────────────────
      icons = {
        -- Show a breadcrumb in the popup title showing where you are.
        -- e.g. "Leader > Git" when inside <leader>g.
        breadcrumb = "»",
        separator  = "➜",
        group      = "+",   -- prefix for group labels in the popup
        ellipsis   = "…",
        -- Nerd Font icons for key types shown next to each binding.
        mappings   = true,
        -- Rules for which icon to show per binding. Set false to disable icons.
        rules      = {},
        -- which-key uses the sign column colors for unknown/known mappings.
        colors     = true,
        -- Requires nvim-web-devicons (already a dependency of neo-tree / lualine).
        keys       = {
          Up        = " ",  Down    = " ",
          Left      = " ", Right   = " ",
          C         = "󰘴 ", M       = "󰘵 ",
          S         = "󰘶 ", CR      = "󰌑 ",
          Esc       = "󱊷 ", Tab     = "󰌒 ",
          Space     = "󱁐 ", BS      = "󰁮 ",
          ScrollWheelDown = "󱕐 ",
          ScrollWheelUp   = "󱕑 ",
        },
      },

      -- ── WINDOW STYLE ───────────────────────────────────────────────────
      win = {
        border   = "rounded",
        padding  = { 1, 2 },   -- { top/bottom, left/right } padding
        wo = {
          winblend = 10,        -- slight transparency (0 = opaque, 100 = invisible)
        },
      },

      -- ── LAYOUT ─────────────────────────────────────────────────────────
      layout = {
        width  = { min = 20 },  -- minimum column width
        spacing = 3,            -- spacing between columns
      },
    })

    -- ── GROUP LABELS ───────────────────────────────────────────────────────
    -- These give human-readable names to key prefixes in the popup.
    -- Without these, pressing <leader>h would show "h" — with them, it shows
    -- "Git Hunks". You only need to register groups for prefixes that have
    -- multiple bindings under them.
    --
    -- NOTE: Individual keymap descriptions come automatically from the `desc`
    -- field in vim.keymap.set() calls across all plugin files. You don't need
    -- to re-register individual keys here.
    wk.add({

      -- ── TOP-LEVEL LEADER GROUPS ─────────────────────────────────────
      { "<leader>c", group = "Code Actions" },
      { "<leader>d", group = "Document" },
      { "<leader>e", group = "Diagnostics" },
      { "<leader>f", group = "Find / Telescope" },
      { "<leader>g", group = "Git (Fugitive)" },
      { "<leader>h", group = "Git Hunks (Gitsigns)" },
      { "<leader>i", group = "Inlay Hints" },
      { "<leader>m", group = "Manual Format/Lint" },
      { "<leader>r", group = "Rename / Refactor" },
      { "<leader>t", group = "Toggles" },
      { "<leader>w", group = "Workspace" },

      -- ── BRACKET NAVIGATION GROUPS ───────────────────────────────────
      -- ]x / [x pairs are common in Vim. Label them so the popup is useful.
      { "]",         group = "Next →" },
      { "[",         group = "← Prev" },

      -- ── SPECIFIC BINDING DESCRIPTIONS ───────────────────────────────
      -- These override or supplement descriptions for keys that don't go
      -- through vim.keymap.set with a desc (e.g. keys inherited from plugins
      -- or set with an empty opts table).
      {
        K.which_key.show,
        function() wk.show({ global = true }) end,
        desc = "which-key: show all keymaps",
        mode = "n",
      },
    })
  end,
}
