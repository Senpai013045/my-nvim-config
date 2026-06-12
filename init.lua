vim.loader.enable()

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true

vim.o.number = true
vim.o.relativenumber = true
vim.o.mouse = 'a'
vim.o.showmode = false
-- Defer to avoid startup-time cost
vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)
vim.o.breakindent = true
vim.o.expandtab = true
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = 'yes'
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.o.inccommand = 'split'
vim.o.cursorline = true
vim.o.virtualedit = 'block'
vim.o.scrolloff = 10
vim.o.confirm = true

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

vim.diagnostic.config {
  update_in_insert = false,
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = { min = vim.diagnostic.severity.WARN } },
  virtual_text = true,
  virtual_lines = false,
  -- Auto-open diagnostic float when jumping with [d / ]d
  jump = {
    on_jump = function(_, bufnr) vim.diagnostic.open_float { bufnr = bufnr, scope = 'cursor', focus = false } end,
  },
}

vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  -- vim.hl.on_yank is the newer API for flash-on-yank
  callback = function() vim.hl.on_yank() end,
})

vim.o.autoread = true
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter' }, {
  pattern = '*',
  command = "if mode() != 'c' | checktime | endif",
})

local function run_build(name, cmd, cwd)
  local result = vim.system(cmd, { cwd = cwd }):wait()
  if result.code ~= 0 then
    local stderr = result.stderr or ''
    local stdout = result.stdout or ''
    local output = stderr ~= '' and stderr or stdout
    if output == '' then output = 'No output from build command.' end
    vim.notify(('Build failed for %s:\n%s'):format(name, output), vim.log.levels.ERROR)
  end
end

-- Post-install build steps for compiled plugins
vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    local name = ev.data.spec.name
    local kind = ev.data.kind
    if kind ~= 'install' and kind ~= 'update' then return end

    if name == 'telescope-fzf-native.nvim' and vim.fn.executable 'make' == 1 then
      run_build(name, { 'make' }, ev.data.path)
      return
    end
  end,
})

-- Shorthand for plugin URLs
local function gh(repo) return 'https://github.com/' .. repo end

if vim.g.have_nerd_font then vim.pack.add { gh 'nvim-tree/nvim-web-devicons' } end

-- ===== Theme =====
vim.pack.add { gh 'catppuccin/nvim' }
require('catppuccin').setup {
  flavour = 'mocha',
  transparent_background = true,
}
vim.cmd.colorscheme 'catppuccin'

-- ===== Which-key =====
vim.pack.add { gh 'folke/which-key.nvim' }
require('which-key').setup {
  delay = 0,
  icons = { mappings = vim.g.have_nerd_font },
  spec = {
    { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
    { '<leader>t', group = '[T]oggle' },
    { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
    { 'gr', group = 'LSP Actions', mode = { 'n' } },
  },
}

-- ===== Guess-indent =====
vim.pack.add { gh 'NMAC427/guess-indent.nvim' }
require('guess-indent').setup {}

-- ===== Todo-comments =====
vim.pack.add { gh 'folke/todo-comments.nvim' }
require('todo-comments').setup { signs = false }

-- ===== mini.nvim (ai, surround, statusline) =====
vim.pack.add { gh 'nvim-mini/mini.nvim' }
require('mini.ai').setup {
  mappings = { around_next = 'aa', inside_next = 'ii' },
  n_lines = 500,
}
require('mini.surround').setup()
require('mini.pairs').setup()
-- ===== Statusline (lualine) =====
vim.pack.add { gh 'nvim-lualine/lualine.nvim' }
require('lualine').setup {}

-- ===== Indent guides =====
vim.pack.add { gh 'lukas-reineke/indent-blankline.nvim' }
require('ibl').setup {}

-- ===== Treesitter =====
-- Auto-install tree-sitter CLI if missing (needed for compiling parsers).
-- Installs locally under stdpath('data'), no sudo needed.
-- Works automatically on fresh clones — zero manual setup required.
local ts_bin = vim.fn.stdpath 'data' .. '/tree-sitter-cli/node_modules/.bin'
vim.env.PATH = ts_bin .. ':' .. (vim.env.PATH or '')

if vim.fn.executable 'tree-sitter' ~= 1 then
  if vim.fn.executable 'npm' == 1 then
    vim.notify('Installing tree-sitter-cli (one-time)...', vim.log.levels.INFO)
    pcall(function() vim.system({ 'npm', 'install', '--prefix', vim.fn.stdpath 'data' .. '/tree-sitter-cli', 'tree-sitter-cli' }):wait() end)
  end
end

vim.pack.add { gh 'nvim-treesitter/nvim-treesitter' }
pcall(function() require('nvim-treesitter').install { 'javascript', 'typescript', 'tsx', 'html', 'css', 'json', 'markdown' } end)

-- Attach treesitter per filetype (Neovim 0.12 native API)
vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    local lang = vim.treesitter.language.get_lang(args.match)
    if lang and vim.treesitter.language.add(lang) then vim.treesitter.start(args.buf, lang) end
  end,
})

