local api = vim.api
local lsp = vim.lsp

local utils = require("utils")

vim.cmd [[autocmd! ColorScheme * highlight NormalFloat guibg=#1f2335]]
vim.cmd [[autocmd! ColorScheme * highlight FloatBorder guifg=white guibg=#1f2335]]

local border = {
  { "🭽", "FloatBorder" },
  { "▔", "FloatBorder" },
  { "🭾", "FloatBorder" },
  { "▕", "FloatBorder" },
  { "🭿", "FloatBorder" },
  { "▁", "FloatBorder" },
  { "🭼", "FloatBorder" },
  { "▏", "FloatBorder" },
}

-- LSP settings (for overriding per client)
local handlers = {
}

local custom_attach = function(client, bufnr)
  -- Mappings.
  local opts = { silent = true, buffer = bufnr }
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
  vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
  vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
  vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
  vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
  vim.keymap.set("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts)
  vim.keymap.set("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts)
  vim.keymap.set("n", "<leader>wl", function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end, opts)
  vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
  vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
  vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
  vim.keymap.set("n", "<space>q", function() vim.diagnostic.setqflist({ open = true }) end, opts)
  vim.keymap.set("n", "<space>ca", vim.lsp.buf.code_action, opts)

  vim.api.nvim_create_autocmd("CursorHold", {
    buffer = bufnr,
    callback = function()
      local opts = {
        focusable = false,
        close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
        border = 'rounded',
        source = 'always', -- show source in diagnostic popup window
        prefix = ' '
      }
      vim.diagnostic.open_float(nil, opts)
    end
  })

  -- Set some key bindings conditional on server capabilities
  if client.server_capabilities.documentFormattingProvider then
    vim.keymap.set("n", "<space>f", vim.lsp.buf.format, opts)
  end
  if client.server_capabilities.documentRangeFormattingProvider then
    vim.keymap.set("x", "<space>f", vim.lsp.buf.range_formatting, opts)
  end

  -- The blow command will highlight the current variable and its usages in the buffer.
  if client.server_capabilities.documentHighlightProvider then
    vim.cmd([[
      hi! link LspReferenceRead Visual
      hi! link LspReferenceText Visual
      hi! link LspReferenceWrite Visual
      augroup lsp_document_highlight
        autocmd! * <buffer>
        autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
        autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
      augroup END
    ]])
  end

  if vim.g.logging_level == 'debug' then
    local msg = string.format("Language server %s started!", client.name)
    vim.notify(msg, 'info', { title = 'Nvim-config' })
  end
end

local capabilities = lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)
capabilities.textDocument.completion.completionItem.snippetSupport = true

local lspconfig = require("lspconfig")
util = require "lspconfig/util"

local on_attach = function(client)
  -- Highlight symbol under cursor
  if client.server_capabilities.documentHighlightProvider then
    vim.cmd [[
        hi! LspReferenceRead cterm=bold ctermbg=red guibg=LightYellow
        hi! LspReferenceText cterm=bold ctermbg=red guibg=LightYellow
        hi! LspReferenceWrite cterm=bold ctermbg=red guibg=LightYellow
        augroup lsp_document_highlight
          autocmd! * <buffer>
          autocmd! CursorHold <buffer> lua vim.lsp.buf.document_highlight()
          autocmd! CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()
          autocmd! CursorMoved <buffer> lua vim.lsp.buf.clear_references()
        augroup END
      ]]
  end
end

lspconfig.solidity.setup({
  default_config = {
    cmd = {'nomicfoundation-solidity-language-server', '--stdio'},
    filetypes = { 'solidity' },
    root_dir = lspconfig.util.find_git_ancestor,
    single_file_support = true,
  },
})


lspconfig.rust_analyzer.setup({
  on_attach = custom_attach,
  capabilities = capabilities,
  filetypes = { 'rust' },
  cmd = { 'rust-analyzer' },
  settings = {
    ["rust-analyzer"] = {
      checkOnSave = {
        command = "clippy"
      }
    }
  },
})


--gopls setting
if utils.executable('gopls') then
  lspconfig.gopls.setup({
    on_attach = custom_attach,
    capabilities = capabilities,
    cmd = { "gopls", "serve" },
    filetypes = { "go", "gomod" },
    root_dir = util.root_pattern("go.work", "go.mod", ".git"),
    settings = {
      gopls = {
        analyses = {
          unusedparams = true,
        },
        staticcheck = true,
      },
    },
  })
else
  vim.notify("gopls not found!", 'warn', { title = 'Nvim-config' })
end

lspconfig.pylsp.setup({
  on_attach = custom_attach,
  settings = {
    pylsp = {
      plugins = {
        pylint = { enabled = true, executable = "pylint" },
        pyflakes = { enabled = false },
        pycodestyle = { enabled = false },
        jedi_completion = { fuzzy = true },
        pyls_isort = { enabled = true },
        pylsp_mypy = { enabled = true },
      },
    },
  },
  flags = {
    debounce_text_changes = 200,
  },
  capabilities = capabilities,
})

lspconfig.yamlls.setup({
  on_attach = custom_attach,
  capabilities = capabilities,
  settings = {
    yaml = {
      schemas = {
                ["https://raw.githubusercontent.com/quantumblacklabs/kedro/develop/static/jsonschema/kedro-catalog-0.17.json"]= "conf/**/*catalog*",
                ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*"
            },
      keyOrdering = false
    },
  },
  filetypes = {"yaml", "yml"}
})

lspconfig.tsserver.setup({
  on_attach = custom_attach,
  capabilities = capabilities,
  filetypes = {"javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx"}
})

-- if utils.executable('pyright') then
--   lspconfig.pyright.setup{
--     on_attach = custom_attach,
--     capabilities = capabilities
--   }
-- else
--   vim.notify("pyright not found!", 'warn', {title = 'Nvim-config'})
-- end

if utils.executable('clangd') then
  lspconfig.clangd.setup({
    on_attach = custom_attach,
    capabilities = capabilities,
    filetypes = { "c", "cpp", "cc" },
    flags = {
      debounce_text_changes = 500,
    },
  })
else
  vim.notify("clangd not found!", 'warn', { title = 'Nvim-config' })
end

-- set up vim-language-server
if utils.executable('vim-language-server') then
  lspconfig.vimls.setup({
    on_attach = custom_attach,
    flags = {
      debounce_text_changes = 500,
    },
    capabilities = capabilities,
  })
else
  vim.notify("vim-language-server not found!", 'warn', { title = 'Nvim-config' })
end

-- set up bash-language-server
if utils.executable('bash-language-server') then
  lspconfig.bashls.setup({
    on_attach = custom_attach,
    capabilities = capabilities,
  })
end


local lsp_flags = {
  debounce_text_changes = 100,
}
lspconfig.lua_ls.setup({
   on_attach = on_attach,
  flags = lsp_flags,
  capabilities = capabilities,
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
      },
      diagnostics = {
        globals = {"vim", "packer_bootstrap"},
      },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
      },
      telemetry = {
        enable = false,
      },
    },
  },
})


--[[local sumneko_binary_path = vim.fn.exepath("lua-language-server")]]
--[[if vim.g.is_mac or vim.g.is_linux and sumneko_binary_path ~= "" then]]
--[[local sumneko_root_path = vim.fn.fnamemodify(sumneko_binary_path, ":h:h:h")]]

--[[local runtime_path = vim.split(package.path, ";")]]
--[[table.insert(runtime_path, "lua/?.lua")]]
--[[table.insert(runtime_path, "lua/?/init.lua")]]

--[[lsumneko_luasumneko_luaspconfig.sumneko_lua.setup({]]
--[[on_attach = custom_attach,]]
--[[cmd = { sumneko_binary_path, "-E", sumneko_root_path .. "/main.lua" },]]
--[[settings = {]]
--[[Lua = {]]
--[[runtime = {]]
--[[-- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)]]
--[[version = "LuaJIT",]]
--[[-- Setup your lua path]]
--[[path = runtime_path,]]
--[[},]]
--[[diagnostics = {]]
--[[-- Get the language server to recognize the `vim` global]]
--[[globals = { "vim" },]]
--[[},]]
--[[workspace = {]]
--[[-- Make the server aware of Neovim runtime files]]
--[[library = api.nvim_get_runtime_file("", true),]]
--[[},]]
--[[-- Do not send telemetry data containing a randomized but unique identifier]]
--[[telemetry = {]]
--[[enable = false,]]
--[[},]]
--[[},]]
--[[},]]
--[[capabilities = capabilities,]]
--[[})]]
--[[end]]

