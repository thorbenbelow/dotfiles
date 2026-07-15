return { -- Autoformat
	"stevearc/conform.nvim",
	opts = {
		notify_on_error = false,
		format_on_save = {
			timeout_ms = 500,
			lsp_format = "fallback",
		},
		formatters_by_ft = {
			lua = { "stylua" },
			javascript = { "prettierd", "prettier", stop_after_first = true },
			typescript = { "prettierd", "prettier", stop_after_first = true },
			python = { "isort", "black" },
			go = { "gofmt", "goimports" },
			sh = { "shfmt" },
			-- Conform can also run multiple formatters sequentially
			-- python = { "isort", "black" },
		},
	},
}
