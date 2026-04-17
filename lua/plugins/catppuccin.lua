-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- lua/plugins/catppuccin.lua
-- CATPPUCCIN — Color Scheme
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Four flavours available: latte (light), frappe, macchiato, mocha (darkest).
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

return {
  "catppuccin/nvim",
  name     = "catppuccin",
  priority = 1000,   -- load before all other plugins that might set colors

  -- This block below is responsible for applying the plugins
  -- it first `require`s tha package and then calls a setup function
  -- This is conventional in lua plugins;
  -- Plugins export a setup function you have to call. It imports all setup 
  -- functions and all functionalities for the given plugin/ package into the
  -- Neovim Lua runtime for Neovim to execute 
  config = function()
    require("catppuccin").setup({
      flavour = "mocha",   -- options: "latte", "frappe", "macchiato", "mocha"

      -- Integration flags: catppuccin ships with first-class support for
      -- popular plugins. Explicitly enabling them gives you palette-matched
      -- highlights for those plugins (rather than relying on their defaults).
      integrations = {
        cmp             = true,       -- nvim-cmp (if you ever switch back)
        gitsigns        = true,       -- gitsigns.nvim
        nvimtree        = false,      -- we use neo-tree, not nvim-tree
        neotree         = true,       -- neo-tree.nvim
        telescope       = { enabled = true },
        which_key       = true,       -- which-key.nvim
        treesitter      = true,
        lsp_trouble     = false,
        mason           = true,
        mini            = { enabled = false },
        notify          = false,
        -- Semantic token highlights (richer LSP coloring).
        semantic_tokens = true,
        native_lsp = {
          enabled = true,
          underlines = {
            errors      = { "undercurl" },
            hints       = { "undercurl" },
            warnings    = { "undercurl" },
            information = { "underdotted" },
          },
        },
      },
    })

    -- Apply the scheme. "catppuccin-mocha" is the full name;
    -- "catppuccin" alone would use whatever `flavour` was set above.
    vim.cmd.colorscheme("catppuccin-mocha")
  end,
}
