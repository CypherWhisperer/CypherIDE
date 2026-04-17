-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- lua/plugins/tree-sitter.lua
-- NVIM-TREESITTER — Syntax Parsing and Highlighting
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Treesitter builds a real syntax tree of your code — it "understands"
-- the structure of the language rather than just matching regex patterns.
-- This powers: accurate highlighting, indentation, incremental selection,
-- and is the foundation that many other plugins (gitsigns, indent-blankline,
-- nvim-ts-autotag, etc.) build on top of.
--
-- IMPORTANT: WHY `main` + `opts` INSTEAD OF `config = function()`?
--
--   The previous pattern was:
--     config = function()
--       require("nvim-treesitter.configs").setup({ ... })
--     end
--
--   This fails on NixOS (and sometimes anywhere with `lazy = false`) because:
--   lazy.nvim hasn't added the plugin's directory to the rtp yet at the point
--   the config function runs for a `lazy = false` plugin. So Lua's `require`
--   can't find "nvim-treesitter.configs" — it isn't on the module search path.
--
--   The fix is lazy.nvim's `main` field:
--     main = "nvim-treesitter.configs"
--     opts = { ... }
--
--   When `main` is set, lazy handles the require() internally, AFTER it has
--   already added the plugin to rtp. It then calls main.setup(opts) for you.
--   This is the correct pattern for any plugin that needs early loading.
--
-- The root cause of module 'nvim-treesitter.configs' not found is a timing 
-- issue: with lazy = false, lazy loads the plugin at startup before it has 
-- finished wiring up the rtp. When the config function immediately calls 
-- require("nvim-treesitter.configs"), the module path isn't set up yet.
--
-- The fix is lazy.nvim's main field, which tells lazy which module to call
-- .setup() on. Lazy then handles the require() itself, after rtp is properly
-- configured. No config function needed at all — the entire setup config 
-- moves into opts = { ... }.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
return {
  "nvim-treesitter/nvim-treesitter",

  -- lazy = false: load at startup, not on-demand.
  -- Treesitter powers syntax highlighting which must be active immediately
  -- when a buffer opens. Lazy-loading it causes a flash of unhighlighted text.
  lazy  = false,

  -- build: runs once after install or update, not on every launch.
  -- :TSUpdate fetches updated parser grammars from the treesitter registry.
  build = ":TSUpdate",

  -- CORRECT PATTERN for NixOS / early-load plugins:
  -- `main` tells lazy.nvim which module to call .setup() on, and lazy handles
  -- the require() after rtp is configured. No `config = function()` needed.
  main = "nvim-treesitter",
  --main = "nvim-treesitter.configs",
  -- CORRECT require path: the configuration API is in the .configs submodule.
  -- require('nvim-treesitter') alone has no setup() — that's a common mistake.

  --
  -- OLD PATTERN
  -- config = function()
  --   require("nvim-treesitter.configs").setup({
  --     -- ensure_installed = { ... },
  --     -- other options
  --   }) 
  -- end,  
  --config = function()
  --  require("nvim-treesitter.configs").setup({
  opts = {
      -- ── PARSER INSTALLATION ──────────────────────────────────────────
      -- ensure_installed: parsers to auto-install on first launch.
      -- "all" would install every available parser — explicit list is better
      -- so you know exactly what's installed and startup isn't slow on first run.
      ensure_installed = {
        -- Core / always useful
        "bash", "c", "cpp", "cmake", "make",
        "lua", "vim", "vimdoc",    -- vimdoc: treesitter for :help buffers

        -- Web
        "html", "css", "scss",
        "javascript", "typescript", "tsx",
        "json", "jsonc",
        "graphql",
        "svelte", "vue", "astro",
        "prisma",                  -- relevant to your stack

        -- Systems / compiled
        "rust", "go", "zig",
        "python",
        "java", "kotlin",          -- JVM languages
        "scala",                   -- Metals/JVM

        -- Markup / config
        "markdown", "markdown_inline",  -- both needed: inline for code blocks
        "yaml", "toml",
        "xml",
        "dockerfile",
        "sql",
        "regex",                   -- regex syntax inside strings

        -- Git
        "diff",                    -- diff buffers (fugitive, git log)
        "git_config",
        "gitattributes",
        "gitcommit",
        "gitignore",

        -- Nix (directly relevant to CypherOS)
        "nix",

        -- Shell / terminal
        "fish",
        "ssh_config",

        -- Misc useful
        "http",                    -- HTTP request files
        "jq",                      -- jq query files
        "printf",                  -- printf format strings
        "solidity",                -- smart contracts
        "mermaid",                 -- mermaid diagrams in markdown

        -- Leave these out unless you actively use them:
        -- "angular", "arduino", "asm", "clojure", "csv", "cuda",
        -- "dart", "elixir", "glimmer", "glimmer_javascript",
        -- "glimmer_typescript", "go", "gpg", "helm", "julia",
        -- "kitty", "ocaml", "php", "perl", "pascal", "powershell",
        -- "ruby", "swift", "tmux", "udev", "zsh"
        -- Add back any you actually need.
      },

      -- Automatically install missing parsers when a file is opened.
      -- If you open a .zig file and don't have the zig parser, it installs it.
      -- Requires a C compiler to be on PATH (gcc/clang) for compilation.
      auto_install = true,

      -- ── HIGHLIGHT ────────────────────────────────────────────────────
      -- Treesitter-based syntax highlighting. Replaces Vim's regex-based
      -- highlighting with a proper parse tree — more accurate, more colorful,
      -- and aware of context (e.g. won't highlight a keyword inside a string).
      highlight = {                 -- NOTE: was "hightlight" in original — silent bug
        enable = true,

        -- Disable for very large files where treesitter re-parsing on every
        -- keystroke causes noticeable lag. 100KB is a reasonable threshold.
        disable = function(_, buf)
          local max_filesize = 100 * 1024  -- 100 KB in bytes
          local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
          if ok and stats and stats.size > max_filesize then
            return true   -- returning true = disable highlight for this buffer
          end
        end,

        -- additional_vim_regex_highlighting: run Vim's old regex highlighter
        -- IN ADDITION to treesitter. Usually you want this false — it causes
        -- conflicts and is slower. Exception: some older colorschemes need it
        -- to highlight certain constructs correctly. Enable only if your
        -- colorscheme looks wrong.
        additional_vim_regex_highlighting = false,
      },

      -- ── INDENTATION ──────────────────────────────────────────────────
      -- Treesitter-aware indentation when you press = or use 'o'/'O'.
      -- More correct than Vim's built-in cindent for complex nested structures.
      -- Note: some languages (Python) can be finicky — disable per-language
      -- in that case: indent = { enable = true, disable = { "python" } }
      indent = { enable = true },

      -- ── INCREMENTAL SELECTION ─────────────────────────────────────────
      -- Expand/shrink your visual selection by syntax node boundaries.
      -- Extremely useful for selecting function args, blocks, etc. precisely.
      --
      -- Start with <C-space> on a word → expands to the node (variable name,
      -- string, etc.) → press again → expands to parent node (argument list,
      -- function body, etc.) → <BS> shrinks back.
      incremental_selection = {
        enable = true,
        keymaps = {
          -- Initialize selection on the node under cursor
          init_selection    = "<C-space>",
          -- Expand selection to the next syntax node boundary
          node_incremental  = "<C-space>",
          -- Shrink selection back to the previous boundary
          node_decremental  = "<BS>",
          -- Expand to the enclosing scope (function, class, block)
          scope_incremental = "<C-s>",
        },
      },

      -- ── TEXT OBJECTS ─────────────────────────────────────────────────
      -- Treesitter-aware text objects. Requires nvim-treesitter-textobjects
      -- plugin (add it as a dependency if you want this section).
      -- Commented here as reference for when you add that plugin:
      --
      -- textobjects = {
      --   select = {
      --     enable    = true,
      --     lookahead = true,  -- jump forward to next text object if not on one
      --     keymaps = {
      --       ["af"] = "@function.outer",  -- around function
      --       ["if"] = "@function.inner",  -- inside function
      --       ["ac"] = "@class.outer",     -- around class
      --       ["ic"] = "@class.inner",     -- inside class
      --       ["aa"] = "@parameter.outer", -- around argument
      --       ["ia"] = "@parameter.inner", -- inside argument
      --     },
      --   },
      --   move = {
      --     enable              = true,
      --     set_jumps           = true,   -- add to jumplist so <C-o> goes back
      --     goto_next_start     = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
      --     goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
      --   },
      -- },
    --})
  --end,
  },
}
