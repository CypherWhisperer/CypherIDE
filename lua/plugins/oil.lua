-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- lua/plugins/oil.lua
-- OIL.NVIM — Edit-the-Filesystem File Manager
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Role in the dual-explorer setup:
--   oil.nvim  → floating "edit filesystem like a buffer" tool
--               rename files by typing, move by cutting lines, bulk ops
--   neo-tree  → persistent sidebar for project structure overview
--
-- "-" opens oil in a floating window over the current buffer, showing the
-- directory of the file you're editing. Navigate with h/l (or hjkl), press
-- Enter to open, press "-" again to go up to the parent directory.
-- Save your changes with :w — oil executes the filesystem operations.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

return {
  "stevearc/oil.nvim",
  -- Load lazily — the keymap below triggers the first load on demand.
  -- No need to load oil at startup if you haven't pressed "-" yet.
  lazy = true,

  -- oil.nvim recommends nvim-web-devicons for file type icons.
  dependencies = { "nvim-tree/nvim-web-devicons" },

  config = function()
    local oil = require("oil")
    local K   = require("cide-keymaps")

    oil.setup({
      -- Float mode is the default when using toggle_float.
      -- These settings control the floating window appearance.
      float = {
        padding       = 2,
        max_width     = 90,
        max_height    = 0,   -- 0 = no max height, uses available screen space
        border        = "rounded",
        win_options   = {
          winblend = 10,     -- slight transparency
        },
      },

      -- Show file icons (requires nvim-web-devicons + Nerd Font).
      columns = {
        "icon",
        -- Uncomment to show permissions, size, and modification time:
        -- "permissions",
        -- "size",
        -- "mtime",
      },

      -- Key bindings INSIDE the oil buffer.
      -- These are oil's own navigation keys — separate from the global toggle.
      keymaps = {
        ["g?"]    = "actions.show_help",
        ["<CR>"]  = "actions.select",
        ["<C-s>"] = "actions.select_vsplit",   -- open in vertical split
        ["<C-h>"] = "actions.select_split",    -- open in horizontal split
        ["<C-t>"] = "actions.select_tab",      -- open in new tab
        ["<C-p>"] = "actions.preview",         -- preview without opening
        ["<C-c>"] = "actions.close",
        ["<C-r>"] = "actions.refresh",
        ["-"]     = "actions.parent",          -- go up to parent directory
        ["_"]     = "actions.open_cwd",        -- open cwd in oil
        ["`"]     = "actions.cd",
        ["~"]     = "actions.tcd",
        ["gs"]    = "actions.change_sort",
        ["gx"]    = "actions.open_external",
        ["g."]    = "actions.toggle_hidden",   -- toggle dotfiles
        ["g\\"]   = "actions.toggle_trash",
      },

      -- Don't show confirmation for simple single-file operations.
      -- For multi-file or destructive operations (delete), prompt always shows.
      skip_confirm_for_simple_edits = true,

      -- Highlight the filename as you hover over it in oil.
      highlight_filename = {
        enabled  = true,
        timeout  = 0,
        interval = 0,
      },
    })

    -- ── GLOBAL TOGGLE KEYMAP ────────────────────────────────────────────
    -- "-" opens oil as a floating window over the current buffer.
    -- The directory shown is the directory of the file currently being edited.
    -- Change K.oil.open_float in cide-keymaps.lua to update it everywhere.
    vim.keymap.set("n", K.oil.open_float, oil.toggle_float, {
      desc    = "Explorer: open oil (float)",
      noremap = true,
      silent  = true,
    })
  end,
}
