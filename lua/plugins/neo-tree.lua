-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- lua/plugins/neo-tree.lua
-- NEO-TREE — Project Sidebar File Explorer
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Role in the dual-explorer setup:
--   neo-tree → persistent sidebar for project structure overview
--   oil.nvim  → floating editor-style buffer for renaming/moving files
--
-- Toggle neo-tree with <C-b> (mirrors VSCode's Ctrl+B sidebar toggle).
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    -- nvim-web-devicons: file type icons in the sidebar.
    -- Requires a Nerd Font in your terminal emulator.
    "nvim-tree/nvim-web-devicons",
  },

  -- Do NOT set `lazy = false` here. neo-tree registers its own lazy-load
  -- triggers internally (it watches for directory arguments on startup, etc.).
  -- Let lazy.nvim manage load timing — the keymap below will also trigger
  -- an on-demand load the first time you press <C-b>.

  config = function()
    local K = require("cide-keymaps")

    -- neo-tree setup — minimal config, sensible defaults.
    -- Expand as you learn which behaviors you want to change.
    require("neo-tree").setup({
      close_if_last_window = true,    -- auto-close if neo-tree is the last split
      popup_border_style   = "rounded",

      -- Default component configs
      default_component_configs = {
        indent = {
          indent_size          = 2,
          padding              = 1,
          with_markers         = true,
          indent_marker        = "│",
          last_indent_marker   = "└",
          highlight            = "NeoTreeIndentMarker",
          with_expanders       = nil,
          expander_collapsed   = "",
          expander_expanded    = "",
          expander_highlight   = "NeoTreeExpander",
        },
        icon = {
          folder_closed  = "",
          folder_open    = "",
          folder_empty   = "󰜌",
        },
        git_status = {
          symbols = {
            -- Symbols for changed, staged, untracked, etc.
            added     = "✚",
            modified  = "",
            deleted   = "✖",
            renamed   = "󰁕",
            untracked = "",
            ignored   = "",
            unstaged  = "󰄱",
            staged    = "",
            conflict  = "",
          },
        },
      },

      window = {
        position = "right",   -- sidebar on the right (matches your original config)
        width     = 35,
      },

      filesystem = {
        -- Follow the file currently open in the active buffer.
        follow_current_file = {
          enabled = true,
        },
        -- Show hidden files (dotfiles) by default.
        -- Toggle with 'H' inside the neo-tree window.
        filtered_items = {
          visible        = false,
          hide_dotfiles  = false,
          hide_gitignored = true,
        },
        -- Watch the filesystem for external changes and update automatically.
        use_libuv_file_watcher = true,
      },
    })

    -- ── TOGGLE KEYMAP ───────────────────────────────────────────────────
    -- <C-b> toggles the neo-tree filesystem sidebar.
    --
    -- NOTE: <C-b> in insert mode scrolls up (Vim's built-in). This keymap
    -- only applies in normal mode, so insert-mode behavior is unaffected.
    -- The key was chosen to mirror VSCode's Ctrl+B sidebar toggle.
    -- Change K.neo_tree.toggle in cide-keymaps.lua to update it everywhere.
    vim.keymap.set("n", K.neo_tree.toggle, function()
      -- "reveal" = focus the currently open file in the tree when toggling open.
      -- "toggle" = if open, close; if closed, open.
      vim.cmd("Neotree filesystem reveal toggle right")
    end, { desc = "Explorer: toggle neo-tree sidebar", noremap = true, silent = true })

  end,
}
