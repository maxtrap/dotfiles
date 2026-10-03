-- ┌─────────────────────────┐
-- │ Plugins outside of MINI │
-- └─────────────────────────┘
--
-- This file contains installation and configuration of plugins outside of MINI.
-- They significantly improve user experience in a way not yet possible with MINI.
-- These are mostly plugins that provide programming language specific behavior.
--
-- Use this file to install and configure other such plugins.

-- Make concise helpers for installing/adding plugins in two stages
local add, later, now = MiniDeps.add, MiniDeps.later, MiniDeps.now
local now_if_args = _G.Config.now_if_args

-- Tree-sitter ================================================================

-- Tree-sitter is a tool for fast incremental parsing. It converts text into
-- a hierarchical structure (called tree) that can be used to implement advanced
-- and/or more precise actions: syntax highlighting, textobjects, indent, etc.
--
-- Tree-sitter support is built into Neovim (see `:h treesitter`). However, it
-- requires two extra pieces that don't come with Neovim directly:
-- - Language parsers: programs that convert text into trees. Some are built-in
--   (like for Lua), 'nvim-treesitter' provides many others.
--   NOTE: It requires third party software to build and install parsers.
--   See the link for more info in "Requirements" section of the MiniMax README.
-- - Query files: definitions of how to extract information from trees in
--   a useful manner (see `:h treesitter-query`). 'nvim-treesitter' also provides
--   these, while 'nvim-treesitter-textobjects' provides the ones for Neovim
--   textobjects (see `:h text-objects`, `:h MiniAi.gen_spec.treesitter()`).
--
-- Add these plugins now if file (and not 'mini.starter') is shown after startup.
--
-- Troubleshooting:
-- - Run `:checkhealth vim.treesitter nvim-treesitter` to see potential issues.
-- - In case of errors related to queries for Neovim bundled parsers (like `lua`,
--   `vimdoc`, `markdown`, etc.), manually install them via 'nvim-treesitter'
--   with `:TSInstall <language>`. Be sure to have necessary system dependencies
--   (see MiniMax README section for software requirements).
now_if_args(function()
	add({
		source = "nvim-treesitter/nvim-treesitter",
		-- Update tree-sitter parser after plugin is updated
		hooks = {
			post_checkout = function()
				vim.cmd("TSUpdate")
			end,
		},
	})
	add({
		source = "nvim-treesitter/nvim-treesitter-textobjects",
		-- Use `main` branch since `master` branch is frozen, yet still default
		-- It is needed for compatibility with 'nvim-treesitter' `main` branch
		checkout = "main",
	})

	-- Define languages which will have parsers installed and auto enabled
	-- After changing this, restart Neovim once to install necessary parsers. Wait
	-- for the installation to finish before opening a file for added language(s).
	local languages = {
		"bash",
		"css",
		"html",
		"http",
		"javascript",
		"jsx",
		"latex",
		"lua",
		"markdown",
		"markdown_inline",
		"r",
		"typst",
		"vimdoc",
		"python",
		"yaml",
		-- Add here more languages with which you want to use tree-sitter
		-- To see available languages:
		-- - Execute `:=require('nvim-treesitter').get_available()`
		-- - Visit 'SUPPORTED_LANGUAGES.md' file at
		--   https://github.com/nvim-treesitter/nvim-treesitter/blob/main
	}
	local isnt_installed = function(lang)
		return #vim.api.nvim_get_runtime_file("parser/" .. lang .. ".*", false) == 0
	end
	local to_install = vim.tbl_filter(isnt_installed, languages)
	if #to_install > 0 then
		require("nvim-treesitter").install(to_install)
	end

	-- Enable tree-sitter after opening a file for a target language
	local filetypes = {}
	for _, lang in ipairs(languages) do
		for _, ft in ipairs(vim.treesitter.language.get_filetypes(lang)) do
			table.insert(filetypes, ft)
		end
	end
	local ts_start = function(ev)
		vim.treesitter.start(ev.buf)
	end
	_G.Config.new_autocmd("FileType", filetypes, ts_start, "Start tree-sitter")
end)

-- Language servers ===========================================================