-- ===== Telescope =====
local telescope_plugins = {
  gh 'nvim-lua/plenary.nvim',
  gh 'nvim-telescope/telescope.nvim',
  gh 'nvim-telescope/telescope-ui-select.nvim',
}
if vim.fn.executable 'make' == 1 then table.insert(telescope_plugins, gh 'nvim-telescope/telescope-fzf-native.nvim') end
vim.pack.add(telescope_plugins)

require('telescope').setup {
  defaults = {
    path_display = { 'smart' },
    sorting_strategy = 'ascending',
    layout_config = {
      prompt_position = 'top',
    },
  },
  extensions = {
    ['ui-select'] = { require('telescope.themes').get_dropdown() },
  },
}
pcall(require('telescope').load_extension, 'fzf')
pcall(require('telescope').load_extension, 'ui-select')

local builtin = require 'telescope.builtin'
vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = '[S]earch [C]ommands' })
vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
  callback = function(event)
    local buf = event.buf
    vim.keymap.set('n', 'grr', builtin.lsp_references, { buffer = buf, desc = '[G]oto [R]eferences' })
    vim.keymap.set('n', 'gri', builtin.lsp_implementations, { buffer = buf, desc = '[G]oto [I]mplementation' })
    vim.keymap.set('n', 'grd', builtin.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })
    vim.keymap.set('n', 'gO', builtin.lsp_document_symbols, { buffer = buf, desc = 'Open Document Symbols' })
    vim.keymap.set('n', 'gW', builtin.lsp_dynamic_workspace_symbols, { buffer = buf, desc = 'Open Workspace Symbols' })
    vim.keymap.set('n', 'grt', builtin.lsp_type_definitions, { buffer = buf, desc = '[G]oto [T]ype Definition' })
  end,
})

vim.keymap.set(
  'n',
  '<leader>/',
  function() builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown { winblend = 10, previewer = false }) end,
  { desc = '[/] Fuzzily search in current buffer' }
)

vim.keymap.set(
  'n',
  '<leader>s/',
  function() builtin.live_grep { grep_open_files = true, prompt_title = 'Live Grep in Open Files' } end,
  { desc = '[S]earch [/] in Open Files' }
)

vim.keymap.set('n', '<leader>sn', function() builtin.find_files { cwd = vim.fn.stdpath 'config' } end, { desc = '[S]earch [N]eovim files' })

-- ===== Autocomplete (blink.cmp) =====
vim.pack.add { { src = gh 'saghen/blink.cmp', version = vim.version.range '1.*' } }
require('blink.cmp').setup {
  keymap = { preset = 'default' },
  appearance = { nerd_font_variant = 'mono' },
  completion = { documentation = { auto_show = false, auto_show_delay_ms = 500 } },
  sources = { default = { 'lsp', 'path', 'snippets' } },
  snippets = { preset = 'default' },
  fuzzy = { implementation = 'lua' },
  signature = { enabled = true },
}

-- ===== LSP =====
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc, mode)
      mode = mode or 'n'
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
    map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
    map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client:supports_method('textDocument/documentHighlight', event.buf) then
      local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })
      vim.api.nvim_create_autocmd('LspDetach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
        callback = function(event2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
        end,
      })
    end

    if client and client:supports_method('textDocument/inlayHint', event.buf) then
      map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
    end
  end,
})

