return { -- Highlight, edit, and navigate code
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	build = ":TSUpdate",
	config = function()
		-- [[ Configure Treesitter ]] See `:help nvim-treesitter`
		local ts = require("nvim-treesitter")
		ts.setup({})

		-- Define desired parsers to ensure they are installed
		local parsers = { "bash", "c", "html", "lua", "markdown", "vim", "vimdoc" }
		for _, parser in ipairs(parsers) do
			ts.install(parser)
		end

		-- Automatically enable treesitter features on file load
		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("treesitter-enable", { clear = true }),
			callback = function(args)
				local lang = vim.treesitter.language.get_lang(args.match)
				if not lang or not vim.treesitter.language.add(lang) then return end

				-- Enable Highlighting
				if vim.treesitter.query.get(lang, "highlights") then
					vim.treesitter.start(args.buf)
				end

				-- Enable Indentation
				if vim.treesitter.query.get(lang, "indents") then
					vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end
			end,
		})

		-- There are additional nvim-treesitter modules that you can use to interact
		-- with nvim-treesitter. You should go explore a few and see what interests you:
		--
		--    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
		--    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
		--    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
	end,
}
