-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- lua/plugins/markdown.lua
-- MARKDOWN TOOLING — Rendering, Preview, and Language Intelligence
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--
-- This module covers three distinct layers of Markdown support:
--
--   LAYER 1 — In-buffer rendering (inline, no external window)
--     Transforms the buffer visually using extmarks / virtual text so
--     Markdown reads as rendered output in normal mode, then disappears
--     in insert mode so you edit raw syntax cleanly.
--
--     Two plugins cover this space — both are configured here, ONE active
--     at a time. Toggle between them by flipping the `enabled` flags
--     in each plugin spec. See the decision comments on each.
--
--     • render-markdown.nvim  (MeanderingProgrammer) — CURRENTLY ACTIVE
--     • markview.nvim         (OXY2DEV)              — AVAILABLE, commented config
--
--   LAYER 2 — External browser preview (full rendering including Mermaid)
--     Opens a live-synced browser tab. Full Mermaid, math, images.
--     Three options provided — all declared, one active at a time.
--
--     • markdown-preview.nvim (iamcco)         — CURRENTLY ACTIVE
--     • markdown-preview.nvim (selimacerbas)   — COMMENTED (no Node dep, Rust Mermaid)
--     • peek.nvim             (toppair)        — COMMENTED (requires Deno)
--
--   LAYER 3 — Language intelligence (marksman LSP)
--     marksman is already installed and enabled via lsp-config.lua.
--     This module adds Markdown-specific buffer-local keybindings that
--     surface marksman's capabilities (heading search, link follow).
--     These are set via a FileType autocmd, NOT LspAttach, to keep
--     this module self-contained and lsp-config.lua untouched.
--
-- KITTY / GHOSTTY NOTE:
--   Both terminals support the Kitty graphics protocol, which enables
--   true inline image rendering inside Neovim via image.nvim.
--   A placeholder for image.nvim is included at the bottom of this file
--   for future integration with Layer 1 (inline diagram images).
--
-- KEYBINDINGS:
--   All keys are declared in cide-keymaps.lua (the SSOT) and referenced
--   here via K.markdown.*. Do not hardcode key strings in this file.
--   See the `markdown` section in cide-keymaps.lua for the full map.
--
-- KEYMAP TABLE (for documentation reference):
--   <leader>mr  → Toggle in-buffer rendering (render-markdown / markview)
--   <leader>mo  → Open browser preview
--   <leader>mx  → Close browser preview
--   <leader>mt  → Toggle browser preview (open if closed, close if open)
--   <leader>mh  → Find heading in file (Telescope + marksman)
--   <leader>mf  → Follow link under cursor (marksman go-to-definition)
--
-- WHICH-KEY:
--   Group label "<leader>m" → "Markdown / Format" is registered in which-key.lua.
--   Individual key descriptions here match the desc strings in cide-keymaps.lua.
--
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ── CIDE-KEYMAPS SSOT REFERENCE ───────────────────────────────────────────
-- The markdown keymap section expected in cide-keymaps.lua:
--
--   markdown = {
--     toggle_render  = "<leader>mr",
--     preview_open   = "<leader>mo",
--     preview_close  = "<leader>mx",
--     preview_toggle = "<leader>mt",
--     find_heading   = "<leader>mh",
--     follow_link    = "<leader>mf",
--   },
--
-- Add this block to the return table in cide-keymaps.lua before activating
-- the bindings in this file.
-- ──────────────────────────────────────────────────────────────────────────