---@type table<string, vim.lsp.Config>
local servers = {
  vtsls = {},
  stylua = {},
  lua_ls = {
    on_init = function(client)
      client.server_capabilities.documentFormattingProvider = false -- Disable formatting (formatting is done by stylua)

      if client.workspace_folders then
        local path = client.workspace_folders[1].name
        if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
      end

      client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
        runtime = {
          version = 'LuaJIT',
          path = { 'lua/?.lua', 'lua/?/init.lua' },
        },
        workspace = {
          checkThirdParty = false,
          -- NOTE: this is a lot slower and will cause issues when working on your own configuration.
          --  See https://github.com/neovim/nvim-lspconfig/issues/3189
          library = vim.tbl_extend('force', vim.api.nvim_get_runtime_file('', true), {
            '${3rd}/luv/library',
            '${3rd}/busted/library',
          }),
        },
      })
    end,
    ---@type lspconfig.settings.lua_ls
    settings = {
      Lua = {
        format = { enable = false }, -- Disable formatting (formatting is done by stylua)
      },
    },
  },
}

vim.pack.add {
  gh 'neovim/nvim-lspconfig',
  gh 'mason-org/mason.nvim',
  gh 'WhoIsSethDaniel/mason-tool-installer.nvim',
}
require('mason').setup {}

require('mason-tool-installer').setup {
  ensure_installed = {
    'vtsls',
    'lua-language-server',
    'stylua',
    'eslint_d',
    'markdownlint',
    'prettierd',
  },
}

-- Global LSP capabilities from blink.cmp (auto-merged into all servers)
vim.lsp.config('*', {
  capabilities = require('blink.cmp').get_lsp_capabilities(),
})

for name, server in pairs(servers) do
  vim.lsp.config(name, server)
  vim.lsp.enable(name)
end

-- ===== Lazydev (Lua LSP enhancements) =====
vim.pack.add {
  gh 'folke/lazydev.nvim',
  gh 'Bilal2453/luvit-meta',
}
require('lazydev').setup {
  library = {
    { path = 'luvit-meta/library', words = { 'vim%.uv' } },
  },
}

-- ===== Format =====
vim.pack.add { gh 'stevearc/conform.nvim' }
require('conform').setup {
  notify_on_error = false,
  default_format_opts = { lsp_format = 'fallback' },
  formatters_by_ft = {
    lua = { 'stylua' },
    javascript = { 'prettierd', 'prettier', stop_after_first = true },
    typescript = { 'prettierd', 'prettier', stop_after_first = true },
    javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
    typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
    css = { 'prettierd', 'prettier', stop_after_first = true },
    scss = { 'prettierd', 'prettier', stop_after_first = true },
    html = { 'prettierd', 'prettier', stop_after_first = true },
    json = { 'prettierd', 'prettier', stop_after_first = true },
    markdown = { 'prettierd', 'prettier', stop_after_first = true },
    astro = { 'prettierd', 'prettier', stop_after_first = true },
  },
}
vim.keymap.set({ 'n', 'v' }, '<leader>f', function() require('conform').format { async = true } end, { desc = '[F]ormat buffer' })

-- ===== Lint (eslint_d) =====
vim.pack.add { gh 'mfussenegger/nvim-lint' }
local lint = require 'lint'
lint.linters_by_ft = {
  markdown = { 'markdownlint' },
  javascript = { 'eslint_d' },
  typescript = { 'eslint_d' },
  javascriptreact = { 'eslint_d' },
  typescriptreact = { 'eslint_d' },
}
lint.linters.eslint_d = require('lint.util').wrap(lint.linters.eslint_d, function(diag)
  if diag.message:find 'Error: Could not find config file' then return nil end
  return diag
end)
local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
  group = lint_augroup,
  callback = function()
    if vim.bo.modifiable then lint.try_lint() end
  end,
})