-- Language Server Protocol (LSP) is a set of conventions that power creation of
-- language specific tools. It requires two parts:
-- - Server - program that performs language specific computations.
-- - Client - program that asks server for computations and shows results.
--
-- Here Neovim itself is a client (see `:h vim.lsp`). Language servers need to
-- be installed separately based on your OS, CLI tools, and preferences.
-- See note about 'mason.nvim' at the bottom of the file.
--
-- Neovim's team collects commonly used configurations for most language servers
-- inside 'neovim/nvim-lspconfig' plugin.
--
-- Add it now if file (and not 'mini.starter') is shown after startup.
now_if_args(function()
	add("neovim/nvim-lspconfig")

	-- Use `:h vim.lsp.enable()` to automatically enable language server based on
	-- the rules provided by 'nvim-lspconfig'.
	-- Use `:h vim.lsp.config()` or 'after/lsp/' directory to configure servers.
	-- Uncomment and tweak the following `vim.lsp.enable()` call to enable servers.
	-- vim.lsp.enable({
	--   -- For example, if `lua-language-server` is installed, use `'lua_ls'` entry
	-- })
end)

-- Formatting =================================================================

-- Programs dedicated to text formatting (a.k.a. formatters) are very useful.
-- Neovim has built-in tools for text formatting (see `:h gq` and `:h 'formatprg'`).
-- They can be used to configure external programs, but it might become tedious.
--
-- The 'stevearc/conform.nvim' plugin is a good and maintained solution for easier
-- formatting setup.
later(function()
	add("stevearc/conform.nvim")

	-- See also:
	-- - `:h Conform`
	-- - `:h conform-options`
	-- - `:h conform-formatters`
	require("conform").setup({
		log_level = vim.log.levels.DEBUG,
		default_format_opts = {
			-- Allow formatting from LSP server if no dedicated formatter is available
			lsp_format = "fallback",
		},
		-- Map of filetype to formatters
		-- Make sure that necessary CLI tool is available
		formatters_by_ft = {
			lua = { "stylua" },
			javascript = { "biome" },
			typescript = { "biome" },
			javascriptreact = { "biome" },
			typescriptreact = { "biome" },
			css = { "biome" },
			html = { "biome" },
			json = { "biome" },
			yaml = { "biome" },
			markdown = { "biome" },
			graphql = { "biome" },
			python = { "black" },
		},
		format_on_save = {
			lsp_fallback = true,
			async = false,
			timeout_ms = 500,
		},
	})
end)

-- Snippets ===================================================================

-- Although 'mini.snippets' provides functionality to manage snippet files, it
-- deliberately doesn't come with those.
--
-- The 'rafamadriz/friendly-snippets' is currently the largest collection of
-- snippet files. They are organized in 'snippets/' directory (mostly) per language.
-- 'mini.snippets' is designed to work with it as seamlessly as possible.
-- See `:h MiniSnippets.gen_loader.from_lang()`.
later(function()
	add("rafamadriz/friendly-snippets")
end)

-- Honorable mentions =========================================================

-- 'mason-org/mason.nvim' (a.k.a. "Mason") is a great tool (package manager) for
-- installing external language servers, formatters, and linters. It provides
-- a unified interface for installing, updating, and deleting such programs.
--
-- The caveat is that these programs will be set up to be mostly used inside Neovim.
-- If you need them to work elsewhere, consider using other package managers.
--
-- You can use it like so:
now_if_args(function()
	add("mason-org/mason.nvim")
	require("mason").setup()

	add({
		source = "mason-org/mason-lspconfig.nvim",
		depends = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
	})
	require("mason-lspconfig").setup({
		ensure_installed = {
			"clangd",
			"html",
			"lua_ls",
			"pyright",
			"texlab",
			"ts_ls",
			"tinymist",
			"yamlls",
		},
	})
end)

