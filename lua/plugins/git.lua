-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- lua/plugins/git.lua
-- GIT INTEGRATION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Two plugins, two complementary responsibilities:
--   gitsigns  → in-buffer: hunk markers, staging, blame, navigation
--   fugitive  → full git workflow: status, commit, push, log, diff
--
-- All keybindings are read from cide-keymaps.lua (the SSOT).
-- To change a key, edit it there — not in this file.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

return {

  -- ──────────────────────────────────────────────────────────────────────────
  -- GITSIGNS — in-buffer git hunk experience
  -- ──────────────────────────────────────────────────────────────────────────
  -- Shows a colored symbol in the sign column for every changed line:
  --   │  (green)  = added line
  --   │  (red)    = deleted line (shown as a marker at the deletion point)
  --   │  (yellow) = modified line
  --
  -- Beyond signs, it enables staging/unstaging individual hunks without
  -- leaving the buffer, inline blame, and hunk previews.
  {
    "lewis6991/gitsigns.nvim",

    -- Load when a file buffer opens — no point loading before a file exists.
    event = { "BufReadPre", "BufNewFile" },

    opts = {
      signs = {
        -- Characters shown in the sign column for each change type.
        add          = { text = "│" },
        change       = { text = "│" },
        delete       = { text = "_" },
        topdelete    = { text = "‾" },
        changedelete = { text = "~" },
        untracked    = { text = "┆" },
      },

      -- Show blame annotation at the end of the current line.
      -- Shows WHO changed this line and WHEN, inline. Off by default —
      -- toggle with <leader>tb (defined in on_attach below).
      current_line_blame = false,
      current_line_blame_opts = {
        virt_text         = true,
        virt_text_pos     = "eol",   -- end of line
        delay             = 800,     -- wait 800ms after cursor stops moving
        ignore_whitespace = false,
      },

      -- on_attach: gitsigns fires this when attaching to a buffer.
      -- Same pattern as LspAttach — keymaps here are buffer-local,
      -- so they only exist in git-tracked files.
      on_attach = function(bufnr)
        -- Import the SSOT keymap table.
        -- All key strings come from here — never hardcoded in this file.
        local K  = require("cide-keymaps")
        local gs = package.loaded.gitsigns

        -- Local helper to reduce repetition. Applies buffer-local, silent,
        -- noremap opts automatically and surfaces the desc to which-key.
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, {
            buffer  = bufnr,
            noremap = true,
            silent  = true,
            desc    = desc,
          })
        end

        -- ── HUNK NAVIGATION ────────────────────────────────────────────
        -- "Hunk" = a contiguous block of changed lines.
        -- The vim.wo.diff guard makes ]h / [h work correctly in diff
        -- buffers (fugitive, git log) using Vim's built-in ]c / [c.
        map("n", K.git.next_hunk, function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gs.next_hunk()
          end
        end, "Git: next hunk")

        map("n", K.git.prev_hunk, function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gs.prev_hunk()
          end
        end, "Git: previous hunk")

        -- ── STAGING ────────────────────────────────────────────────────
        -- Stage/unstage individual hunks without touching the terminal.
        -- "Stage" = add to git's index (the pre-commit staging area).
        map("n", K.git.stage_hunk, gs.stage_hunk,      "Git: stage hunk")
        map("n", K.git.reset_hunk, gs.reset_hunk,      "Git: reset hunk")
        map("n", K.git.undo_stage, gs.undo_stage_hunk, "Git: undo stage hunk")

        -- Visual mode: stage/reset only the lines selected within a hunk.
        map("v", K.git.stage_hunk, function()
          gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Git: stage selected lines")
        map("v", K.git.reset_hunk, function()
          gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Git: reset selected lines")

        -- Stage or reset the entire file buffer at once.
        map("n", K.git.stage_buffer, gs.stage_buffer, "Git: stage entire buffer")
        map("n", K.git.reset_buffer, gs.reset_buffer, "Git: reset entire buffer")

        -- ── INSPECTION ─────────────────────────────────────────────────
        -- Preview the diff of the hunk under cursor in a floating window.
        map("n", K.git.preview_hunk, gs.preview_hunk, "Git: preview hunk diff")

        -- Blame for the current line — full = shows the full commit message.
        map("n", K.git.blame_line, function()
          gs.blame_line({ full = true })
        end, "Git: blame current line (full)")

        -- Toggle the inline EOL blame annotation for the current line.
        map("n", K.git.toggle_blame, gs.toggle_current_line_blame, "Git: toggle inline blame")

        -- Diff the buffer against the index (what's staged).
        map("n", K.git.diff_index, gs.diffthis, "Git: diff buffer against index")

        -- Diff the buffer against HEAD (last commit). "~" = one commit back.
        map("n", K.git.diff_head, function()
          gs.diffthis("~")
        end, "Git: diff buffer against HEAD")

        -- Toggle showing deleted lines as virtual text above the deletion point.
        map("n", K.git.toggle_deleted, gs.toggle_deleted, "Git: toggle deleted lines display")

        -- ── TEXT OBJECT ────────────────────────────────────────────────
        -- "ih" = "inner hunk" — select the changed lines of a hunk.
        -- Works with operators: "vih" selects a hunk, "dih" deletes it, etc.
        map({ "o", "x" }, "ih", ":<C-u>Gitsigns select_hunk<CR>", "Git: select hunk (text object)")
      end,
    },
  },

  -- ──────────────────────────────────────────────────────────────────────────
  -- FUGITIVE — full git workflow inside Neovim
  -- ──────────────────────────────────────────────────────────────────────────
  -- Fugitive turns Neovim into a complete git client. The core interface
  -- is :Git (or :G) which opens a status window where you can stage,
  -- commit, push, pull, and navigate history without leaving the editor.
  --
  -- Key fugitive concepts:
  --   :Git          → status window (s=stage, u=unstage, cc=commit, P=push)
  --   :Git diff     → diff the working tree
  --   :Git log      → browsable commit log
  --   :Git blame    → whole-file blame view (different from gitsigns line blame)
  --   :GBrowse      → open the current file/line on GitHub/GitLab in browser
  --   :Gread        → replace buffer with git index version of the file
  --   :Gwrite       → stage the current file (equivalent to git add)
  {
    "tpope/vim-fugitive",

    -- cmd: lazy-loads fugitive when one of these commands is first called.
    -- event: also load when a buffer opens (needed for status window triggers).
    cmd   = { "Git", "G", "Gdiffsplit", "Gread", "Gwrite", "GBrowse" },
    event = { "BufReadPre" },

    config = function()
      -- Fugitive needs no setup() call — it works out of the box.
      -- This config block only adds keymaps.

      -- Import the SSOT keymap table.
      local K = require("cide-keymaps")

      -- Fugitive keymaps are GLOBAL (not buffer-local) because you need to
      -- trigger the status window from any buffer, not just git-tracked ones.
      local function map(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, {
          noremap = true,
          silent  = true,
          desc    = desc,
        })
      end

      -- Open the git status window — the main fugitive interface.
      -- Inside the window: press ? to see all available keymaps.
      map(K.git.status,     "<cmd>Git<cr>",                "Git: open status window (fugitive)")
      map(K.git.commit,     "<cmd>Git commit<cr>",          "Git: commit")
      map(K.git.push,       "<cmd>Git push<cr>",            "Git: push")
      map(K.git.pull,       "<cmd>Git pull<cr>",            "Git: pull")
      map(K.git.log,        "<cmd>Git log --oneline<cr>",   "Git: log (oneline)")
      map(K.git.diff_split, "<cmd>Gdiffsplit<cr>",          "Git: diff split current file")
      map(K.git.blame_file, "<cmd>Git blame<cr>",           "Git: blame view (whole file)")
    end,
  },

}
