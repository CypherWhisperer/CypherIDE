-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- lua/cide-options.lua
-- NEOVIM OPTIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Pure options only — NO keymaps in this file.
-- All keymaps (including the basic editor ones) live in cide-keymaps.lua.
--
-- Load order in init.lua:
--   1. cide-options.lua   ← sets leader + all vim.opt settings  (YOU ARE HERE)
--   2. cide-keymaps.lua   ← sets basic editor keymaps
--   3. lazy_bootstrap.lua ← loads plugins
--
-- The leader MUST be set before lazy.nvim loads so every plugin that
-- registers <leader> keymaps sees the correct leader key from the start.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ── LEADER — must be first ────────────────────────────────────────────────────
-- Set BEFORE lazy.nvim loads. Any plugin that binds a <leader> mapping reads
-- vim.g.mapleader at load time, so setting it late means those bindings use
-- the default leader ("\") instead of Space.
--
-- maplocalleader is used by some plugins for buffer-local mappings (e.g. vimtex).
-- "\" is the conventional default.
vim.g.mapleader      = " "
vim.g.maplocalleader = "\\"

-- ── LINE NUMBERS ──────────────────────────────────────────────────────────────
-- number + relativenumber together = "hybrid line numbers":
--   • The current line shows its absolute number
--   • All other lines show their distance from the cursor
-- This lets you instantly read jump counts: "5j", "12k", etc.
vim.opt.number         = true
vim.opt.relativenumber = true

-- ── MOUSE ─────────────────────────────────────────────────────────────────────
-- Enable mouse support in all modes. Useful for resizing splits and clicking
-- through Telescope results without needing to count lines.
vim.opt.mouse = "a"

-- ── STATUS LINE ───────────────────────────────────────────────────────────────
-- Disable the built-in mode indicator ("-- INSERT --" at the bottom).
-- lualine shows the mode with better styling — the built-in one is redundant.
vim.opt.showmode = false

-- ── CLIPBOARD ─────────────────────────────────────────────────────────────────
-- Sync Neovim's unnamed register (p/y) with the system clipboard.
-- "unnamedplus" = the X11/Wayland clipboard (Ctrl+C / Ctrl+V in other apps).
-- Requires xclip, xsel, or wl-clipboard to be installed on Linux.
vim.opt.clipboard = "unnamedplus"

-- ── INDENTATION ───────────────────────────────────────────────────────────────
-- breakindent: wrapped lines visually indent to match the opening line.
-- Without it, a long line wraps to column 0, which looks terrible.
vim.opt.breakindent = true

-- Tab/indent settings — set once here via vim.opt. Do NOT also set via vim.cmd.
-- tabstop:    how many columns a literal <Tab> character visually occupies
-- shiftwidth: how many columns >> / << and autoindent use
-- expandtab:  insert spaces when <Tab> is pressed (no literal tab characters)
-- softtabstop is intentionally omitted — with expandtab it equals shiftwidth.
vim.opt.tabstop    = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab  = true

-- ── UNDO ──────────────────────────────────────────────────────────────────────
-- Persist undo history across sessions. Undo after closing and reopening a file.
-- Files are stored in XDG_STATE_HOME/nvim/undo/ (usually ~/.local/state/nvim/undo/).
vim.opt.undofile = true

-- ── SEARCH ────────────────────────────────────────────────────────────────────
-- ignorecase: search is case-insensitive by default (/hello matches Hello)
-- smartcase: if the pattern contains an uppercase letter, becomes case-sensitive
-- Together: /hello → case-insensitive, /Hello → exact match only.
vim.opt.ignorecase = true
vim.opt.smartcase  = true

-- ── SIGN COLUMN ───────────────────────────────────────────────────────────────
-- Always show the sign column (the thin column left of line numbers).
-- Without "yes", the sign column appears/disappears as diagnostics are added
-- or removed — causing the whole buffer to shift left/right. Visually jarring.
vim.opt.signcolumn = "yes"

-- ── TIMING ────────────────────────────────────────────────────────────────────
-- updatetime: how long Neovim waits before writing the swap file and firing
-- CursorHold events. 250ms makes CursorHold-triggered things (like LSP hover)
-- feel instant. Default is 4000ms.
vim.opt.updatetime = 250

-- timeoutlen: how long Neovim waits for the next key in a multi-key mapping.
-- 500ms is a good balance: fast typists don't accidentally trigger prefixes,
-- but which-key has enough time to show its popup before you type the next key.
vim.opt.timeoutlen = 500

-- ── SPLITS ────────────────────────────────────────────────────────────────────
-- Open new splits to the right and below. More intuitive than the defaults
-- (left and above), which feel backwards for most people.
vim.opt.splitright = true
vim.opt.splitbelow = true

-- ── SCROLLING ─────────────────────────────────────────────────────────────────
-- Keep at least 8 lines visible above and below the cursor while scrolling.
-- Prevents the cursor from reaching the very edge of the screen.
vim.opt.scrolloff = 8

-- ── COLORS ────────────────────────────────────────────────────────────────────
-- Enable 24-bit RGB colors. Required for catppuccin and most modern themes.
-- Without this, colors are approximated to the terminal's 256-color palette.
vim.opt.termguicolors = true

-- ── FILES ─────────────────────────────────────────────────────────────────────
-- Disable swap files. With undofile enabled and frequent saves (or auto-save),
-- swap files provide little benefit and create clutter in your directories.
vim.opt.swapfile = false

-- ── COMPLETION ────────────────────────────────────────────────────────────────
-- Don't auto-insert a match, and show the menu even with one item.
-- These apply to Neovim's built-in completion; blink.cmp has its own settings.
vim.opt.completeopt = { "menuone", "noselect" }

-- ── VISUAL ────────────────────────────────────────────────────────────────────
-- Show invisible characters (tabs, trailing spaces, non-breaking spaces).
-- Helps catch unintentional whitespace issues, especially in Python and YAML.
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Highlight the line the cursor is currently on.
-- Combined with relativenumber, makes the current position very obvious.
vim.opt.cursorline = true
