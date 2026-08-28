vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.number = true
vim.opt.mouse = "a"
local clipboard_commands = { "pbcopy", "wl-copy", "xclip", "xsel" }
for _, command in ipairs(clipboard_commands) do
	if vim.fn.executable(command) == 1 then
		vim.opt.clipboard = "unnamedplus"
		break
	end
end
vim.opt.termguicolors = true
vim.opt.laststatus = 3
vim.opt.showmode = false

-- Leave terminal input mode with Escape twice and move between windows.
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Leave terminal mode" })
vim.keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>h", { desc = "Move to the left window" })
vim.keymap.set("t", "<C-j>", "<C-\\><C-n><C-w>j", { desc = "Move to the lower window" })
vim.keymap.set("t", "<C-k>", "<C-\\><C-n><C-w>k", { desc = "Move to the upper window" })
vim.keymap.set("t", "<C-l>", "<C-\\><C-n><C-w>l", { desc = "Move to the right window" })

-- Bootstrap lazy.nvim and let it manage all plugins.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local output = vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"--branch=stable",
		lazyrepo,
		lazypath,
	})
	if vim.v.shell_error ~= 0 then
		error("Failed to clone lazy.nvim:\n" .. output)
	end
end
vim.opt.rtp:prepend(lazypath)

local treesitter_parsers = {
	"bash",
	"c",
	"cmake",
	"cpp",
	"json",
	"lua",
	"markdown",
	"markdown_inline",
	"python",
	"regex",
	"vim",
	"vimdoc",
	"yaml",
}

local treesitter_filetypes = {
	"bash",
	"c",
	"cmake",
	"cpp",
	"help",
	"json",
	"jsonc",
	"lua",
	"markdown",
	"python",
	"sh",
	"vim",
	"yaml",
}

local snacks_filetypes = {
	"snacks_layout_box",
	"snacks_picker_input",
	"snacks_picker_list",
	"snacks_terminal",
}

local function snacks_status_name()
	if vim.bo.filetype == "snacks_terminal" then
		return "Terminal"
	end
	for _, picker in ipairs(Snacks.picker.get()) do
		if picker:is_focused() then
			return picker.opts.source == "explorer" and "File Explorer" or "Picker"
		end
	end
	return "Picker"
end

local snacks_lualine_extension = {
	sections = {
		lualine_a = { snacks_status_name },
		lualine_b = {},
		lualine_c = {},
		lualine_x = {},
		lualine_y = {},
		lualine_z = {},
	},
	inactive_sections = {
		lualine_a = {},
		lualine_b = {},
		lualine_c = { snacks_status_name },
		lualine_x = {},
		lualine_y = {},
		lualine_z = {},
	},
	filetypes = snacks_filetypes,
}