-- Change diagnostic signs.
vim.fn.sign_define("DiagnosticSignError", { text = "✗", texthl = "DiagnosticSignError" })
vim.fn.sign_define("DiagnosticSignWarn", { text = "!", texthl = "DiagnosticSignWarn" })
vim.fn.sign_define("DiagnosticSignInformation", { text = "", texthl = "DiagnosticSignInfo" })
vim.fn.sign_define("DiagnosticSignHint", { text = "", texthl = "DiagnosticSignHint" })

-- global config for diagnostic
vim.diagnostic.config({
  underline = false,
  virtual_text = false,
  signs = true,
  severity_sort = true,
})

-- lsp.handlers["textDocument/publishDiagnostics"] = lsp.with(lsp.diagnostic.on_publish_diagnostics, {
--   underline = false,
--   virtual_text = false,
--   signs = true,
--   update_in_insert = false,
-- })

-- Change border of documentation hover window, See https://github.com/neovim/neovim/pull/13998.
lsp.handlers["textDocument/hover"] = lsp.with(vim.lsp.handlers.hover, {
  --border = "rounded",
  ["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = border }),
  ["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = border }),

})

-- Go-to definition in a split window
local function goto_definition(split_cmd)
  local util = vim.lsp.util
  local log = require("vim.lsp.log")
  local api = vim.api

  -- note, this handler style is for neovim 0.5.1/0.6, if on 0.5, call with function(_, method, result)
  local handler = function(_, result, ctx)
    if result == nil or vim.tbl_isempty(result) then
      local _ = log.info() and log.info(ctx.method, "No location found")
      return nil
    end

    if split_cmd then
      vim.cmd(split_cmd)
    end

    if vim.tbl_islist(result) then
      util.jump_to_location(result[1])

      if #result > 1 then
        util.set_qflist(util.locations_to_items(result))
        api.nvim_command("copen")
        api.nvim_command("wincmd p")
      end
    else
      util.jump_to_location(result)
    end
  end

  return handler
end

vim.lsp.handlers["textDocument/definition"] = goto_definition('vsplit')