-- ===== Gitsigns =====
vim.pack.add { gh 'lewis6991/gitsigns.nvim' }
require('gitsigns').setup {
  signs = {
    add = { text = '+' },
    change = { text = '~' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
  },
  on_attach = function(bufnr)
    local gitsigns = require 'gitsigns'
    local function map(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end

    map('n', ']c', function()
      if vim.wo.diff then
        vim.cmd.normal { ']c', bang = true }
      else
        gitsigns.nav_hunk 'next'
      end
    end, { desc = 'Jump to next git [c]hange' })
    map('n', '[c', function()
      if vim.wo.diff then
        vim.cmd.normal { '[c', bang = true }
      else
        gitsigns.nav_hunk 'prev'
      end
    end, { desc = 'Jump to previous git [c]hange' })

    map('v', '<leader>hs', function() gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'git [s]tage hunk' })
    map('v', '<leader>hr', function() gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'git [r]eset hunk' })
    map('n', '<leader>hs', gitsigns.stage_hunk, { desc = 'git [s]tage hunk' })
    map('n', '<leader>hr', gitsigns.reset_hunk, { desc = 'git [r]eset hunk' })
    map('n', '<leader>hS', gitsigns.stage_buffer, { desc = 'git [S]tage buffer' })
    map('n', '<leader>hR', gitsigns.reset_buffer, { desc = 'git [R]eset buffer' })
    map('n', '<leader>hp', gitsigns.preview_hunk, { desc = 'git [p]review hunk' })
    map('n', '<leader>hi', gitsigns.preview_hunk_inline, { desc = 'git preview hunk [i]nline' })
    map('n', '<leader>hb', function() gitsigns.blame_line { full = true } end, { desc = 'git [b]lame line' })
    map('n', '<leader>hd', gitsigns.diffthis, { desc = 'git [d]iff against index' })
    map('n', '<leader>hD', function() gitsigns.diffthis '@' end, { desc = 'git [D]iff against last commit' })
    map('n', '<leader>hQ', function() gitsigns.setqflist 'all' end, { desc = 'git hunk [Q]uickfix list' })
    map('n', '<leader>hq', gitsigns.setqflist, { desc = 'git hunk [q]uickfix list' })
    map('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = '[T]oggle git show [b]lame line' })
    map('n', '<leader>tw', gitsigns.toggle_word_diff, { desc = '[T]oggle git intra-line [w]ord diff' })
    map({ 'o', 'x' }, 'ih', gitsigns.select_hunk)
  end,
}

-- ===== Lazygit =====
vim.pack.add { gh 'kdheepak/lazygit.nvim' }
vim.keymap.set('n', '<leader>lg', '<cmd>LazyGit<cr>', { desc = 'LazyGit' })

-- ===== Neo-tree (file browser) =====
vim.pack.add {
  gh 'nvim-neo-tree/neo-tree.nvim',
  gh 'MunifTanjim/nui.nvim',
}
require('neo-tree').setup {
  filesystem = {
    window = {
      mappings = {
        ['\\'] = 'close_window',
      },
    },
  },
}
vim.keymap.set('n', '\\', '<cmd>Neotree reveal<CR>', { desc = 'Toggle file browser' })

-- ===== Colorizer =====
vim.pack.add { gh 'NvChad/nvim-colorizer.lua' }
require('colorizer').setup {
  user_default_options = {
    tailwind = true,
  },
}

-- ===== Tmux navigator =====
vim.pack.add { gh 'christoomey/vim-tmux-navigator' }

-- ===== OpenCode AI =====
vim.pack.add {
  { src = gh 'nickjvandyke/opencode.nvim', version = vim.version.range '*' },
  gh 'folke/snacks.nvim',
}

vim.g.opencode_opts = {
  server = {
    start = false, -- You manage opencode in your tmux window
  },
}

-- snacks.nvim integration: enhances ask() and select()
require('snacks').setup {
  input = { enabled = true },
  picker = {
    enabled = true,
    actions = {
      ---@param picker snacks.Picker
      opencode_send = function(picker)
        local items = vim.tbl_map(function(item) ---@param item snacks.picker.Item
          return item.file
            and require('opencode').format { path = item.file, from = item.pos, to = item.end_pos }
            or item.text
        end, picker:selected { fallback = true })
        require('opencode').prompt(table.concat(items, ', ') .. ' ')
      end,
    },
    win = {
      input = {
        keys = {
          ['<M-a>'] = { 'opencode_send', mode = { 'n', 'i' } },
        },
      },
    },
  },
}

vim.keymap.set({ 'n', 'x' }, '<leader>oa', function() require('opencode').ask('@this: ') end, { desc = 'Ask opencode…' })
vim.keymap.set({ 'n', 'x' }, '<leader>os', function() require('opencode').select() end, { desc = 'Select opencode…' })

vim.keymap.set({ 'n', 'x' }, 'go', function() return require('opencode').operator('@this ') end, { desc = 'Add range to opencode', expr = true })
vim.keymap.set('n', 'goo', function() return require('opencode').operator('@this ') .. '_' end, { desc = 'Add line to opencode', expr = true })

vim.keymap.set('n', '<S-C-u>', function() require('opencode').command('session.half.page.up') end, { desc = 'Scroll opencode up' })
vim.keymap.set('n', '<S-C-d>', function() require('opencode').command('session.half.page.down') end, { desc = 'Scroll opencode down' })
