-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- lua/plugins/alpha.lua
-- ALPHA — Startup Dashboard
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Shows a dashboard when Neovim opens with no file argument.
-- Contains: ASCII header art, shortcut buttons, recent files, session info.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

return {
  "goolord/alpha-nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },

  -- Load only when Neovim opens with no file (the typical startup screen case).
  event = "VimEnter",

  config = function()
    local alpha     = require("alpha")
    -- IMPORTANT: use "dashboard", NOT "startify".
    -- The startify theme ignores section.header.val — your custom ASCII art
    -- was being silently discarded. The dashboard theme has explicit sections
    -- for header, buttons, and footer that you can customize.
    --
    --local dashboard = require("alpha.themes.startify")
    local dashboard = require("alpha.themes.dashboard")

    -- ── HEADER ─────────────────────────────────────────────────────────
    -- Neovim logo. Displayed at the top of the dashboard.
    dashboard.section.header.val = {

      [[                                                                       ]],
      [[                                                                       ]],
      [[                                                                       ]],
      [[                                                                       ]],
      [[                                                                     ]],
      [[       ████ ██████           █████      ██                     ]],
      [[      ███████████             █████                             ]],
      [[      █████████ ███████████████████ ███   ███████████   ]],
      [[     █████████  ███    █████████████ █████ ██████████████   ]],
      [[    █████████ ██████████ █████████ █████ █████ ████ █████   ]],
      [[  ███████████ ███    ███ █████████ █████ █████ ████ █████  ]],
      [[ ██████  █████████████████████ ████ █████ █████ ████ ██████ ]],
      [[                                                                       ]],
      [[                                                                       ]],
      [[                                                                       ]],
    }

    -- ── BUTTONS ────────────────────────────────────────────────────────
    -- Shortcut buttons shown below the header. Each button:
    --   button(shortcut, label, command)
    -- The shortcut is a single key — pressing it while the dashboard is
    -- focused runs the command. Icons require a Nerd Font.
    dashboard.section.buttons.val = {
      dashboard.button("f", "󰈞  Find file",        "<cmd>Telescope find_files<CR>"),
      dashboard.button("r", "  Recent files",      "<cmd>Telescope oldfiles<CR>"),
      dashboard.button("g", "  Live grep",          "<cmd>Telescope live_grep<CR>"),
      dashboard.button("n", "  New file",           "<cmd>ene <BAR> startinsert<CR>"),
      dashboard.button("l", "󰒲  Open lazy.nvim",    "<cmd>Lazy<CR>"),
      dashboard.button("m", "  Open Mason",         "<cmd>Mason<CR>"),
      dashboard.button("q", "󰅚  Quit",              "<cmd>qa<CR>"),
    }

    -- ── FOOTER ─────────────────────────────────────────────────────────
    -- Shown below the buttons. Displays loaded plugin count via lazy.nvim.
    -- The pcall guard handles the edge case where lazy.nvim isn't loaded yet.
    local function footer()
      local stats = nil
      local ok, lazy = pcall(require, "lazy")
      if ok then
        stats = lazy.stats()
      end
      if stats then
        return string.format(
          "⚡ Neovim loaded %d/%d plugins in %.2fms",
          stats.loaded, stats.count, stats.startuptime
        )
      end
      return "CypherIDE"
    end

    dashboard.section.footer.val = footer()

    -- ── LAYOUT ─────────────────────────────────────────────────────────
    -- Padding between sections (header, buttons, footer).
    -- Adjust the numbers to control vertical spacing.
    dashboard.config.layout = {
      { type = "padding", val = 2 },
      dashboard.section.header,
      { type = "padding", val = 2 },
      dashboard.section.buttons,
      { type = "padding", val = 1 },
      dashboard.section.footer,
    }

    alpha.setup(dashboard.config)

    -- ── AUTOCMD: refresh footer after lazy finishes loading ─────────────
    -- The footer's plugin count is 0 if read before lazy finishes.
    -- This autocmd fires once after all plugins load and updates the count.
    vim.api.nvim_create_autocmd("User", {
      pattern  = "LazyDone",
      once     = true,
      callback = function()
        if vim.bo.filetype == "alpha" then
          dashboard.section.footer.val = footer()
          -- pcall: alpha.redraw may not exist in older versions
          pcall(require("alpha").redraw)
        end
      end,
    })
  end,
}
