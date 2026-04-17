-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- lua/lazy_bootstrap.lua
-- PACKAGE MANAGER: LAZY.NVIM
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Bootstraps lazy.nvim on first launch, then sets it up.
-- lazy.nvim is installed into XDG_DATA_HOME/nvim/lazy/lazy.nvim
-- (resolves to ~/.local/share/nvim/lazy/lazy.nvim, which respects NVIM_APPNAME).
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ─────────────────────────────────────────────────────────────────────────
-- LAZY.NVIM BOOTSTRAP
-- ─────────────────────────────────────────────────────────────────────────
-- Clone lazy.nvim if it isn't present. On subsequent launches, this block
-- does nothing — the fs_stat check is essentially free. 
--
-- On NixOS, lazy.nvim is installed via Nix (pkgs.vimPlugins.lazy-nvim)
-- and injected into Neovim's rtp automatically by the wrapper.
-- We do NOT clone it from GitHub — Nix owns that dependency.
--
-- For non-NixOS fallback (e.g. if someone runs this config on a plain Linux
-- machine), we keep the clone logic as a fallback below.
--
-- Strategy:
--   1. Nix installs lazy-nvim into the wrapper rtp via programs.neovim.plugins.
--      We find it there and prepend its path explicitly before calling setup().
--   2. If not found via Nix (non-NixOS machine), fall back to cloning.
--   3. Never use rtp.reset = true — that would wipe the Nix-injected path.
-- ─────────────────────────────────────────────────────────────────────────

-- Check if lazy.nvim is already on rtp (Nix-provided path)
local lazy_ok = pcall(require, "lazy")

if not lazy_ok then
  --fallback: not on rtp yet, try standard data path (non-NixOS usage)

  -- One variable, set exactly once via whichever path succeeds first.
  -- No nested local re-declarations — that was the scoping bug.
  local lazypath
  
  -- Step 1: try to find the Nix-provided lazy.nvim in the current rtp.
  -- The Nix wrapper adds vimPlugins to rtp before init.lua runs, so we
  -- can search for lazy.nvim's init.lua across all current rtp entries.
  -- i.e
  -- programs.neovim.plugins in neovim.nix puts vimPlugins on rtp before
  -- init.lua runs, so this will find it on NixOS.
  for _, rtp_entry in ipairs(vim.api.nvim_list_runtime_paths()) do
    if rtp_entry:match("lazy%.nvim$") then
      lazypath = rtp_entry
      break
    end
  end

  -- Step 2: if not found in rtp (non-NixOS) via Nix, fall back to standard
  -- data path. 
  -- This handles non-NixOS machines or configs that don't use the Nix plugin.
  if not lazypath then
    lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  end

  -- Third: if the data path also doesn't exist, clone it (true first launch).
  --
  -- As a concequence of an incident of a corrupt lazy clone that prevented 
  -- Neovim from loading the plugins and configuration (lazy not being there 
  -- due to the corrupt clone) the below guard was established:
  --
  -- This catches the corrupt-clone scenario (directory present, working tree absent)
  -- and ensures re-cloning is triggered whenever the actual Lua source is missing,
  -- regardless of whether the directory exists.
  local lazy_main = lazypath .. "/lua/lazy/init.lua" 

  if not (vim.uv or vim.loop).fs_stat(lazy_main) then -- <-  from lazypath -> lazy_main

    -- Not installed at all — clone it (non-NixOS first launch)
    vim.notify("Bootstrapping lazy.nvim...", vim.log.levels.INFO)

    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local result = vim.fn.system({ 
      "git",
      "clone",
      "--filter=blob:none",
      "--branch=stable", 
      lazyrepo, 
      lazypath 
    })

    if vim.v.shell_error ~= 0 then
      vim.api.nvim_echo({
        { "Failed to clone lazy.nvim:\n", "ErrorMsg"},
        { result,                         "WarningMsg" },
        { "\nPress any key to exit...",   "Normal"},
      }, true, {})
      vim.fn.getchar()
      os.exit(1)

      -- prev
      -- error("Failed to clone lazy.nvim:\n" .. result)
    end
  end
  
  -- Step 3: ensure lazypath is at the FRONT of rtp.
  -- vim.opt.rtp:prepend() is idempotent — safe to call even if already present.
  -- prepend to rtp so require("lazy") finds it.
  --
  -- Always prepend regardless of source (Nix or clone).
  -- If it's already in rtp this is a no-op — safe to call unconditionally.
  vim.opt.rtp:prepend(lazypath)
