-- Some utility stuff
require 'utils'

-- plugin installation
require 'plugins'

require 'config/lsp'

require 'config/telescope'

require 'config/nvim-web-devicons'

vim.cmd [[autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()]]