return {

  -- ══════════════════════════════════════════════════════════════════════════
  -- LAYER 1A — render-markdown.nvim (ACTIVE)
  -- In-buffer Markdown rendering via extmarks and virtual text.
  --
  -- WHY THIS ONE IS ACTIVE:
  --   • 4.5k+ stars, ecosystem leader as of 2025
  --   • Default in LazyVim — battle-tested across configs
  --   • Has a dedicated NixVim module (relevant for CypherOS portability)
  --   • Focused scope: Markdown only — does one thing extremely well
  --   • Lighter config surface than markview for the same core feature
  --
  -- HOW IT WORKS:
  --   In normal / command / terminal mode → renders headings, bullets,
  --   checkboxes, code blocks, tables, callouts as styled virtual text.
  --   In insert mode → virtual text is hidden, raw Markdown is visible.
  --   This "flicker-free" toggle is the core UX of the plugin.
  --
  -- MERMAID NOTE:
  --   render-markdown.nvim does NOT render Mermaid diagrams as images inline.
  --   It syntax-highlights the fenced block and labels it, but the diagram
  --   itself requires a browser preview (Layer 2) or image.nvim (future, bottom
  --   of this file). This is a terminal limitation, not a plugin limitation.
  --   With Kitty/Ghostty graphics protocol support, image.nvim closes this gap.
  -- ══════════════════════════════════════════════════════════════════════════
  {
    "MeanderingProgrammer/render-markdown.nvim",

    -- Load only when a Markdown file is opened — no startup cost.
    ft = { "markdown", "mdx" },

    dependencies = {
      -- nvim-treesitter: render-markdown uses TS to parse Markdown structure.
      -- It must be installed but does not need explicit setup here —
      -- your existing treesitter config handles that.
      "nvim-treesitter/nvim-treesitter",
      -- nvim-web-devicons: optional but recommended — provides icons for
      -- callout blocks (NOTE, WARNING, TIP, etc.) and file type indicators.
      "nvim-tree/nvim-web-devicons",
    },

    opts = {
      -- ── ENABLED STATE ───────────────────────────────────────────────
      -- true = render on buffer open. <leader>mr toggles at runtime.
      -- Set to false if you want to start un-rendered and opt in per-buffer.
      enabled = true,

      -- ── RENDER MODE ─────────────────────────────────────────────────
      -- "full"   = render everything (default)
      -- "normal" = render in normal mode only, not in other modes
      render_modes = { "n", "c" },
      -- DECISION: insert mode is intentionally excluded so raw Markdown
      -- is always visible while typing. This is the core UX contract.

      -- ── HEADINGS ────────────────────────────────────────────────────
      heading = {
        -- Render heading levels with descending visual weight.
        -- Icons use Nerd Font heading symbols.
        icons = { "󰉫 ", "󰉬 ", "󰉭 ", "󰉮 ", "󰉯 ", "󰉰 " },
        -- Heading background extends the full width of the window.
        -- "full" = colored background; "minimal" = icon + color only.
        width = "full",
        -- sign = false: don't show heading level in the sign column.
        -- The sign column is owned by diagnostics / gitsigns.
        sign = false,
      },

      -- ── CODE BLOCKS ─────────────────────────────────────────────────
      code = {
        -- "full" = render language label + styled border around the block.
        -- "language" = just the language label, no border.
        -- "normal" = no styling.
        style = "full",
        -- Show the language name as a label in the top-right of the block.
        language_name = true,
        -- sign = false: keep sign column clean.
        sign = false,
        -- Border style for fenced code blocks.
        -- "thin" uses box-drawing chars; "thick" uses heavier chars.
        border = "thin",
      },

      -- ── CHECKBOXES ──────────────────────────────────────────────────
      -- Render [ ] and [x] as visual checkbox icons.
      checkbox = {
        unchecked = { icon = "󰄱 " },
        checked   = { icon = "󰱒 " },
        -- Custom states for extended syntax (e.g. [-] for in-progress):
        -- custom = {
        --   in_progress = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownWarn" },
        -- },
      },

      -- ── BULLETS ─────────────────────────────────────────────────────
      -- Replace raw "-" / "*" / "+" bullet markers with styled icons.
      -- List is cycled per nesting level.
      bullet = {
        icons = { "●", "○", "◆", "◇" },
      },

      -- ── TABLES ──────────────────────────────────────────────────────
      pipe_table = {
        -- "full" = render table borders with box-drawing characters.
        -- "none" = leave tables as raw pipe syntax.
        style = "full",
        -- Alignment: respect the column alignment markers in the table header.
        alignment_indicator = "━",
      },

      -- ── CALLOUTS / ALERTS ───────────────────────────────────────────
      -- GitHub-style callout blocks: > [!NOTE], > [!WARNING], etc.
      -- render-markdown renders these with icons and highlight colors.
      -- Defaults are good — no overrides needed here.

      -- ── LINKS ───────────────────────────────────────────────────────
      link = {
        -- Render inline links with an icon prefix.
        -- "󰌹 " is a chain-link Nerd Font icon.
        image     = "󰥶 ",
        hyperlink = "󰌹 ",
        custom    = {
          -- Render GitHub links with a GitHub icon.
          github = { pattern = "https://github%.com", icon = "󰊤 " },
          -- Render local file links with a file icon.
          local_file = { pattern = "^[^h]", icon = "󰈙 " },
        },
      },
    },

    config = function(_, opts)
      require("render-markdown").setup(opts)

      -- ── KEYMAP: TOGGLE IN-BUFFER RENDER ─────────────────────────────
      -- <leader>mr: toggle render-markdown on/off for the current buffer.
      -- Set as a global normal-mode keymap (not buffer-local) so it can
      -- also activate render-markdown when it's not yet attached to a buffer.
      local K = require("cide-keymaps")
      vim.keymap.set("n", K.markdown.toggle_render, function()
        require("render-markdown").toggle()
      end, {
        noremap = true,
        silent  = true,
        desc    = "Markdown: toggle inline render",
      })
    end,
  },


  -- ══════════════════════════════════════════════════════════════════════════
  -- LAYER 1B — markview.nvim (AVAILABLE — swap with render-markdown if preferred)
  --
  -- WHY IT'S HERE (commented out):
  --   • More configurable than render-markdown — finer control over every element
  --   • Covers more filetypes: Markdown, Typst, LaTeX, HTML inline, AsciiDoc
  --   • Good choice if you write in multiple markup languages beyond Markdown
  --
  -- WHY IT'S NOT ACTIVE BY DEFAULT:
  --   • Larger config surface — more to learn before it feels right
  --   • render-markdown's focused scope is a better fit for the current use case
  --     (Markdown for dev docs, READMEs, notes — not multi-format academic writing)
  --
  -- TO SWITCH: comment out the render-markdown block above, uncomment this one.
  -- Remember to also update <leader>mr's callback from
  --   require("render-markdown").toggle()
  -- to
  --   require("markview").toggle()
  -- ══════════════════════════════════════════════════════════════════════════
  --
  -- {
  --   "OXY2DEV/markview.nvim",
  --   ft    = { "markdown", "mdx", "typst" },
  --   dependencies = {
  --     "nvim-treesitter/nvim-treesitter",
  --     "nvim-tree/nvim-web-devicons",
  --   },
  --   opts = {
  --     -- markview's config is deeply nested per element type.
  --     -- See: https://github.com/OXY2DEV/markview.nvim/wiki
  --     --
  --     -- Minimal starting config — enable and let defaults render first,
  --     -- then override per-element as you identify friction points.
  --     modes      = { "n", "no", "c" },
  --     hybrid_modes = { "i" },    -- insert mode: show raw syntax near cursor only
  --   },
  --   config = function(_, opts)
  --     require("markview").setup(opts)
  --     local K = require("cide-keymaps")
  --     vim.keymap.set("n", K.markdown.toggle_render, function()
  --       require("markview").toggle()
  --     end, { noremap = true, silent = true, desc = "Markdown: toggle inline render" })
  --   end,
  -- },


  -- ══════════════════════════════════════════════════════════════════════════
  -- LAYER 2A — markdown-preview.nvim by iamcco (ACTIVE)
  -- Opens a live browser preview with full rendering including Mermaid,
  -- KaTeX math, PlantUML, Chart.js, task lists, and local images.
  --
  -- WHY THIS ONE IS ACTIVE:
  --   • Most widely used browser preview plugin — largest community, best docs
  --   • Mermaid support is first-class and well-tested
  --   • Scroll sync between Neovim and browser is reliable
  --
  -- BUILD NOTE:
  --   This plugin requires a Node.js build step (installs its own dependencies
  --   into the plugin directory via npm). The `build` field handles this.
  --   On NixOS, if Node is in your PATH (via nix shell / devShell / HM),
  --   the build runs correctly. If you see "app/node_modules not found",
  --   run :call mkdp#util#install() manually once.
  -- ══════════════════════════════════════════════════════════════════════════
  {
    "iamcco/markdown-preview.nvim",

    -- Only load for Markdown files.
    ft = { "markdown" },

    -- Node.js build step — installs preview server dependencies.
    -- "npm install" runs inside the plugin directory on first install/update.
    build = function()
      vim.fn["mkdp#util#install"]()
    end,

    config = function()
      local K = require("cide-keymaps")

      -- ── PLUGIN SETTINGS ─────────────────────────────────────────────
      -- These are set via vim globals (the plugin's configuration API).

      -- Auto-close the preview tab when you switch away from the Markdown buffer.
      vim.g.mkdp_auto_close = 1

      -- Don't auto-open preview on buffer enter — open explicitly with <leader>mo.
      vim.g.mkdp_auto_start = 0

      -- Open preview in a new browser tab (not a new window).
      vim.g.mkdp_open_to_the_world = 0

      -- Port for the local preview server. 0 = auto-assign.
      -- Set a fixed port (e.g. 8080) if you want a stable URL.
      vim.g.mkdp_port = ""

      -- Browser command. Empty string = use system default browser.
      -- Example override: vim.g.mkdp_browser = "firefox"
      vim.g.mkdp_browser = ""

      -- Page title format in the browser tab.
      -- "${name}" is replaced with the buffer filename.
      vim.g.mkdp_page_title = "「${name}」"

      -- Theme: "dark" | "light" — sets the preview page background.
      -- "dark" matches the Catppuccin Mocha setup.
      vim.g.mkdp_theme = "dark"

      -- ── KEYMAPS ─────────────────────────────────────────────────────
      vim.keymap.set("n", K.markdown.preview_open, "<cmd>MarkdownPreview<CR>", {
        noremap = true,
        silent = true,
        desc = "Markdown: open preview",
      })
      vim.keymap.set("n", K.markdown.preview_close, "<cmd>MarkdownPreviewStop<CR>", {
        noremap = true,
        silent = true,
        desc = "Markdown: close preview",
      })
      vim.keymap.set("n", K.markdown.preview_toggle, "<cmd>MarkdownPreviewToggle<CR>", {
        noremap = true,
        silent = true,
        desc = "Markdown: toggle preview",
      })
    end,
  },


  -- ══════════════════════════════════════════════════════════════════════════
  -- LAYER 2B — markdown-preview.nvim by selimacerbas (AVAILABLE)
  --
  -- WHY IT'S INTERESTING:
  --   • Zero external dependencies — no Node.js, no npm, no Deno
  --   • SSE-based live updates (no polling — more responsive than iamcco)
  --   • Optional Rust-powered Mermaid renderer (mermaid-rs-renderer):
  --     ~400x faster diagram rendering than JS-based alternatives
  --   • Philosophically aligned with CypherOS: minimal external deps
  --
  -- WHY IT'S NOT ACTIVE:
  --   • Newer / less battle-tested than iamcco's plugin
  --   • mermaid-rs-renderer is a separate binary to manage
  --   • iamcco's plugin is sufficient for current needs
  --
  -- TO SWITCH: comment out the iamcco block above, uncomment this one.
  -- ══════════════════════════════════════════════════════════════════════════
  --
  -- {
  --   "selimacerbas/markdown-preview.nvim",
  --   ft    = { "markdown" },
  --   -- No build step — pure Lua + browser. No Node/npm required.
  --   config = function()
  --     local K = require("cide-keymaps")
  --     -- Plugin-specific settings (check the plugin's README for current API):
  --     -- vim.g.mdpreview_port    = 8080
  --     -- vim.g.mdpreview_browser = ""
  --     vim.keymap.set("n", K.markdown.preview_open,   "<cmd>MarkdownPreviewOpen<CR>",
  --       { noremap = true, silent = true, desc = "Markdown: open preview" })
  --     vim.keymap.set("n", K.markdown.preview_close,  "<cmd>MarkdownPreviewClose<CR>",
  --       { noremap = true, silent = true, desc = "Markdown: close preview" })
  --     vim.keymap.set("n", K.markdown.preview_toggle, "<cmd>MarkdownPreviewToggle<CR>",
  --       { noremap = true, silent = true, desc = "Markdown: toggle preview" })
  --   end,
  -- },


  -- ══════════════════════════════════════════════════════════════════════════
  -- LAYER 2C — peek.nvim by toppair (AVAILABLE)
  --
  -- WHY IT'S INTERESTING:
  --   • Clean, modern codebase — actively maintained
  --   • Mermaid support, math (via KaTeX), scroll sync
  --   • Lighter than iamcco for setups that already have Deno
  --
  -- WHY IT'S NOT ACTIVE:
  --   • Requires Deno — an additional runtime to manage in NixOS
  --     (pkgs.deno would need to be in home.packages / systemPackages)
  --   • iamcco covers the same surface with Node.js already in the stack
  --
  -- TO ACTIVATE:
  --   1. Add pkgs.deno to your HM packages in NixOS config
  --   2. Comment out iamcco block, uncomment this block
  -- ══════════════════════════════════════════════════════════════════════════
  --
  -- {
  --   "toppair/peek.nvim",
  --   ft    = { "markdown" },
  --   build = "deno task --quiet build:fast",
  --   opts  = {
  --     auto_load = false,     -- don't auto-open on buffer enter
  --     close_on_bdelete = true,
  --     syntax = true,
  --     theme  = "dark",       -- "dark" | "light"
  --     update_on_change = true,
  --     app = "browser",       -- "webview" | "browser" | custom command
  --     -- throttle_at = 200000,  -- bytes — pause updates for large files
  --   },
  --   config = function(_, opts)
  --     require("peek").setup(opts)
  --     local K = require("cide-keymaps")
  --     vim.keymap.set("n", K.markdown.preview_open, function()
  --       require("peek").open()
  --     end, { noremap = true, silent = true, desc = "Markdown: open preview" })
  --     vim.keymap.set("n", K.markdown.preview_close, function()
  --       require("peek").close()
  --     end, { noremap = true, silent = true, desc = "Markdown: close preview" })
  --     vim.keymap.set("n", K.markdown.preview_toggle, function()
  --       local peek = require("peek")
  --       if peek.is_open() then peek.close() else peek.open() end
  --     end, { noremap = true, silent = true, desc = "Markdown: toggle preview" })
  --   end,
  -- },


  -- ══════════════════════════════════════════════════════════════════════════
  -- LAYER 3 — marksman LSP keybindings (Markdown-specific)
  --
  -- marksman is already installed and enabled via lsp-config.lua.
  -- This plugin spec is NOT a plugin install — it's a thin Lazy spec
  -- with no `plugin` repo that uses `init` to register a FileType autocmd.
  --
  -- WHY FileType INSTEAD OF LspAttach:
  --   The LSP keybindings in lsp-config.lua use LspAttach with buffer-local
  --   maps for all servers universally. Markdown-specific bindings live HERE
  --   to keep lsp-config.lua clean and this module self-contained.
  --   FileType "markdown" fires when a .md buffer opens, which is always
  --   before or coincident with LspAttach for marksman. We use a lazy check
  --   inside the callback to access Telescope only when needed (not a hard dep).
  --
  -- WHAT MARKSMAN PROVIDES:
  --   • Go-to-definition for [[wiki links]] and [markdown](links)
  --   • Document symbols = all headings in the file (Telescope-surfaced)
  --   • Workspace symbols = headings across the whole vault/directory
  --   • Diagnostics for broken links (already shown via lsp-config diagnostics)
  --   • Rename: renames a heading and updates all links pointing to it
  -- ══════════════════════════════════════════════════════════════════════════
  {
    -- This is a virtual spec — no repo to install.
    -- Lazy loads it as a "config-only" entry via the `init` hook.
    -- dir is set to the Neovim config directory so Lazy treats it as local.
    --
    -- ALTERNATIVE: if this pattern feels unclean, move the autocmd block
    -- into your main init.lua or a dedicated lua/markdown-bindings.lua file
    -- that is require()'d from init.lua directly. Both are valid.
    "nvim-lua/plenary.nvim", -- already a dependency in your stack
    name = "markdown-lsp-keymaps",
    lazy = false,            -- register the autocmd on startup, not on ft load

    config = function()
      local K = require("cide-keymaps")

      -- ── MARKDOWN FILETYPE AUTOCMD ──────────────────────────────────
      -- Fires when any Markdown buffer is opened.
      -- Keymaps are buffer-local: they exist only in .md buffers.
      vim.api.nvim_create_autocmd("FileType", {
        pattern  = "markdown",
        group    = vim.api.nvim_create_augroup("MarkdownLspKeymaps", { clear = true }),
        desc     = "Set Markdown-specific buffer-local keymaps (marksman LSP)",
        callback = function(ev)
          -- Shared options for all Markdown keymaps in this buffer.
          local function opts(description)
            return {
              buffer  = ev.buf,
              noremap = true,
              silent  = true,
              desc    = description,
            }
          end

          -- ── HEADING FINDER ──────────────────────────────────────
          -- <leader>mh: open Telescope document symbols picker.
          -- marksman populates this with all headings in the file.
          -- This is effectively an in-file heading TOC navigator.
          --
          -- Falls back to vim.lsp.buf.document_symbol() (the raw LSP
          -- call) if Telescope is not available — graceful degradation.
          vim.keymap.set("n", K.markdown.find_heading, function()
            local ok, telescope = pcall(require, "telescope.builtin")
            if ok then
              -- Telescope lsp_document_symbols scoped to marksman's
              -- "String" symbol kind (how marksman reports headings).
              telescope.lsp_document_symbols({
                symbols = { "String" }, -- marksman uses "String" for headings
                prompt_title = "Headings",
              })
            else
              -- Fallback: built-in LSP document symbols (quickfix list).
              vim.lsp.buf.document_symbol()
            end
          end, opts("Markdown: find heading"))

          -- ── FOLLOW LINK ─────────────────────────────────────────
          -- <leader>mf: jump to the target of the link under cursor.
          -- Works for:
          --   [[wiki links]]          → jumps to the referenced file/heading
          --   [text](./relative.md)   → jumps to the file
          --   [text](#heading)        → jumps to the heading in the same file
          vim.keymap.set("n", K.markdown.follow_link, function()
            vim.lsp.buf.definition()
          end, opts("Markdown: follow link"))
        end, -- end FileType callback
      })
    end,
  },


  -- ══════════════════════════════════════════════════════════════════════════
  -- FUTURE: image.nvim — Inline image rendering (Kitty / Ghostty protocol)
  --
  -- Your terminal setup (Kitty + Ghostty) fully supports the Kitty graphics
  -- protocol, which enables true pixel-level image rendering inside Neovim
  -- buffers. image.nvim bridges this capability to Neovim.
  --
  -- With image.nvim active alongside render-markdown.nvim:
  --   • Images referenced in Markdown (![]()) render inline in the buffer
  --   • Mermaid diagrams can be rendered inline by piping mmdc output
  --     (mermaid-cli: pkgs.mermaid-cli) to image.nvim as a temp PNG
  --     This would close the "Mermaid inline in Neovim" gap without a browser.
  --
  -- WHY IT'S NOT INCLUDED NOW:
  --   • image.nvim requires luarocks (magick binding) which has a non-trivial
  --     NixOS setup (imagemagick + luarocks + lua bindings in the right PATH).
  --   • The browser preview (Layer 2) covers Mermaid rendering adequately
  --     for the current workflow.
  --   • Worth revisiting when CypherOS image.nvim + luarocks integration
  --     is worked out at the NixOS module level.
  --
  -- PLACEHOLDER (uncomment when ready):
  --
  -- {
  --   "3rd/image.nvim",
  --   ft = { "markdown" },
  --   dependencies = { "leafo/magick" },    -- Lua ImageMagick binding
  --   opts = {
  --     backend = "kitty",                  -- "kitty" | "ueberzug" | "sixel"
  --     integrations = {
  --       markdown = {
  --         enabled            = true,
  --         clear_in_insert_mode = true,    -- hide images while editing
  --         download_remote_images = true,
  --         only_render_image_at_cursor = false,
  --       },
  --     },
  --     max_width  = 80,   -- columns
  --     max_height = 30,   -- rows
  --   },
  -- },

}
