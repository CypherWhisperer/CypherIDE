-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- lua/plugins/lsp-config.lua
-- LSP STACK — Language Server Protocol Configuration
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Full LSP stack, four layers:
--   1. mason.nvim           — installs LSP servers, formatters, linters as binaries
--   2. mason-lspconfig      — bridges Mason → nvim-lspconfig; auto-enables servers
--   3. nvim-lspconfig       — default configs (cmd, filetypes, root detection)
--   4. mason-tool-installer — single ensure_installed list for all tools
--
-- Flow:
--   Mason installs the binary
--   → mason-lspconfig calls vim.lsp.enable()
--   → nvim-lspconfig provides launch config + per-server settings
--   → Neovim's built-in LSP client connects to the server process
--   → blink.cmp's enhanced capabilities are passed to every server
--
-- All keybindings are read from cide-keymaps.lua (the SSOT).
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

return {

  -- ──────────────────────────────────────────────────────────────────────────
  -- 1. MASON
  -- Package manager for LSP servers, DAP adapters, linters, and formatters.
  -- Opens with :Mason — browse, install, and update tools interactively.
  -- ──────────────────────────────────────────────────────────────────────────
  {
    "mason-org/mason.nvim",
    -- `opts` is a lazy.nvim shorthand: it calls require("mason").setup(opts)
    -- automatically. You don't need a separate `config` function for simple setups.
    opts = {
      ui = {
        -- Rounded borders on the Mason popup window
        border = "rounded",
        icons = {
          package_installed   = "✓",
          package_pending     = "➜",
          package_uninstalled = "✗",
        },
      },
      max_concurrent_installers = 4,
    },
  },

  -- ──────────────────────────────────────────────────────────────────────────
  -- 2. MASON-LSPCONFIG
  -- Bridges Mason and nvim-lspconfig.
  --   • ensure_installed: auto-installs listed servers via Mason
  --   • automatic_enable: calls vim.lsp.enable() for every Mason-installed server
  -- ──────────────────────────────────────────────────────────────────────────
  {
    "mason-org/mason-lspconfig.nvim",
    -- Dependencies must be loaded BEFORE this plugin initializes.
    -- lazy.nvim respects this order automatically.   
    dependencies = {
      { "mason-org/mason.nvim" },
      "neovim/nvim-lspconfig",
    },
    opts = {
      
      -- Servers to auto-install if not already present on the system.
      -- Trim list to desired languages 
      -- Installing Many servers on first launch will be slow. 
      -- Add more as required
      ensure_installed = {
        -- Extend when needed
        --
        -- "arduino_language_server", "clojure_lsp", "elixirls","julials",
        -- "kotlin_language_server",  "ocamllsp", "intelephense", "powershell_es",
        -- "solargraph", "solidity_ls", "perlpls", 
        --
        --  These Need a non-trivial extra configuration to get 'em working
        -- "jdtls",   -- download a full JDT runtime
        -- "metals",  -- bootstraps an entire Scala toolchain 
        --
        -- Only add if you install the Swift toolchain on your machine, and note it won't
        -- be Mason-managed; you'd enable it via vim.lsp.enable('sourcekit') manually.
        -- "sourcekit", 
        
        -- Web / JS ecosystem
        "ts_ls",          -- TS & JS (NOTE: "tsserver" name was deprecated)
        "html",           -- HTML
        "cssls",          -- CSS / SCSS / Less
        "jsonls",         -- JSON with schema support
        "eslint",         -- ESLint as an LSP (diagnostics + fix-on-save)
        "astro",          -- Astro framework
        "angularls",      -- Angular framework
        "svelte",         -- Svelte framework
        "graphql",        -- GraphQL
        "prismals",       -- Prisma ORM schemas
        "lemminx",        -- XML

        -- Systems / compiled languages
        "lua_ls",         -- Lua
        "clangd",         -- C and C++
        "cmake",
        "rust_analyzer",  -- Rust (large binary)
        "gopls",          -- Go
        "zls",            -- Zig

        -- Scripting / interpreted
        "pyright",        -- Python (static type checker + LSP)
        "bashls",         -- Bash / shell scripts

        -- Config & markup
        "yamlls",         -- YAML (with schema support)
        "taplo",          -- TOML
        "dockerls",       -- Dockerfile
        "marksman",       -- Markdown (link checking, references)

        -- Extras
        -- "volar",          -- Vue 3 (but mason doesn't recorgnize it)
        "helm_ls",        -- Helm chart templates
        --"nixd",           -- Nix expressions
        "sqlls",          -- SQL
        "vimls",
      },

      -- automatic_enable: mason-lspconfig calls vim.lsp.enable() for every
      -- server it installs. This is the default. Exclude specific servers here
      -- if you want to manage their enable/disable manually.
      -- Example: automatic_enable = { exclude = { "rust_analyzer" } }
      automatic_enable = true,
    },
  },

  -- ──────────────────────────────────────────────────────────────────────────
  -- 3. NVIM-LSPCONFIG
  -- Provides pre-written default configs for hundreds of language servers.
  -- So you don't have to write 'em yourself
  -- (cmd, filetypes, root detection)
  -- Also handles: diagnostic display, gutter signs,
  -- per-server overrides (via exposing the lspcnfig.server_name.setup() API),
  -- and the LspAttach autocmd that sets buffer-local keymaps.
  -- ──────────────────────────────────────────────────────────────────────────
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
      -- blink.cmp must load before lspconfig so its capabilities are available
      -- when we call lspconfig.server.setup() below.
      "saghen/blink.cmp",
    },
    config = function()

      -- ── BLINK.CMP CAPABILITIES ─────────────────────────────────────────
      -- blink.cmp extends the LSP capabilities that Neovim advertises to
      -- servers. "Capabilities" is the handshake where Neovim tells the server
      -- what features the editor supports (snippets, resolve support, etc.).
      -- Without this, servers send basic completions; with it, they send
      -- richer data including snippet placeholders and full documentation.
      --
      -- We set this ONCE globally via vim.lsp.config("*", ...) so it applies
      -- to every server automatically — no need to add it to each setup() call.
      local blink_capabilities = require("blink.cmp").get_lsp_capabilities()
      vim.lsp.config("*", { capabilities = blink_capabilities })

      -- ── DIAGNOSTIC DISPLAY ─────────────────────────────────────────────
      -- Controls how Neovim renders LSP errors/warnings visually in thy buffer.
      -- This is separate from keymaps - it's a global visual configuration.
      vim.diagnostic.config({

        -- virtual_text: show the diagnostic message as faded text at the
        -- END of the line (same line as the error). Always visible.
        -- DISABLED here because virtual_lines covers the current line better.
        -- PREV:
        -- virtual_text = {
          -- spacing = 4,  -- spaces btn code and message
          -- prefix = "●", -- symbol before each diagnostic message
        --}, 
        virtual_text = false,

        -- virtual_lines: shows the full diagnostic message on a dedicated
        -- line BELOW the offending code, with an arrow pointing up to it.
        -- current_line = true: only show this for the line the cursor is on,
        -- keeping the rest of the buffer clean.
        --
        -- NOTE: Previously, both virtual_text and virtual_lines were enabled
        -- simultaneously, which caused duplicate messages on the current line.
        -- The fix: disable virtual_text, enable virtual_lines for current line.
        -- If you want always-visible inline hints on every line, swap them:
        --   virtual_text = { spacing = 4, prefix = "●" }
        --   virtual_lines = false
        --
        virtual_lines = { current_line = true },

        -- Show the error/warning/hint/info icons in the sign column (gutter).
        signs = {
          -- Neovim 0.10+ API: set sign text directly in diagnostic.config().
          -- This replaces the legacy vim.fn.sign_define() calls.
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN]  = " ",
            [vim.diagnostic.severity.HINT]  = "󰠠 ",
            [vim.diagnostic.severity.INFO]  = " ",
          },
        },

        -- THE LEGACY PATH         
        -- ── DIAGNOSTIC SIGNS (gutter icons) ──────────────────────────────────
        -- These are the icons shown in the sign column (the thin column left of
        -- line numbers) to indicate errors, warnings, hints, and info.
        --local signs = {
        --  Error = " ",
        --  Warn  = " ",
        --  Hint  = "󰠠 ",
        --  Info  = " ",
        --}
        --for type, icon in pairs(signs) do
          -- "DiagnosticSign" .. "Error" → "DiagnosticSignError", etc.
        --  local hl = "DiagnosticSign" .. type
        --  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
        --end


        -- Don't update diagnostics while you're actively typing in insert mode.
        -- Diagnostics update when you leave insert mode instead.
        -- Reason: mid-word, half-typed expressions are almost always "errors"
        -- that disappear as soon as you finish the word. Updating in-insert
        -- creates constant noise that trains you to ignore the signs.
        update_in_insert = false,

        -- Sort diagnostics: errors first, then warnings, hints, info.
        severity_sort = true,

        -- Floating window style when you open a diagnostic with <leader>e.
        float = {
          border = "rounded",
          source = true,   -- show which LSP server produced this diagnostic
        },
      })

      -- ── PER-SERVER SETTINGS ────────────────────────────────────────────
      -- For most servers, mason-lspconfig + nvim-lspconfig defaults are
      -- sufficient — you don't need a setup() call at all.
      -- Only use this section for specific overrides.
      -- like passing extra settings, disabling a feature, or customizing root
      -- detection for a particular server.
      --
      local lspconfig = require("lspconfig")
      -- MIGRATION NOTE: The old pattern was:
      --   local lspconfig = require("lspconfig")
      --   lspconfig.lua_ls.setup({ settings = { ... } })
      --
      -- In Neovim 0.11 + nvim-lspconfig v2.x, `require("lspconfig")` is
      -- deprecated. The new API is:
      --   vim.lsp.config("server_name", { settings = { ... } })  -- set config
      --   vim.lsp.enable("server_name")                          -- activate it
      --
      -- vim.lsp.config("*", ...) was already called above for capabilities.
      -- Per-server overrides just call vim.lsp.config() with that server's name.
      -- mason-lspconfig's automatic_enable = true calls vim.lsp.enable() for us,
      -- so we only need to call vim.lsp.config() here.
      --
      -- OLD PATTERN
      --lspconfig.lua_ls.setup({
      --  settings = {
      --    Lua = {
      --      runtime = {
      --        version = "LuaJIT",
      --      },
      --      diagnostics = {  
      --        globals = { "vim", "require" },
      --      },
      --      workspace = {
      --        library = vim.api.nvim_get_runtime_file("", true),
      --        checkThirdParty = false,
      --      },
      --      telemetry = {
      --        enable = false,
      --      },
      --    },
      --  },
      --})
      --
      -- lua_ls: Tell the Lua language server that "vim" is a valid global.
      -- Without this, every `vim.*` call in your Neovim config gets flagged
      -- as "undefined global 'vim'".
      -- 
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            runtime = {
              version = "LuaJIT",   -- Neovim uses LuaJIT, not standard Lua 5.x
            },
            diagnostics = {
              -- Recognize these globals so lua_ls doesn't warn about them.
              globals = { "vim", "require" },
            },
            workspace = {
              -- Make lua_ls aware of Neovim's built-in Lua API.
              -- Enables autocomplete and type info for vim.* functions.
              library = vim.api.nvim_get_runtime_file("", true),
              -- Suppress the "configure work environment?" prompt on first launch.
              checkThirdParty = false,
            },
            telemetry = {
              enable = false,
            },
          },
        },
      })

      -- jsonls: Enable JSON schema validation.
      -- Schemas tell the server what keys are valid in specific JSON files
      -- (package.json, tsconfig.json, .eslintrc.json, etc.).
      vim.lsp.config("jsonls", {
        settings = {
          json = {
            validate = { enable = true },
            -- To get automatic schema detection, add the optional plugin:
            -- "b0o/schemastore.nvim" and replace the above with:
            -- schemas = require("schemastore").json.schemas(),
            -- Without the plugin, you can hardcode schemas like:
            
            --   { fileMatch = { "package.json" }, url = "https://json.schemastore.org/package.json" },
            -- },
          },
        },
      })
 
      -- yamlls: YAML schema validation (same idea as jsonls).
      vim.lsp.config("yamlls", {
        settings = {
          yaml = {
            schemaStore = {
              enable = true, -- use built-in schema store
              url    = "",   -- required field when enable = true
            },
            validate = true,
            format   = { enable = true },
          },
        },
      })

      -- ts_ls: TypeScript / JavaScript.
      -- No extra settings needed — the defaults are good.
      -- The name changed from "tsserver" to "ts_ls" in recent versions.
      -- (Nothing to call here since we have no overrides, but kept as a
      --  comment so we know where to add TypeScript-specific settings later.)      
      --
      -- Adding `init_options` enables support for TypeScript plugins if needed.
      -- vim.lsp.config("ts_ls", {
          -- Uncomment for Angular/ Vue and need TS plugin support:
          -- init_options = {
          --   plugins = { ... }
          -- }
      -- }) 

      -- ── LSPATTACH AUTOCMD ────────────────────────────────────────────── 
      -- WHY LspAttach instead of global keymaps?
      --
      --   Global keymaps exist in EVERY buffer, even plain text files where no
      --   LSP is running. Pressing "gd" in a .txt file would call
      --   vim.lsp.buf.definition() and fail silently.
      --
      --   LspAttach fires ONLY when a language server successfully connects to
      --   a buffer. By passing buffer = ev.buf, the keymaps are BUFFER-LOCAL —
      --   they exist only in that buffer and are cleaned up when you close it.
      --
      -- WHY the augroup?
      --   Re-sourcing this file (:source %) without a cleared augroup would
      --   register the autocmd a second time. clear = true prevents duplication.

      local lsp_augroup = vim.api.nvim_create_augroup("UserLspKeymaps", { clear = true })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = lsp_augroup,
        desc  = "Set buffer-local LSP keymaps when a language server attaches",
        callback = function(ev)        
          -- ev.buf    → the buffer number the server just attached to
          -- ev.data.client_id → the ID of the LSP client (server instance)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if not client then return end -- safety guard: abort if client not found
          
          -- Shared options for all keymaps in this buffer:
          --   buffer  = ev.buf  → makes the keymap LOCAL to this buffer only
          --   noremap = true    → prevents this mapping from being re-mapped by other plugins
          --   silent  = true    → suppresses "Press ENTER" prompts

          -- Import the SSOT keymap table.
          local K = require("cide-keymaps")

          -- Local helper: creates buffer-local, noremap, silent opts with a desc.
          -- The desc appears in :map output and in the which-key popup.
          local function opts(description)
            return {
              buffer  = ev.buf,
              noremap = true,
              silent  = true,
              desc    = description,
            }
          end

          -- ── NAVIGATION ───────────────────────────────────────────────
          -- Jump to where a symbol is DEFINED (where it was written/declared).
          vim.keymap.set("n", K.lsp.definition,      vim.lsp.buf.definition,     opts("LSP: go to definition"))
          -- Jump to the DECLARATION (e.g. header in C, interface in TypeScript).
          vim.keymap.set("n", K.lsp.declaration,     vim.lsp.buf.declaration,    opts("LSP: go to declaration"))
          -- Jump to the TYPE DEFINITION (hover on a variable → jump to its type).
          vim.keymap.set("n", K.lsp.type_definition, vim.lsp.buf.type_definition, opts("LSP: go to type definition"))
          -- Show all IMPLEMENTATIONS of an interface or abstract method.
          vim.keymap.set("n", K.lsp.implementation,  vim.lsp.buf.implementation,  opts("LSP: go to implementation"))
          -- List all REFERENCES to the symbol under cursor across the project.
          vim.keymap.set("n", K.lsp.references,      vim.lsp.buf.references,      opts("LSP: show all references"))

          -- ── INFORMATION ──────────────────────────────────────────────
          -- Show documentation popup. Press K again while popup is open to
          -- enter it and scroll with <C-d>/<C-u>.
          vim.keymap.set("n", K.lsp.hover, vim.lsp.buf.hover, opts("LSP: hover documentation"))

          -- Signature help: shows the parameters of the function you're calling.
          -- Insert mode: natural trigger while typing inside function parentheses.
          -- Normal mode: gK (intentionally distinct from K which is hover).
          --
          -- NOTE: <C-k> is intentionally NOT used here.
          -- <C-k> is owned by nvim-tmux-navigation (navigate pane up).
          -- Using it here would silently overwrite that binding in every LSP buffer.
          vim.keymap.set("i", K.lsp.signature_help_i, vim.lsp.buf.signature_help, opts("LSP: signature help (insert)"))
          vim.keymap.set("n", K.lsp.signature_help_n, vim.lsp.buf.signature_help, opts("LSP: signature help (normal)"))

          -- ── EDITING ──────────────────────────────────────────────────
          -- Rename the symbol under cursor across ALL files in the project.
          -- Scope-aware — safer than a search-and-replace.
          vim.keymap.set("n", K.lsp.rename,      vim.lsp.buf.rename,      opts("LSP: rename symbol"))
          -- Code actions: quick fixes, auto-imports, refactors, etc.
          -- Works in visual mode too (for range-based actions).
          vim.keymap.set({ "n", "v" }, K.lsp.code_action, vim.lsp.buf.code_action, opts("LSP: code actions"))
          -- Format via LSP. async = true so Neovim doesn't freeze on slow servers.
          -- NOTE: conform.nvim's format_on_save is the primary formatter;
          -- this keymap is the LSP-specific manual override.
          vim.keymap.set("n", K.lsp.format, function()
            vim.lsp.buf.format({ async = true })
          end, opts("LSP: format file"))

          -- ── DIAGNOSTICS ──────────────────────────────────────────────
          -- Open a floating window with the full diagnostic at the cursor.
          -- Useful when virtual text is truncated or hard to read.
          vim.keymap.set("n", K.lsp.diagnostic_float, vim.diagnostic.open_float, opts("LSP: show diagnostic detail"))
          -- Navigate diagnostics: jump to next/previous in the current file.
          -- float = true: automatically opens the detail popup when you land on one.
          vim.keymap.set("n", K.lsp.diagnostic_next, function()
            vim.diagnostic.jump({ count = 1, float = true })
          end, opts("LSP: next diagnostic"))
          vim.keymap.set("n", K.lsp.diagnostic_prev, function()
            vim.diagnostic.jump({ count = -1, float = true })
          end, opts("LSP: previous diagnostic"))
          -- Jump specifically to the next/previous ERROR (skips warnings/hints).
          vim.keymap.set("n", K.lsp.error_next, function()
            vim.diagnostic.jump({ count = 1, float = true, severity = vim.diagnostic.severity.ERROR })
          end, opts("LSP: next error"))
          vim.keymap.set("n", K.lsp.error_prev, function()
            vim.diagnostic.jump({ count = -1, float = true, severity = vim.diagnostic.severity.ERROR })
          end, opts("LSP: previous error"))

          -- ── WORKSPACE ────────────────────────────────────────────────
          -- List all symbols in the current file (functions, classes, variables).
          -- Pairs well with Telescope for fuzzy searching.
          vim.keymap.set("n", K.lsp.document_symbols,  vim.lsp.buf.document_symbol,  opts("LSP: document symbols"))
          -- Same but across the whole project workspace.
          vim.keymap.set("n", K.lsp.workspace_symbols, vim.lsp.buf.workspace_symbol, opts("LSP: workspace symbols"))

          -- ── INLAY HINTS (Neovim 0.10+) ───────────────────────────────
          -- Inlay hints are subtle inline annotations: inferred types, parameter
          -- names, etc. Example: add(/*x=*/1, /*y=*/2).
          -- Only register the toggle if this server actually supports them.
          if client.supports_method("textDocument/inlayHint") then
            vim.keymap.set("n", K.lsp.inlay_hints, function()
              vim.lsp.inlay_hint.enable(
                not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf })
              )
            end, opts("LSP: toggle inlay hints"))
          end
          
          -- ── FORMAT ON SAVE (opt-in) ────────────────────────────────────
          -- Uncomment the block below if you want the file to auto-format
          -- every time you save. The supports_method guard ensures we only
          -- set this up for servers that actually provide a formatter.
          --
          -- if client.supports_method("textDocument/formatting") then
          --   vim.api.nvim_create_autocmd("BufWritePre", {
          --     buffer = ev.buf,
          --     group  = vim.api.nvim_create_augroup("LspFormatOnSave", { clear = false }),
          --     callback = function()
          --       vim.lsp.buf.format({ bufnr = ev.buf, async = false })
          --     end,
          --   })
          -- end

        end, -- end LspAttach callback
      })

    end, -- end nvim-lspconfig config
  },

  -- ──────────────────────────────────────────────────────────────────────────
  -- 4. MASON TOOL INSTALLER
  -- Single source of truth for everything Mason should keep installed:
  -- LSP servers, formatters (for conform.nvim), and linters (for nvim-lint).
  -- ──────────────────────────────────────────────────────────────────────────
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    opts = {      
      -- Everything Mason can install goes here — LSP servers, formatters, linters.
      -- This is the single source of truth for our entire toolchain.
      -- Use Mason package names here (which differ slightly from lspconfig names
      -- in some cases — e.g. lspconfig uses "ts_ls" but Mason calls it "typescript-language-server").
      ensure_installed = {

        -- ── LSP SERVERS ────────────────────────────────────────────────
        
        -- These overlap with mason-lspconfig's ensure_installed intentionally.
        -- mason-tool-installer handles the installation; mason-lspconfig handles
        -- the enabling. Having both listed in both places is the correct pattern.
        --
        -- Note: Mason package names differ slightly from lspconfig names in
        -- some cases (e.g. lspconfig "ts_ls" = Mason "typescript-language-server").
        "typescript-language-server",  -- ts_ls
        "lua-language-server",         -- lua_ls
        "html-lsp",
        "css-lsp",
        "json-lsp",
        "eslint-lsp",
        "pyright",
        "bash-language-server",
        "yaml-language-server",
        "dockerfile-language-server",
        "taplo",                       -- TOML
        "marksman",                    -- Markdown
        --"nixd",                        -- Nix

        -- ── FORMATTERS (used by conform.nvim) ───────────────────────────────────
        "prettier",                    -- JS/TS/CSS/HTML/JSON/YAML/Markdown
        "stylua",                      -- Lua
        "black",                       -- Python
        "isort",                       -- Python import sorting
        "shfmt",                       -- Shell scripts
        "goimports",                   -- Go

        -- ── LINTERS (nvim-lint) ─────────────────────────────────────────
        "eslint_d",                    -- JS/TS (daemon, much faster than eslint)
        "pylint",                      -- Python
        --"luacheck",                    -- Lua
        "shellcheck",                  -- Shell scripts
        "markdownlint",                -- Markdown
        "hadolint",                    -- Dockerfile
      },


      -- Check for tool updates automatically on startup.
      -- false = only install missing tools, don't auto-update existing ones.
      -- Prevents Mason from running upgrade checks on every startup. 
      -- Set to true if you want Mason to keep everything current on every launch
      -- (slightly slower startup, but you're always on latest versions).
      auto_update = false,
    },
  },

}
