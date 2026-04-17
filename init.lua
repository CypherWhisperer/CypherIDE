-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- configs/editor/cypher-ide/init.lua
-- CypherIDE — Neovim entry point
-- NVIM_APPNAME=cypher-ide
--
-- Part of (submodule of) the CypherOS setup.
-- Managed by Home Manager (modules/apps/neovim.nix).
-- Edit in the CypherOS repo, NOT in the deployed location.
-- Redeploy with:
--     home-manager switch
--     sudo nixos-rebuild [option] --flake /path/to/repo#[host-name]
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ── RTP BOOTSTRAP ─────────────────────────────────────────────────────────────
-- Prepend this config's lua/ directory to the runtime path.
-- Required when the config directory is a Nix store symlink: Neovim's automatic
-- rtp population may resolve through the symlink to the store path rather than
-- the config path, leaving lua/ off the Lua module search path.
--
-- This single prepend is sufficient. The previous config also manually patched
-- package.path — that is NOT needed and caused subtle double-load issues.
-- vim.opt.rtp:prepend already makes Lua's require() find files in lua/.
vim.opt.rtp:prepend(vim.fn.stdpath("config"))

-- ── LOAD ORDER ────────────────────────────────────────────────────────────────
-- 1. Options first — sets vim.g.mapleader BEFORE any plugin loads.
--    Plugins that register <leader> mappings read mapleader at load time,
--    so the leader must be set before lazy.nvim runs.
require("cide-options")

-- 2. Basic editor keymaps — these don't depend on any plugin.
--    Also exports the SSOT table that plugin files import.
require("cide-keymaps")

-- 3. Plugin manager last — lazy.nvim loads all plugins.
--    By this point, options and keymaps are already in place.
require("lazy_bootstrap")
--
-- previous `require("config.lazy")` for lua/config/lazy.lua was 'buggy'
--   Neovim tries to find config/lazy.lua on the Lua module path (package.path) 
--   before lazy.nvim has had any chance to run or modify rtp. 
--
--   At the point require("config.lazy") executes, the only paths Lua searches 
--   are the standard ones — none of which contain your lua/ directory yet 
--   because nothing has set it up.
--
--   lua/config/ isn't on the path at the moment init.lua runs. You can fix this
--   by explicitly prepending your config's lua/ directory to rtp before the 
--   require, right at the top of init.lua:
--
--     `vim.opt.rtp:prepend(vim.fn.stdpath("config"))`
--     `require("config.lazy")` -- now resolvable: lua/config/lazy.lua
--
--     But the cleaner option is to simply drop the file into lua/ 

