-- Neovim configuration

-- ── Line numbers ────────────────────────────────────────────────────────────
-- Show the absolute number on the current line and relative distances above and
-- below it (hybrid mode).
vim.opt.number = true         -- absolute number on the cursor's line
vim.opt.relativenumber = true -- count away from the cursor on every other line

-- ── Search ──────────────────────────────────────────────────────────────────
-- Case-insensitive search until you type a capital, then case-sensitive.
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- ── Clipboard ───────────────────────────────────────────────────────────────
-- Route yank/delete/put through the OS clipboard so copy-paste works across apps.
vim.opt.clipboard = 'unnamedplus'

-- ── Undo ────────────────────────────────────────────────────────────────────
-- Persist undo history to disk so undo/redo survives closing and reopening files.
vim.opt.undofile = true

-- ── Gutter / UI ─────────────────────────────────────────────────────────────
vim.opt.signcolumn = 'yes'  -- always reserve the sign column so text doesn't shift
vim.opt.cursorline = true   -- highlight the line the cursor is on
vim.opt.scrolloff = 8       -- keep 8 lines of context above/below the cursor

-- ── Splits ──────────────────────────────────────────────────────────────────
vim.opt.splitright = true   -- vertical splits open to the right
vim.opt.splitbelow = true   -- horizontal splits open below

-- ── Responsiveness ──────────────────────────────────────────────────────────
vim.opt.updatetime = 250    -- faster CursorHold (LSP hover, diagnostics, gitsigns)
vim.opt.timeoutlen = 300    -- shorter wait for mapped key sequences

-- ── Line wrapping ───────────────────────────────────────────────────────────
-- When lines wrap, keep continuation indented and break at word boundaries.
vim.opt.breakindent = true
vim.opt.linebreak = true

-- ── Indentation ─────────────────────────────────────────────────────────────
-- Insert spaces instead of tabs, 2 spaces per indent level.
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.smartindent = true

-- ── Whitespace visibility ───────────────────────────────────────────────────
-- Render tabs, trailing spaces, and non-breaking spaces so they're visible.
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- ── Filetype detection ──────────────────────────────────────────────────────
-- Treat *.Dockerfile (e.g. base-image.Dockerfile) as Dockerfile syntax.
vim.filetype.add({
  pattern = {
    ['.*%.Dockerfile'] = 'dockerfile',
  },
})

-- ── Colorscheme ─────────────────────────────────────────────────────────────
-- Bundled with Neovim 0.12+. The stock default scheme renders keywords as bold
-- with no color; catppuccin gives every syntax group a distinct color.
vim.cmd.colorscheme('catppuccin')

-- ── Plugins ─────────────────────────────────────────────────────────────────
-- Managed by Neovim's built-in package manager (vim.pack, 0.12+).
-- nvim-treesitter's `main` branch: parser installer + highlight queries.
-- Parsers are compiled on install; requires the tree-sitter CLI and a C
-- compiler (`brew install tree-sitter-cli`).
vim.pack.add({
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
})

-- ── Tree-sitter highlighting ────────────────────────────────────────────────
-- Prefer tree-sitter over regex syntax everywhere a parser exists. On opening
-- a buffer: start tree-sitter if the parser is installed; otherwise install it
-- in the background (when available) and start once ready. Filetypes with no
-- tree-sitter parser fall back to the regex :syntax engine untouched.
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('treesitter-highlight', { clear = true }),
  callback = function(args)
    local ft = args.match
    -- Map filetype → parser language (e.g. filetype `sh` → parser `bash`).
    local lang = vim.treesitter.language.get_lang(ft)
    if not lang then return end

    -- Parser already installed: turn on tree-sitter for this buffer.
    if vim.treesitter.language.add(lang) then
      vim.treesitter.start(args.buf, lang)
      return
    end

    -- Not installed: auto-install if nvim-treesitter offers it, then start.
    local ok, ts = pcall(require, 'nvim-treesitter')
    if not ok or not vim.tbl_contains(ts.get_available(), lang) then return end
    ts.install(lang):await(function()
      if vim.api.nvim_buf_is_valid(args.buf)
          and vim.bo[args.buf].filetype == ft
          and vim.treesitter.language.add(lang) then
        vim.treesitter.start(args.buf, lang)
      end
    end)
  end,
})