end

-- ─────────────────────────────────────────────────────────────────────────
-- LAZY.NVIM SETUP
-- ─────────────────────────────────────────────────────────────────────────
-- lazy.setup() takes two arguments (tuples):
--   1. Plugin source: a string → scans lua/<string>/ for plugin spec files
--                    or a table → an inline plugin spec list.
--   2. Options table: global lazy.nvim configuration.
--
-- IMPORTANT: the string MUST match the actual directory name under lua/.
-- lua/plugins/ exists → "plugins" is correct.
require("lazy").setup("plugins", {

  -- ── INSTALL ──────────────────────────────────────────────────────────
  install = {
    -- Colorscheme to use while plugins are being installed on first launch.
    -- If this scheme isn't installed yet, lazy falls back to default.
    colorscheme = { "catppuccin", "habamax" }, 
  },

  -- ── UPDATE CHECKER ───────────────────────────────────────────────────
  checker = {
    enabled = true,       -- check for plugin updates in the background

     -- don't pop a notification every launch saying updates exist.
     -- You'll see it in :Lazy instead. With notify=true it becomes
     -- noise you ignore — defeating the purpose. 
    notify  = false,    
    frequency = 3600,     -- check at most once per hour (in seconds)
  },

  -- ── CHANGE DETECTION ─────────────────────────────────────────────────
  change_detection = {
    -- Watch your plugin spec files for changes and reload automatically.
    enabled = true,
    
    -- same reasoning as checker.notify — suppress the popup,
    -- let lazy handle it silently
    notify  = false, 

  },

  -- ── UI ───────────────────────────────────────────────────────────────
  ui = {
    border = "rounded",
    -- Size of the lazy window as a fraction of the editor
    size = { width = 0.85, height = 0.85 },
    -- Icons used in the lazy UI (requires a Nerd Font)
    icons = {
      cmd        = " ",
      config     = "",
      event      = "",
      ft         = " ",
      init       = " ",
      import     = " ",
      keys       = " ",
      lazy       = "󰒲 ",
      loaded     = "●",
      not_loaded = "○",
      plugin     = " ",
      runtime    = " ",
      require    = "󰢱 ",
      source     = " ",
      start      = "",
      task       = "✔ ",
      list = { "●", "➜", "★", "‒" },
    },
  },

  -- ── PERFORMANCE ──────────────────────────────────────────────────────
  performance = {
    cache = {
      enabled = true,   -- cache the Lua module loader — measurably faster startup
    },
    reset_packpath = true,   -- reset packpath to only include lazy-managed paths,
                             -- preventing accidental loading of system-installed plugins
    rtp = {
      reset = false,         -- when set to true: reset rtp to a clean minimal set
                             -- prevents system/distro plugins from leaking in —
                             -- important on NixOS where system Neovim plugins could
                             -- otherwise interfere with your managed setup
                             -- Set to false tho after some issues with loading lazy
                             --
                             -- NOTE: reset = false is intentional and important on NixOS.
                             -- reset = true would wipe the Nix-injected rtp entries (lazy-nvim,
                             -- neovim runtime files from the Nix store) before setup completes,
                             -- causing require("lazy") itself to fail on the internal reload.
      disabled_plugins = {
        -- Built-in plugins you never use. Disabling them shaves startup time.
        -- These are safe to disable in a lazy.nvim-managed config.
        "gzip",
        "matchit",        -- extended % matching (treesitter does this better)
        "matchparen",     -- highlight matching parens (plugins do this better)
        "netrwPlugin",    -- built-in file browser (w're using oil.nvim + neo-tree)
        "tarPlugin",
        "tohtml",         -- :TOhtml command (never used)
        "tutor",          -- :Tutor command
        "zipPlugin",
      },
    },
  },

  -- ── DIFF TOOL ────────────────────────────────────────────────────────
  -- How lazy displays diffs when you press 'd' on a plugin in :Lazy
  diff = {
    -- "browser" opens GitHub. "terminal_git" uses git in a terminal split.
    -- "diffview" uses diffview.nvim if you have it installed.
    cmd = "terminal_git",
  },

  -- ── HEADLESS / CI BEHAVIOUR ──────────────────────────────────────────
  -- When running Neovim headlessly (e.g. in a script or CI pipeline),
  -- you generally want to skip the interactive UI.
  headless = {
    -- Don't show the lazy progress bar during headless installs
    process = true,
    log     = true,
    task    = true,
  },
})