-- Beautiful, usable, well maintained color schemes outside of 'mini.nvim' and
-- have full support of its highlight groups. Use if you don't like 'miniwinter'
-- enabled in 'plugin/30_mini.lua' or other suggested 'mini.hues' based ones.
MiniDeps.now(function()
	--   -- Install only those that you need
	add("polirritmico/monokai-nightasty.nvim")
	-- require('monokai').setup {}

	add("navarasu/onedark.nvim")
	require("onedark").setup({
		style = "darker", -- Choose between 'dark', 'darker', 'cool', 'deep', 'warm', 'warmer'
	})
	--   add('sainnhe/everforest')
	--   add('Shatur/neovim-ayu')
	--   add('ellisonleao/gruvbox.nvim')
	--
	-- Enable only one
	vim.cmd("color monokai-nightasty")
end)

-- Custom Plugins =========================================================

later(function()
	add("mfussenegger/nvim-lint")
	require("lint").linters_by_ft = {
		javascript = { "eslint_d" },
		typescript = { "eslint_d" },
		javascriptreact = { "eslint_d" },
		typescriptreact = { "eslint_d" },
		python = { "pylint" },
	}

	local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

	vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
		group = lint_augroup,
		callback = function()
			require("lint").try_lint()
		end,
	})
end)

later(function()
	add({
		source = "sphamba/smear-cursor.nvim",
	})
	require("smear_cursor").setup({
		smear_between_buffers = true,
	})
end)

later(function()
	add({
		source = "mbbill/undotree",
	})
end)

later(function()
	add({
		source = "christoomey/vim-tmux-navigator",
	})
end)

later(function()
	add({
		source = "folke/snacks.nvim",
	})
	--   require('snacks').setup {
	--       image = { enabled = true }
	--   }
end)

-- add({
-- 	source = "yetone/avante.nvim",
-- 	monitor = "main",
-- 	depends = {
-- 		"nvim-lua/plenary.nvim",
-- 		"MunifTanjim/nui.nvim",
-- 		"echasnovski/mini.icons",
-- 	},
-- 	hooks = {
-- 		post_checkout = function()
-- 			vim.cmd("make")
-- 		end,
-- 	},
-- })
-- require("avante").setup({})
-- -- add({ source = 'hrsh7th/nvim-cmp' })
-- add({ source = "zbirenbaum/copilot.lua" })
-- require("copilot").setup({})
-- add({ source = "HakonHarnes/img-clip.nvim" })
--
-- later(function()
-- 	add({
-- 		source = "meanderingprogrammer/render-markdown.nvim",
-- 		depends = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.nvim" },
-- 	})
-- 	require("render-markdown").setup({})
-- end)

-- MiniDeps.now(function()
--
--     add({
--         source = "OXY2DEV/markview.nvim",
--
--         -- Completion for `blink.cmp`
--         -- depends = { "saghen/blink.cmp" },
--     });
-- end)

later(function()
	add({
		source = "lukas-reineke/indent-blankline.nvim",
	})
	require("ibl").setup()
end)

MiniDeps.now(function()
	vim.g.vimtex_view_method = "zathura"
	add("lervag/vimtex")
end)

later(function()
	add("windwp/nvim-ts-autotag")
	require("nvim-ts-autotag").setup()
end)
later(function()
	add("lewis6991/gitsigns.nvim")
	require("gitsigns").setup({
		current_line_blame = true,
	})
end)

-- later(function()
-- 	add({
-- 		source = "rest-nvim/rest.nvim",
-- 		dependes = { "nvim-treesitter/nvim-treesitter" },
-- 	})
-- end)

later(function()
	add("chomosuke/typst-preview.nvim")
	require("typst-preview").setup()
end)

later(function()
	add("kdheepak/lazygit.nvim")
end)

later(function()
	add("coder/claudecode.nvim")
	require("claudecode").setup()
end)

later(function()
	add({
		source = "nosduco/remote-sshfs.nvim",
		depends = { "folke/snacks.nvim" },
	})
	require("remote-sshfs").setup()
end)

-- later(function()
-- 	add("nvzone/volt")
--
-- 	add({
-- 		source = "nvzone/timerly",
-- 		depends = { "nvzone/volt" },
-- 	})
-- end)

later(function()
	add("hat0uma/csvview.nvim")
	require("csvview").setup({ view = { display_mode = "border" } })
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "csv",
		callback = function()
			require("csvview").enable()
		end,
	})
end)
