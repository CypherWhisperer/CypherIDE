-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- lua/plugins/nvim-tmux-navigation.lua
-- PANE / SPLIT NAVIGATION (Neovim + tmux unified)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- nvim-tmux-navigation makes <C-h/j/k/l> work seamlessly across both
-- Neovim splits and tmux panes — the same key moves you regardless of
-- whether the next "window" is a Neovim split or a tmux pane.
--
-- CURRENT KEY ASSIGNMENTS:
--   <C-j>   → move down  (Neovim split or tmux pane)
--   <C-k>   → move up    (Neovim split or tmux pane)
--   <M-h>   → move left  (TEMPORARY — see note below)
--   <M-l>   → move right (TEMPORARY — see note below)
--
-- WHY <M-h> / <M-l> INSTEAD OF <C-h> / <C-l>?
--   GNOME (and Plasma/Hyprland in the planned CypherOS lenses) intercepts
--   Ctrl+H and Ctrl+L at the DE level for workspace navigation.
--   Those keystrokes never reach the terminal or Neovim.
--   Alt+h/l (Meta key) are DE-safe on all three compositors.
--
-- TODO: Once DE-level conflicts are resolved:
--   1. Update cide-keymaps.lua:  nav_left = "<C-h>",  nav_right = "<C-l>"
--   2. Configure tmux.conf:      bind -n C-h ... / bind -n C-l ...
--   The plugin config below reads from cide-keymaps.lua, so step 1 is the
--   only change needed here.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

return {
  "alexghergh/nvim-tmux-navigation",

  -- Load early — pane navigation should work from the first keypress.
  --event = "VeryLazy",

  config = function()
    local K   = require("cide-keymaps")
    local nav = require("nvim-tmux-navigation")

    nav.setup({
      -- disable_when_zoomed: when a tmux pane is zoomed (full-screen),
      -- don't try to navigate out of it — let the keys fall through to Neovim.
      disable_when_zoomed = true,
    })

    -- ── NAVIGATION KEYMAPS ──────────────────────────────────────────────
    -- All four directions wired from the SSOT.
    -- These supersede the wincmd-based keymaps that were previously in
    -- cide-options.lua — no need to have both.
    vim.keymap.set("n", K.nav_left,  nav.NvimTmuxNavigateLeft,  { desc = "Nav: move left",  noremap = true, silent = true })
    vim.keymap.set("n", K.nav_right, nav.NvimTmuxNavigateRight, { desc = "Nav: move right", noremap = true, silent = true })
    vim.keymap.set("n", K.nav_up,    nav.NvimTmuxNavigateUp,    { desc = "Nav: move up",    noremap = true, silent = true })
    vim.keymap.set("n", K.nav_down,  nav.NvimTmuxNavigateDown,  { desc = "Nav: move down",  noremap = true, silent = true })
  end,
}
