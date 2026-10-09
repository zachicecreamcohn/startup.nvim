local M = {}

M.config = {
	text = "",
}

local function render()
	vim.cmd("enew")
	vim.opt_local.buftype = "nofile"
	vim.opt_local.bufhidden = "wipe"
	vim.opt_local.swapfile = false
	vim.opt_local.number = false
	vim.opt_local.relativenumber = false
	vim.opt_local.signcolumn = "no"
	vim.opt_local.modifiable = true

	local msg = M.config.text
	local win_w = vim.api.nvim_win_get_width(0)
	local win_h = vim.api.nvim_win_get_height(0)
	local pad_x = math.floor((win_w - #msg) / 2)
	local top = math.floor((win_h - 1) / 2)
	local bottom = win_h - top - 1

	local lines = {}
	for _ = 1, top do
		lines[#lines + 1] = ""
	end
	lines[#lines + 1] = string.rep(" ", pad_x) .. msg
	for _ = 1, bottom do
		lines[#lines + 1] = ""
	end

	vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
	local ns = vim.api.nvim_create_namespace("startup")
	vim.api.nvim_set_hl(0, "StartupBold", { bold = true })
	vim.api.nvim_buf_add_highlight(0, ns, "StartupBold", top, pad_x, pad_x + #msg)
	vim.opt_local.modifiable = false
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
	vim.api.nvim_create_autocmd("VimEnter", {
		group = vim.api.nvim_create_augroup("startup.nvim", { clear = true }),
		callback = function()
			if vim.fn.argc() > 0 then
				return
			end
			render()
		end,
	})
end

return M
