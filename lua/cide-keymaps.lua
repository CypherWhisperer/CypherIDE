-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- lua/cide-keymaps.lua
-- SINGLE SOURCE OF TRUTH — ALL KEYBINDINGS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Every keymap in this config is declared in this file.
-- Other modules import this table instead of hardcoding strings.
--
-- USAGE in plugin files:
--   local K = require("cide-keymaps")
--   vim.keymap.set("n", K.lsp.hover, vim.lsp.buf.hover, opts)
--
-- BENEFITS:
--   • Change a key once — updates everywhere automatically
--   • Conflict detection is easy (everything is visible in one place)
--   • which-key.nvim reads the `desc` fields here for its popup
--   • Audit your entire keymap surface without opening plugin files
--
-- LEADER NOTE:
--   vim.g.mapleader is set in cide-options.lua, which loads before this file.
--   The `leader` field below is documentation only — it does NOT set the leader.
--   Changing it here alone will have no effect; change it in cide-options.lua too.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ── SECTION: BASIC EDITOR KEYMAPS ────────────────────────────────────────────
-- These are set immediately (not inside a plugin's config function) because
-- they don't depend on any plugin being loaded. They apply globally.

-- Clear search highlight on <Esc> in normal mode.
-- A single authoritative binding
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Editor: clear search highlight" })

-- File operations
vim.keymap.set("n", "<leader>w", "<cmd>w<CR>",  { noremap = true, silent = true, desc = "Editor: save file" })
vim.keymap.set("n", "<leader>q", "<cmd>q<CR>",  { noremap = true, silent = true, desc = "Editor: quit" })

-- Centered scrolling — keeps your eye on context while jumping half-pages.
-- zz recenters the view so the cursor line sits in the middle of the screen.
vim.keymap.set("n", "<C-d>", "<C-d>zz", { noremap = true, silent = true, desc = "Editor: scroll down (centered)" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { noremap = true, silent = true, desc = "Editor: scroll up (centered)" })

-- Better visual-mode indent: after shifting, reselect the block so you can
-- indent multiple times without re-selecting each time.
vim.keymap.set("v", "<", "<gv", { noremap = true, silent = true, desc = "Editor: indent left (stay selected)" })
vim.keymap.set("v", ">", ">gv", { noremap = true, silent = true, desc = "Editor: indent right (stay selected)" })

-- Move selected lines up/down in visual mode.
-- J/K in visual mode are normally "join lines" / move; we remap to line-move.
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { noremap = true, silent = true, desc = "Editor: move selection down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { noremap = true, silent = true, desc = "Editor: move selection up" })

-- Paste without overwriting the unnamed register.
-- Without this, pasting over a visual selection replaces your clipboard with
-- the text you just deleted — forcing you to paste the wrong thing next time.
vim.keymap.set("v", "p", '"_dP', { noremap = true, silent = true, desc = "Editor: paste without clobbering register" })

-- ── SECTION: KEYMAP TABLE (SSOT) ─────────────────────────────────────────────
-- This table is what plugin files import. Keys are the actual key strings
-- that get passed to vim.keymap.set(). Descriptions are picked up by which-key.
-- ─────────────────────────────────────────────────────────────────────────────

return {

  leader = " ",   -- Space. Documentation only — set in cide-options.lua.

  -- ── LSP ────────────────────────────────────────────────────────────────────
  -- Set inside the LspAttach autocmd (buffer-local). See lsp-config.lua.
  lsp = {
    hover             = "K",
    definition        = "gd",
    declaration       = "gD",
    type_definition   = "go",
    implementation    = "gi",
    references        = "gr",
    -- <C-k> is intentionally NOT used here — it is owned by tmux navigation.
    -- Signature help lives in insert mode only, on <C-s> which is rarely used
    -- in insert mode and doesn't conflict with any pane/tmux binding.
    signature_help_i  = "<C-s>",   -- insert mode: show parameter signature
    signature_help_n  = "gK",      -- normal mode: show parameter signature
    rename            = "<leader>rn",
    code_action       = "<leader>ca",
    format            = "<leader>f",
    diagnostic_float  = "<leader>e",
    diagnostic_next   = "]d",
    diagnostic_prev   = "[d",
    error_next        = "]e",
    error_prev        = "[e",
    document_symbols  = "<leader>ds",
    workspace_symbols = "<leader>ws",
    inlay_hints       = "<leader>ih",
  },

  -- ── GIT ────────────────────────────────────────────────────────────────────
  -- gitsigns keys are buffer-local (set in on_attach). See git.lua.
  -- fugitive keys are global (set in config). See git.lua.
  git = {
    -- gitsigns — hunk navigation
    next_hunk         = "]h",
    prev_hunk         = "[h",
    -- gitsigns — staging
    stage_hunk        = "<leader>hs",
    reset_hunk        = "<leader>hr",
    undo_stage        = "<leader>hu",
    stage_buffer      = "<leader>hS",
    reset_buffer      = "<leader>hR",
    -- gitsigns — inspection
    preview_hunk      = "<leader>hp",
    blame_line        = "<leader>hb",
    toggle_blame      = "<leader>tb",
    diff_index        = "<leader>hd",
    diff_head         = "<leader>hD",
    toggle_deleted    = "<leader>td",
    -- fugitive — global git workflow
    status            = "<leader>gs",
    commit            = "<leader>gc",
    push              = "<leader>gp",
    pull              = "<leader>gl",
    log               = "<leader>gL",
    diff_split        = "<leader>gd",
    blame_file        = "<leader>gb",
  },

  -- ── FORMATTING / LINTING ───────────────────────────────────────────────────
  -- Set in linting-and-formatting.lua.
  format = {
    manual_format = "<leader>mp",
    manual_lint   = "<leader>ml",
  },

  -- ── FILE EXPLORER ──────────────────────────────────────────────────────────
  neo_tree = {
    -- <C-b> mirrors the VSCode sidebar toggle (Ctrl+B).
    -- NOTE: <C-b> scrolls up in insert mode, but neo-tree opens in normal mode
    -- so this does not conflict in practice.
    toggle = "<C-b>",
  },

  oil = {
    -- "-" is the oil.nvim convention: "go up to the parent directory" feel.
    -- Opens oil in a floating window over the current buffer.
    open_float = "-",
  },

  -- ── TELESCOPE ──────────────────────────────────────────────────────────────
  -- Set in telescope.lua.
  telescope = {
    find_files   = "<C-p>",         -- Ctrl+P: the universal "find file" shortcut
    live_grep    = "<leader>fg",
    buffers      = "<leader>fb",
    help_tags    = "<leader>fh",
    diagnostics  = "<leader>fd",
    resume       = "<leader>fr",    -- re-open last telescope picker with results
    oldfiles     = "<leader>fo",    -- recently opened files
  },

  -- ── PANE / WINDOW NAVIGATION ───────────────────────────────────────────────
  -- Owned by nvim-tmux-navigation. These work both inside Neovim splits
  -- and across tmux panes (when tmux is running).
  --
  -- <C-h> / <C-l>: TEMPORARILY mapped to <M-h> / <M-l> (Alt+h/l).
  -- Reason: GNOME (and Plasma/Hyprland in planned CypherOS lenses) uses
  -- Ctrl+H and Ctrl+L for workspace/window operations at the DE level —
  -- those keystrokes never reach Neovim. Alt+h/l are DE-safe.
  --
  -- TODO: Once DE-level Ctrl+H/L conflicts are resolved, change these back:
  --   nav_left  = "<C-h>",
  --   nav_right = "<C-l>",
  nav_left  = "<M-h>",
  nav_right = "<M-l>",
  nav_up    = "<C-k>",
  nav_down  = "<C-j>",

  -- ── WHICH-KEY ──────────────────────────────────────────────────────────────
  -- which-key shows a popup of available keymaps when you pause after a prefix.
  -- These control the manual triggers (you rarely need them — the popup appears
  -- automatically after `timeoutlen` ms).
  which_key = {
    show = "<leader>?",   -- show ALL keymaps as a searchable list
  },
}
