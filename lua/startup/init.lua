local layout = require("startup.layout")
local canvas = require("startup.canvas")
local widgets = require("startup.widgets")

local M = {}

M.config = {
	widgets = {},
	gap = { x = 2, y = 1 },
}

local function draw(buf, win)
	local width = vim.api.nvim_win_get_width(win)
	local height = vim.api.nvim_win_get_height(win)

	local boxes = {}
	for _, widget_opts in ipairs(M.config.widgets) do
		boxes[#boxes + 1] = canvas.frame(widgets.render(widget_opts, width - 4))
	end

	local c = canvas.new(width, height)
	for i, pos in ipairs(layout.flow(boxes, width, height, M.config.gap)) do
		c:blit(boxes[i], pos.row, pos.col)
	end

	vim.bo[buf].modifiable = true
	c:flush(buf)
	vim.bo[buf].modifiable = false
end

local function open()
	vim.cmd("enew")
	local buf = vim.api.nvim_get_current_buf()
	local win = vim.api.nvim_get_current_win()
	vim.opt_local.buftype = "nofile"
	vim.opt_local.bufhidden = "wipe"
	vim.opt_local.swapfile = false
	vim.opt_local.number = false
	vim.opt_local.relativenumber = false
	vim.opt_local.signcolumn = "no"
	vim.opt_local.cursorline = false
	vim.opt_local.list = false

	draw(buf, win)

	vim.api.nvim_create_autocmd("VimResized", {
		buffer = buf,
		callback = function()
			if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
				draw(buf, win)
			end
		end,
	})
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
	vim.api.nvim_set_hl(0, "StartupBorder", { link = "FloatBorder", default = true })
	vim.api.nvim_set_hl(0, "StartupNote", { bold = true, default = true })

	vim.api.nvim_create_autocmd("VimEnter", {
		group = vim.api.nvim_create_augroup("startup.nvim", { clear = true }),
		callback = function()
			if vim.fn.argc() > 0 then
				return
			end
			open()
		end,
	})
end

return M
