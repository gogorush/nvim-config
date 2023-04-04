-- Some utility stuff
require 'utils'

-- plugin installation
require 'plugins'

require 'config/lsp'

require 'config/telescope'

require 'config/nvim-web-devicons'

require('Comment').setup()

require 'config/lightspeed'

require("mason").setup()
require("mason-lspconfig").setup()
require('lspconfig.ui.windows').default_options.border = 'single'
