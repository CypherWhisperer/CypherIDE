-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- COMPLETION.LUA
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Autocompletion: shows suggestions as you type, sourced from:
--   • The LSP server attached to the current buffer (types, functions, etc.)
--   • Words already in the current buffer
--   • File system paths
--   • Snippets
--
-- TWO PLUGINS ARE CONFIGURED HERE — only one is active at a time.
-- The inactive one is fully commented out so you can switch by
-- uncommenting one block and commenting the other.
--
-- ┌─────────────────┬──────────────────────────────────────────────────────┐
-- │                 │ blink.cmp (ACTIVE)      │ nvim-cmp (COMMENTED)       │
-- ├─────────────────┼─────────────────────────┼────────────────────────────┤
-- │ Speed           │ 0.5–4ms per keystroke   │ 60ms debounce, 2–50ms      │
-- │                 │                         │ processing hitches         │
-- │ Fuzzy matching  │ Typo-resistant +        │ Exact/prefix only          │
-- │                 │ frecency scoring        │                            │
-- │ Sources         │ All built-in            │ Separate cmp-* plugins     │
-- │                 │ (lsp, buffer, path,     │ required for each source   │
-- │                 │  snippets)              │                            │
-- │ Snippets        │ Native, built-in        │ Needs LuaSnip + cmp_luasnip│
-- │ Plugin count    │ 1 (+ friendly-snippets) │ 4–6 plugins minimum        │
-- │ Maintenance     │ Active, growing fast    │ Stable, maintenance mode   │
-- │ Ecosystem compat│ Growing                 │ Widest today               │
-- └─────────────────┴─────────────────────────┴────────────────────────────┘
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