require("lazy").setup({
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1100,
		lazy = false,
		opts = {
			flavour = "mocha",
			auto_integrations = true,
			integrations = {
				blink_cmp = { style = "bordered" },
				mason = true,
				snacks = true,
			},
		},
		config = function(_, opts)
			require("catppuccin").setup(opts)
			vim.cmd.colorscheme("catppuccin-nvim")
		end,
	},
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		opts = {
			explorer = {
				enabled = true,
				replace_netrw = true,
			},
			picker = {
				enabled = true,
				ui_select = true,
				sources = {
					explorer = {
						follow_file = true,
						watch = false,
						layout = {
							preset = "sidebar",
							preview = false,
							layout = { width = 30 },
						},
					},
				},
			},
			terminal = {
				enabled = true,
				win = {
					position = "bottom",
					height = 12,
				},
			},
		},
		keys = {
			{ "<leader><space>", function() Snacks.picker.smart() end, desc = "Smart find files" },
			{ "<leader>ff", function() Snacks.picker.files() end, desc = "Find files" },
			{ "<leader>fg", function() Snacks.picker.git_files() end, desc = "Find Git files" },
			{ "<leader>/", function() Snacks.picker.grep() end, desc = "Grep" },
			{ "<leader>,", function() Snacks.picker.buffers() end, desc = "Find buffers" },
			{ "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent files" },
			{ "<leader>e", function() Snacks.explorer.reveal() end, desc = "File explorer" },
			{
				"<C-\\>",
				function() Snacks.terminal.toggle() end,
				mode = { "n", "t" },
				desc = "Toggle terminal",
			},
		},
	},
	{
		"nvim-lualine/lualine.nvim",
		lazy = false,
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			options = {
				theme = "catppuccin-nvim",
				icons_enabled = true,
				globalstatus = true,
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = { "branch", "diff" },
				lualine_c = { { "filename", path = 0 } },
				lualine_x = { "diagnostics", "filetype" },
				lualine_y = { "encoding", "fileformat" },
				lualine_z = { "location" },
			},
			extensions = { snacks_lualine_extension, "mason", "lazy" },
		},
	},
	{
		"akinsho/bufferline.nvim",
		version = "*",
		lazy = false,
		dependencies = {
			"catppuccin/nvim",
			"nvim-tree/nvim-web-devicons",
		},
		opts = function()
			return {
				highlights = require("catppuccin.special.bufferline").get_theme(),
				options = {
					mode = "buffers",
					diagnostics = "nvim_lsp",
					separator_style = "slant",
					offsets = {
						{
							filetype = "snacks_layout_box",
							text = "File Explorer",
							text_align = "center",
							separator = true,
						},
					},
				},
			}
		end,
		keys = {
			{ "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Previous buffer" },
			{ "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
			{ "<leader>bd", "<cmd>bdelete<cr>", desc = "Delete buffer" },
		},
	},
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			current_line_blame = true,
			current_line_blame_opts = {
				virt_text = true,
				virt_text_pos = "eol",
				delay = 500,
				ignore_whitespace = false,
				use_focus = true,
			},
			current_line_blame_formatter = "  <author>, <author_time:%R> - <summary>",
		},
		keys = {
			{ "<leader>gb", "<cmd>Gitsigns toggle_current_line_blame<cr>", desc = "Toggle Git blame" },
			{ "<leader>gB", "<cmd>Gitsigns blame<cr>", desc = "Git blame buffer" },
		},
	},
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter").install(treesitter_parsers)

			local group = vim.api.nvim_create_augroup("treesitter_highlight", { clear = true })
			vim.api.nvim_create_autocmd("FileType", {
				group = group,
				pattern = treesitter_filetypes,
				callback = function(args)
					pcall(vim.treesitter.start, args.buf)
				end,
			})
		end,
	},
	{
		"saghen/blink.cmp",
		version = "1.*",
		event = "InsertEnter",
		dependencies = { "rafamadriz/friendly-snippets" },
		opts = {
			keymap = { preset = "default" },
			appearance = { nerd_font_variant = "mono" },
			completion = { documentation = { auto_show = false } },
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},
			fuzzy = { implementation = "prefer_rust_with_warning" },
		},
		opts_extend = { "sources.default" },
	},
	{
		"mason-org/mason.nvim",
		cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate", "MasonLog" },
		opts = { ui = { border = "rounded" } },
	},
	{
		"mason-org/mason-lspconfig.nvim",
		event = { "BufReadPre", "BufNewFile" },
		cmd = { "LspInstall", "LspUninstall" },
		dependencies = {
			"mason-org/mason.nvim",
			"neovim/nvim-lspconfig",
			"saghen/blink.cmp",
		},
		opts = {
			ensure_installed = { "clangd", "basedpyright" },
			automatic_enable = { "clangd", "basedpyright" },
		},
		config = function(_, opts)
			local capabilities = require("blink.cmp").get_lsp_capabilities()
			local python_capabilities = vim.deepcopy(capabilities)
			python_capabilities.workspace = python_capabilities.workspace or {}
			python_capabilities.workspace.didChangeWatchedFiles =
				python_capabilities.workspace.didChangeWatchedFiles or {}
			python_capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = false

			vim.lsp.config("clangd", { capabilities = capabilities })
			vim.lsp.config("basedpyright", { capabilities = python_capabilities })
			require("mason-lspconfig").setup(opts)
		end,
	},
}, {
	change_detection = { notify = false },
	install = { colorscheme = { "catppuccin-nvim", "habamax" } },
})

-- Optional, unmanaged per-machine overrides.
pcall(require, "machine")
