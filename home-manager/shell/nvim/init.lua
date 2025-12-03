vim.opt.number = true
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2

-- lualine
require('lualine').setup()

-- accelerated-jk
require('accelerated-jk').setup()
vim.api.nvim_set_keymap('n', 'J', '<Plug>(accelerated_jk_gj)', {})
vim.api.nvim_set_keymap('n', 'K', '<Plug>(accelerated_jk_gk)', {})

-- nvim-autopairs
require('nvim-autopairs').setup {}

-- diagnostics
vim.diagnostic.config({ virtual_text = false })
require('tiny-inline-diagnostic').setup()

-- treesitter
require('nvim-treesitter.configs').setup {
  indent = {
    enable = true,
  },
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
}

-- hlchunk
require('hlchunk').setup({
  chunk = {
    enable = true
  },
  indent = {
    enable = true
  },
  line_num = {
    enable = true
  },
})

-- hellshake-yano
vim.g.hellshake_yano = {
  useJapanese = true,
  useHintGroups = true,
  highlightSelected = true,
  useNumericMultiCharHints = true,
  enableTinySegmenter = true,
  singleCharKeys = "ASDFGNM@;,.",
  multiCharKeys = "BCEIOPQRTUVWXYZ",
  highlightHintMarker = {bg = "yellow", fg = "Blue"},
  highlightHintMarkerCurrent = {bg = "Red", fg = "White"},
  perKeyMinLength = {
    w = 3,
    b = 3,
    e = 3,
  },
  defaultMinWordLength = 3,
  perKeyMotionCount = {
    w = 1,
    b = 1,
    e = 1,
    h = 2,
    j = 2,
    k = 2,
    l = 2,
  },
  motionCount = 3,
  japaneseMinWordLength = 3,
  segmenterThreshold = 4,
  japaneseMergeThreshold = 4,
}

-- LSP settings
require("mason").setup()

local lspconfig = require('lspconfig')

-- Set up nvim-cmp for autocompletion
local cmp = require('cmp')
local luasnip = require('luasnip')

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  }, {
      { name = 'buffer' },
      { name = 'path' },
    })
})

-- Set up cmdline completion
cmp.setup.cmdline('/', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = 'buffer' }
  }
})

cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = 'path' }
  }, {
      { name = 'cmdline' }
    })
})

-- Set up capabilities with cmp_nvim_lsp
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- Telescope setup
-- require('telescope').setup{}

-- Keymaps and other settings for on_attach
local on_attach = function(client, bufnr)
  local bufopts = { noremap=true, silent=true, buffer=bufnr }
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', '<C-h>', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, bufopts)
  vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', 'gr', '<cmd>Telescope lsp_references<cr>', bufopts)
  vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, bufopts)
  vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, bufopts)
  vim.keymap.set('n', ']d', vim.diagnostic.goto_next, bufopts)
  vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, bufopts)
end

require("mason-lspconfig").setup({

  --   "nil_ls",
  --   "lua_ls",
  --   "clangd",
  --   "gopls",
  --   "denols", -- for deno
  -- },
  handlers = {
    -- Default handler for servers
    function (server_name)
      lspconfig[server_name].setup {
        on_attach = on_attach,
        capabilities = capabilities,
      }
    end,

    -- rust-analyzer: enable on-the-fly checks
    ["rust_analyzer"] = function ()
      lspconfig.rust_analyzer.setup {
        on_attach = on_attach,
        capabilities = capabilities,
        settings = {
          ["rust-analyzer"] = {
            check = {
              onFly = true,
            },
          },
        },
      }
    end,

    -- Special handler for lua_ls to recognize 'vim' global
    ["lua_ls"] = function ()
      lspconfig.lua_ls.setup {
        on_attach = on_attach,
        capabilities = capabilities,
        settings = {
          Lua = {
            diagnostics = {
              globals = {'vim'},
            },
          },
        },
      }
    end,
  }
})
