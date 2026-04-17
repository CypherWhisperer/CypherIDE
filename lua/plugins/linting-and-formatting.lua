-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- lua/plugins/linting-and-formatting.lua
-- FORMATTING AND LINTING
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Two separate plugins for two fundamentally different operations:
--   1. FORMATTING  → conform.nvim  (rewrites files to match a style)
--   2. LINTING     → nvim-lint     (analyzes files for problems → diagnostics)
--
-- WHY NOT none-ls (null-ls)?
--   none-ls (null-ls successor) pretends to be an LSP server to relay formatter/linter output
--   through the LSP protocol. It's architectural overhead — a fake server
--   process just to relay CLI output. conform.nvim and nvim-lint do the same
--   jobs directly with less memory and better behavior (conform preserves
--   cursor position and folds; none-ls replaces the whole buffer).
--   The community (LazyVim, kickstart.nvim) has migrated to this pair.
--
-- WHY TWO PLUGINS instead of one?
--   Formatting and linting are fundamentally different operations:
--     • Formatting: "rewrite this file to match a style" — runs on save, produces
--       a new version of the file.
--     • Linting: "analyze this file for problems" — runs as you type/save, produces
--       diagnostics (the red/yellow underlines you already see from LSP).
--   Keeping them separate means you can disable one without touching the other.
--
-- All keybindings read from cide-keymaps.lua (the SSOT).
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

