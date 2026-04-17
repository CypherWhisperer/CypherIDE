-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- lua/plugins/telescope.lua
-- TELESCOPE — Fuzzy Finder
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Telescope is a fuzzy-finder framework. Core pickers:
--   find_files   → fuzzy search files by name in the project
--   live_grep    → search file CONTENTS in real time (requires ripgrep)
--   buffers      → switch between open buffers
--   help_tags    → search Neovim's :help system interactively
--   diagnostics  → browse all LSP diagnostics across the project
--
-- telescope-fzf-native: replaces the default Lua sorter with a compiled C
-- sorter — significantly faster on large projects. Requires 'make' at build time.
--
-- telescope-ui-select: replaces Neovim's built-in vim.ui.select() popup
-- (used by LSP code actions, mason, etc.) with a Telescope picker.
-- All keybindings read from cide-keymaps.lua (the SSOT).
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

return {

  -- ──────────────────────────────────────────────────────────────────────────
  -- TELESCOPE CORE
  -- ──────────────────────────────────────────────────────────────────────────
  {
    "nvim-telescope/telescope.nvim",
    -- `version = "*"` uses the latest stable release tag rather than
    -- the HEAD commit, which can occasionally have breaking changes.
    version = "*",

    -- Load telescope when Neovim is fully initialized but not actively doing
    -- anything ("VeryLazy"). This avoids adding to startup time while still
    -- having telescope ready before you need it.
    --event = "VeryLazy",

    dependencies = {
      "nvim-lua/plenary.nvim",
      -- fzf-native: compiled C sorter, much faster than the Lua default.
      -- `build = "make"` compiles the C extension on install/update.
      -- Requires gcc or clang and make to be on PATH.
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      -- ui-select: replaces vim.ui.select() with a Telescope picker.
      -- Correct plugin name: "nvim-telescope/telescope-ui-select.nvim"
      -- (previously missing the org prefix and .nvim suffix).
      "nvim-telescope/telescope-ui-select.nvim",
    },

    config = function()
      local telescope = require("telescope")
      local builtin   = require("telescope.builtin")
      local themes    = require("telescope.themes")
      local K         = require("cide-keymaps")

      -- ── TELESCOPE SETUP ─────────────────────────────────────────────
      -- Single setup() call — previously split across two plugin blocks,
      -- which caused the second call to silently reinitialize and wipe the
      -- first block's configuration.
      telescope.setup({

        defaults = {
          -- Sorting strategy: show results with the shortest path first.
          -- "ascending" is better for find_files; "descending" for live_grep.
          sorting_strategy = "ascending",

          -- Layout: bottom prompt (matches most people's muscle memory from
          -- other fuzzy finders like fzf in the terminal).
          layout_config = {
            prompt_position = "top",
            horizontal = {
              preview_width = 0.55,   -- preview takes 55% of the width
            },
          },

          -- File ignore patterns: don't show these in find_files results.
          file_ignore_patterns = {
            "node_modules/",
            ".git/",
            "dist/",
            "build/",
            ".next/",
            "%.lock",      -- package-lock.json, yarn.lock, Cargo.lock
          },

          -- Use ripgrep for file finding if available — much faster than find.
          -- Falls back to find if rg isn't installed.
          vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
            "--hidden",         -- include hidden files (dotfiles)
            "--glob=!.git/*",   -- but not .git contents
          },

          -- Show a border around the picker window.
          borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
        },

        -- ── EXTENSIONS SETUP ──────────────────────────────────────────
        extensions = {
          -- fzf-native: enable fzf's fuzzy matching algorithm.
          fzf = {
            fuzzy                   = true,
            override_generic_sorter = true,   -- replace the Lua generic sorter
            override_file_sorter    = true,   -- replace the Lua file sorter
            case_mode               = "smart_case",
          },

          -- ui-select: use Telescope's dropdown for vim.ui.select() calls.
          -- This replaces the default popup for: code actions, hover actions,
          -- Mason install prompts, refactor choices, etc.
          ["ui-select"] = {
            -- get_dropdown: a compact single-column picker, good for short lists
            -- like code action choices. Alternatives: get_cursor (at cursor),
            -- get_ivy (bottom strip).
            themes.get_dropdown({
              -- dropdown appears at the top center of the screen
              layout_config = {
                width  = 0.6,
                height = 0.4,
              },
            }),
          },
        },
      })

      -- ── LOAD EXTENSIONS ─────────────────────────────────────────────
      -- Extensions must be loaded AFTER setup() is called.
      -- Load both extensions now — they were installed as dependencies above.
      --
      -- fzf: wrapped in pcall because on NixOS the C extension may not be
      -- built yet (`build = "make"` requires gcc + make in lazy's build env).
      -- If the .so is missing, telescope silently falls back to its Lua sorter.
      -- To fix: ensure gcc + gnumake are in our Neovim NixOS env, then run
      -- :Lazy build telescope-fzf-native.nvim to retrigger the build step.
      --
      -- The load_extension("fzf") call crashes hard when the compiled .so 
      -- doesn't exist. The call is now wrapped in pcall — if it fails, you get
      -- a one-time WARN notification explaining the issue, and telescope falls
      -- back to its Lua sorter. Everything still works. To get the native 
      -- sorter working properly on NixOS, you need gcc and gnumake available 
      -- in the environment where lazy runs its build step — add them to your 
      -- Neovim NixOS package env, then run :Lazy build telescope-fzf-native.nvim.
      --
      --telescope.load_extension("fzf")
      local fzf_ok = pcall(telescope.load_extension, "fzf")
        if not fzf_ok then
          vim.notify(
            "telescope-fzf-native: .so not built — using Lua sorter. Run :Lazy build telescope-fzf-native.nvim after adding gcc to your Nix env.",
            vim.log.levels.WARN
          )
        end

      telescope.load_extension("ui-select")

      -- ── KEYMAPS ─────────────────────────────────────────────────────
      -- All key strings from the SSOT table.
      local function map(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, {
          noremap = true,
          silent  = true,
          desc    = desc,
        })
      end

      -- find_files: fuzzy search files by name.
      -- <C-p> is the universal "find file" shortcut — same as VSCode Ctrl+P.
      map(K.telescope.find_files, builtin.find_files,  "Telescope: find files")

      -- live_grep: search file contents in real time.
      -- Requires ripgrep (rg) to be installed.
      map(K.telescope.live_grep,  builtin.live_grep,   "Telescope: live grep")

      -- buffers: fuzzy-switch between open buffers.
      map(K.telescope.buffers,    builtin.buffers,     "Telescope: open buffers")

      -- help_tags: search Neovim's :help system interactively.
      -- Incredibly useful for exploring vim/plugin documentation.
      map(K.telescope.help_tags,  builtin.help_tags,   "Telescope: search help")

      -- diagnostics: all LSP diagnostics across the project in one picker.
      map(K.telescope.diagnostics, builtin.diagnostics, "Telescope: project diagnostics")

      -- resume: re-open the last telescope picker with its previous results.
      -- Useful when you close a picker and want to continue where you left off.
      map(K.telescope.resume,     builtin.resume,      "Telescope: resume last picker")

      -- oldfiles: recently opened files (Neovim's :oldfiles, telescope-ified).
      map(K.telescope.oldfiles,   builtin.oldfiles,    "Telescope: recent files")
    end,
  },

}