return {

  -- ══════════════════════════════════════════════════════════════════════════
  -- ACTIVE: BLINK.CMP
  -- ══════════════════════════════════════════════════════════════════════════
  -- blink.cmp is a batteries-included completion plugin. Unlike nvim-cmp which
  -- needs a separate plugin for every source (LSP, buffer, path, snippets),
  -- blink.cmp bundles all common sources. It uses an optional Rust-based fuzzy
  -- matcher (frizbee) for typo-resistant matching with frecency scoring —
  -- items you accept more often float to the top over time.
  {
    "saghen/blink.cmp",

    -- Use a versioned release to download pre-built Rust binaries for the fuzzy
    -- matcher. Using "1.*" means "latest v1.x release" — stable, not nightly.
    -- If you prefer to build from source (requires Rust toolchain):
    --   replace `version` with `build = "cargo build --release"`
    version = "1.*",

    dependencies = {
      -- friendly-snippets: a large curated collection of snippets for dozens of
      -- languages. blink.cmp loads these automatically via its snippets source.
      -- You'll get things like `cl` → console.log(), `fn` → function skeleton, etc.
      "rafamadriz/friendly-snippets",
    },

    opts = {
      -- ── KEYMAP PRESET ──────────────────────────────────────────────────
      -- "default" preset uses Vim-native keys:
      --   <C-n> / <C-p>     → navigate down/up through suggestions
      --   <C-y>             → accept the selected item (the Vim way)
      --   <C-e>             → close the completion menu
      --   <C-b> / <C-f>     → scroll documentation up/down
      --   <C-space>         → manually trigger completion
      keymap = { preset = "default" },

      -- ── APPEARANCE ─────────────────────────────────────────────────────
      appearance = {
        -- "mono" = Nerd Font Mono (icons same width as text — most configs)
        -- "normal" = regular Nerd Font (icons slightly wider)
        nerd_font_variant = "mono",
      },

      -- ── COMPLETION BEHAVIOR ────────────────────────────────────────────
      completion = {
        -- Documentation popup: automatically show docs for the highlighted item.
        -- auto_show_delay_ms: wait this long before showing docs (avoids flicker
        -- when you're rapidly arrowing through items).
        documentation = {
          auto_show          = true,
          auto_show_delay_ms = 200,
        },

        -- Ghost text: shows what would be inserted as faded inline text,
        -- similar to GitHub Copilot's inline suggestions.
        -- Useful as a preview before accepting. Disable if you find it distracting.
        ghost_text = {
          enabled = true,
        },

        -- Menu: draw LSP kind icons using treesitter-aware rendering
        -- (so the icon for "Function" looks different from "Variable").
        menu = {
          draw = {
            treesitter = { "lsp" },
          },
        },

        -- Accept: experimental auto-bracket insertion.
        -- When you accept a function, blink automatically adds () after it.
        accept = {
          auto_brackets = { enabled = true },
        },
      },

      -- ── SOURCES ────────────────────────────────────────────────────────
      -- These are the data sources blink.cmp pulls suggestions from.
      -- All of these are built-in — no extra plugins needed.
      sources = {
        -- Default source list used for most filetypes:
        --   lsp      → completions from the attached language server
        --   buffer   → words already present in the current buffer
        --   path     → filesystem paths (great inside import statements)
        --   snippets → snippets from friendly-snippets
        default = { "lsp", "buffer", "path", "snippets" },

        -- You can override sources per filetype. Example: in SQL files,
        -- you might not want snippet suggestions cluttering the list:
        -- per_filetype = {
        --   sql = { "lsp", "buffer" },
        -- },
      },

      -- ── FUZZY MATCHING ─────────────────────────────────────────────────
      fuzzy = {
        -- "prefer_rust_with_warning" = use the Rust matcher if the pre-built
        -- binary downloaded correctly; warn (but don't crash) if it didn't.
        -- This gives you the fast Rust matcher on supported platforms while
        -- falling back to the pure-Lua matcher on unsupported ones (e.g. some
        -- BSD/musl environments — relevant to your FreeBSD CypherOS lens).
        implementation = "prefer_rust_with_warning",
      },
    },

    -- blink.cmp needs to tell nvim-lspconfig about its enhanced capabilities
    -- (what completion features the editor supports) so LSP servers send richer
    -- data. This opts_extend + the config function below wire that up.
    opts_extend = { "sources.default" },
  },

  -- ══════════════════════════════════════════════════════════════════════════
  -- COMMENTED OUT: NVIM-CMP (uncomment this block and comment blink.cmp above
  -- if you need to switch back — e.g. for plugin compatibility reasons)
  -- ══════════════════════════════════════════════════════════════════════════

  -- {
  --   "hrsh7th/nvim-cmp",
  --   event = "InsertEnter",  -- load only when entering insert mode
  --   dependencies = {
  --     -- Source plugins — each adds a new type of completion data:
  --     "hrsh7th/cmp-nvim-lsp",     -- LSP completions
  --     "hrsh7th/cmp-buffer",        -- words in current buffer
  --     "hrsh7th/cmp-path",          -- filesystem paths
  --     "hrsh7th/cmp-cmdline",       -- completions in Neovim's : command line
  --     -- Snippet engine (nvim-cmp doesn't ship its own):
  --     "L3MON4D3/LuaSnip",
  --     "saadparwaiz1/cmp_luasnip",  -- bridge between LuaSnip and nvim-cmp
  --     "rafamadriz/friendly-snippets", -- snippet collection
  --   },
  --   config = function()
  --     local cmp     = require("cmp")
  --     local luasnip = require("luasnip")
  --
  --     -- Load the friendly-snippets collection into LuaSnip
  --     require("luasnip.loaders.from_vscode").lazy_load()
  --
  --     cmp.setup({
  --       -- Tell cmp to use LuaSnip for snippet expansion
  --       snippet = {
  --         expand = function(args)
  --           luasnip.lsp_expand(args.body)
  --         end,
  --       },
  --
  --       -- Window appearance: rounded borders on completion + docs popups
  --       window = {
  --         completion    = cmp.config.window.bordered(),
  --         documentation = cmp.config.window.bordered(),
  --       },
  --
  --       -- Keymaps
  --       mapping = cmp.mapping.preset.insert({
  --         ["<C-p>"]     = cmp.mapping.select_prev_item(),  -- previous item
  --         ["<C-n>"]     = cmp.mapping.select_next_item(),  -- next item
  --         ["<C-b>"]     = cmp.mapping.scroll_docs(-4),     -- scroll docs up
  --         ["<C-f>"]     = cmp.mapping.scroll_docs(4),      -- scroll docs down
  --         ["<C-Space>"] = cmp.mapping.complete(),          -- trigger manually
  --         ["<C-e>"]     = cmp.mapping.abort(),             -- close menu
  --         ["<CR>"]      = cmp.mapping.confirm({ select = true }), -- accept
  --         -- Tab: accept if menu visible, else insert a real tab
  --         ["<Tab>"] = cmp.mapping(function(fallback)
  --           if cmp.visible() then
  --             cmp.select_next_item()
  --           elseif luasnip.expand_or_jumpable() then
  --             luasnip.expand_or_jump()  -- jump to next snippet placeholder
  --           else
  --             fallback()
  --           end
  --         end, { "i", "s" }),
  --         ["<S-Tab>"] = cmp.mapping(function(fallback)
  --           if cmp.visible() then
  --             cmp.select_prev_item()
  --           elseif luasnip.jumpable(-1) then
  --             luasnip.jump(-1)  -- jump to previous snippet placeholder
  --           else
  --             fallback()
  --           end
  --         end, { "i", "s" }),
  --       }),
  --
  --       -- Sources: ordered by priority (first = highest priority in ranking)
  --       sources = cmp.config.sources({
  --         { name = "nvim_lsp" },  -- LSP server completions
  --         { name = "luasnip" },   -- snippets
  --         { name = "buffer" },    -- current buffer words
  --         { name = "path" },      -- file paths
  --       }),
  --     })
  --
  --     -- Completions in search mode (/ and ?)
  --     cmp.setup.cmdline({ "/", "?" }, {
  --       mapping = cmp.mapping.preset.cmdline(),
  --       sources = { { name = "buffer" } },
  --     })
  --
  --     -- Completions in command mode (:)
  --     cmp.setup.cmdline(":", {
  --       mapping = cmp.mapping.preset.cmdline(),
  --       sources = cmp.config.sources({
  --         { name = "path" },
  --         { name = "cmdline" },
  --       }),
  --     })
  --   end,
  -- },

}
