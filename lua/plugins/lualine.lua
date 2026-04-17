-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- lua/plugins/lualine.lua
-- LUALINE — Status Line
--
-- The / Powerline separators require a Nerd Font variant that includes 
-- Powerline glyphs. If your terminal font doesn't have them, lualine logs a 
-- notice. 
--
-- Replaced with │ (a standard Unicode box character) for components, and / 
-- (slightly more widely available Nerd Font glyphs) for sections. 
--
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },

  config = function()
    require("lualine").setup({
      options = {
        theme = "dracula", -- options "auto", not sure if "catppuccin" is supported

        -- component_separators: small separators between components within a section.
        -- section_separators: larger separators between sections (a, b, c).
        -- Powerline-style angled separators look great with catppuccin.
        component_separators = { left = "", right = "" },
        section_separators   = { left = "", right = "" },

        -- Don't show lualine in these special buffer types.
        disabled_filetypes = {
          statusline = { "alpha", "lazy", "mason" },
        },

        -- Draw lualine across the full screen width (ignoring split boundaries).
        globalstatus = true,
      },

      -- ── SECTIONS ─────────────────────────────────────────────────────
      -- Lualine is split into 6 sections: a b c (left) | x y z (right).
      sections = {
        lualine_a = { "mode" },
        lualine_b = {
          "branch",
          -- diff: shows +/-/~ counts for git hunks in the current file.
          -- gitsigns provides this data if installed.
          {
            "diff",
            symbols = { added = " ", modified = " ", removed = " " },
          },
        },
        lualine_c = {
          -- filename: show relative path. truncate_at_root = trim to project root.
          {
            "filename",
            path = 1,           -- 0 = just filename, 1 = relative, 2 = absolute
            symbols = {
              modified  = " ●",  -- file has unsaved changes
              readonly  = " 🔒",
              unnamed   = "[No Name]",
            },
          },
        },
        lualine_x = {
          -- LSP diagnostics count in the status line.
          {
            "diagnostics",
            sources = { "nvim_lsp" },
            symbols = {
              error = " ",
              warn  = " ",
              info  = " ",
              hint  = "󰠠 ",
            },
          },
          "encoding",
          "fileformat",
          "filetype",
        },
        lualine_y = { "progress" },   -- percentage through file
        lualine_z = { "location" },   -- line:column
      },

      -- Inactive window status lines (splits that don't have focus).
      inactive_sections = {
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "location" },
      },
    })
  end,
}