return {

  -- ──────────────────────────────────────────────────────────────────────────
  -- CONFORM.NVIM — Formatter
  -- ──────────────────────────────────────────────────────────────────────────
  -- Runs external formatter binaries (Prettier, Stylua, Black, etc.)
  -- and applies their output to your buffer. Unlike none-ls it
  -- computes a minimal diff — only changed lines are replaced — so cursor
  -- position, folds, and undo history are preserved after formatting.
  {
    "stevearc/conform.nvim",

    -- Lazy-load: only activate when a real file buffer is opened.
    -- BufReadPre = before reading an existing file into a buffer.
    -- BufNewFile  = when creating a new file.
    -- This means conform doesn't load at all if you open Neovim with no file.
    event = { "BufReadPre", "BufNewFile" },

    config = function()
      local conform = require("conform")
      local K       = require("cide-keymaps")

      conform.setup({
        -- ── FORMATTERS BY FILETYPE ────────────────────────────────────
        -- Maps filetype → list of formatters. Formatters run sequentially.
        -- If a formatter isn't installed, conform skips it gracefully.        
        -- You can list multiple formatters per type; they run sequentially
        -- (e.g. isort sorts imports first, then black formats the rest).
        formatters_by_ft = {
          -- Web
          javascript      = { "prettier" },
          typescript      = { "prettier" },
          javascriptreact = { "prettier" },
          typescriptreact = { "prettier" },
          svelte          = { "prettier" },
          vue             = { "prettier" },
          astro           = { "prettier" },
          css             = { "prettier" },
          scss            = { "prettier" },
          html            = { "prettier" },
          json            = { "prettier" },
          jsonc           = { "prettier" },
          yaml            = { "prettier" },
          markdown        = { "prettier" },
          graphql         = { "prettier" },

          -- Lua         
          -- stylua is the standard Lua formatter; installed via Mason: :MasonInstall stylua
          lua             = { "stylua" },

          -- Python: isort fixes import order first, then black formats everything.
          python          = { "isort", "black" },

          -- Shell
          sh              = { "shfmt" },
          bash            = { "shfmt" },
          zsh             = { "shfmt" },

          -- Go: goimports manages imports + formats; gofmt is Go's official formatter.
          go              = { "goimports", "gofmt" },

          -- Rust: rustfmt ships with the Rust toolchain. conform finds it via cargo.
          rust            = { "rustfmt" },

          -- SQL
          sql             = { "sql_formatter" },

          -- Nix (CypherOS / NixOS work)
          nix             = { "nixfmt" },

          -- Fallback: for any filetype with no formatter configured,
          -- trim trailing whitespace — safe for any file type.
          --
          -- try to use any formatter the attached LSP server provides.
          -- The "*" key means "all filetypes".
          -- ["*"] = { "inject" },   -- uncomment to use LSP formatter as last resort

          -- "_" means "filetypes with no formatters configured".
          -- trim_whitespace removes trailing spaces — safe for any file.
          ["_"]           = { "trim_whitespace" },
        },

        -- ── FORMAT ON SAVE ────────────────────────────────────────────
        -- Auto-formats the file when you write with :w.
        -- lsp_fallback: if no conform formatter is configured for this filetype,
        -- fall back to the LSP server's built-in formatter (if it has one).
        -- timeout_ms: abort if the formatter takes longer than 1 second.
        format_on_save = {
          timeout_ms   = 1000, -- abort if formatter takes longer than 1 second
          lsp_fallback = true, -- use LSP formatter if no conform formatter configured
        },

        -- ── FORMATTER-SPECIFIC OPTIONS ────────────────────────────────     
        -- Override settings for individual formatters here.
        -- These are passed directly to the formatter binary.
        formatters = {
          -- Let the project's .prettierrc control tab width and other style.
          -- prose-wrap = always: wrap markdown prose at printWidth (cleaner diffs).
          prettier = {
            prepend_args = { "--prose-wrap", "always" },
          },
          -- shfmt: 2-space indentation for shell scripts.
          shfmt = {
            prepend_args = { "-i", "2" },
          },
        },
      })

      -- ── MANUAL FORMAT KEYMAP ────────────────────────────────────────
      -- Trigger formatting on demand without waiting for a save.
      -- Works in normal mode (whole file) and visual mode (selection).
      -- async = true: Neovim stays responsive while the formatter runs.
      vim.keymap.set({ "n", "v" }, K.format.manual_format, function()
        conform.format({
          lsp_fallback = true,
          async        = true,
          timeout_ms   = 1000,
        })
      end, { desc = "Format: run conform on buffer/selection", noremap = true, silent = true })

    end,
  },

  -- ──────────────────────────────────────────────────────────────────────────
  -- NVIM-LINT — Linter
  -- ──────────────────────────────────────────────────────────────────────────
  -- Runs external linter binaries and feeds their output into Neovim's
  -- diagnostic system — the same system LSP uses for errors and warnings.
  -- Lint results appear with the same signs, virtual text, and keymaps
  -- already configured in lsp-config.lua.
  --
  -- NOTE: LSP servers (ts_ls, pyright, lua_ls) already provide SOME diagnostics.
  -- nvim-lint adds the linter's perspective on top:
  --   ts_ls   → TypeScript type errors
  --   eslint_d → style rules and lint violations
  -- They complement, not conflict with, each other.
  {
    "mfussenegger/nvim-lint",
    -- Same lazy-load strategy as conform: only load when a buffer is opened.
    event = { "BufReadPre", "BufNewFile" },

    config = function()
      local lint = require("lint")
      local K    = require("cide-keymaps")

      -- ── LINTERS BY FILETYPE ──────────────────────────────────────────
      -- The KEY is the filetype (e.g. "markdown"), NOT the linter name.
      -- Maps filetype → list of linters to run.
      -- Installed via Mason 
      lint.linters_by_ft = {
        -- JavaScript / TypeScript
        -- eslint_d is the daemon version: starts once, stays running.
        -- Much faster than cold-starting eslint on every lint trigger.
        javascript      = { "eslint_d" },
        typescript      = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        svelte          = { "eslint_d" },
        vue             = { "eslint_d" },

        -- Python
        python          = { "pylint" },

        -- Lua
        -- luacheck checks for undefined globals, unused variables, etc.       
        lua             = { "luacheck" },

        -- Shell        
        -- shellcheck is the gold standard for bash/sh linting.
        sh              = { "shellcheck" },
        bash            = { "shellcheck" },

        -- Markdown — key is "markdown" (the filetype), value is the linter name
        markdown        = { "markdownlint" },

        -- Docker
        dockerfile      = { "hadolint" },

        -- Nix: runs `nix-instantiate --parse`.
        -- Consider:
        --   "statix"  -> style checks OR/AND
        --   "deadnix" -> dead code.
        nix             = { "nix" },
      }

      -- ── LINT TRIGGER AUTOCMD ────────────────────────────────────────
      -- nvim-lint doesn't auto-lint — you tell it when to run.
      -- These events cover the most useful trigger points:
      --
      --   BufEnter     → switching to a buffer catches already-open files
      --   BufWritePost → after saving catches changes you just wrote
      --   InsertLeave  → leaving insert mode gives near-realtime feedback
      --
      -- TextChanged (every keystroke) is intentionally excluded — it would
      -- spawn a new linter process on every character you type.
      local lint_augroup = vim.api.nvim_create_augroup("nvim-lint", { clear = true })

      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        group    = lint_augroup,
        callback = function()
          -- try_lint() checks if a linter is configured for the current filetype.
          -- If none is configured, it does nothing silently — safe to call always.
          lint.try_lint()
        end,
      })

      -- ── MANUAL LINT KEYMAP ──────────────────────────────────────────     
      -- Trigger linting on demand. Useful if you want to check a file without
      -- waiting for a save or a mode change.
      vim.keymap.set("n", K.format.manual_lint, function()
        lint.try_lint()
      end, { desc = "Lint: trigger linter on current buffer", noremap = true, silent = true })

    end,
  },

}
