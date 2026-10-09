local layout = require("startup.layout")
local canvas = require("startup.canvas")
local widgets = require("startup.widgets")

local M = {}

M.config = {
	widgets = {},
	gap = { x = 2, y = 1 },
}

local draw

-- One refresh timer per startup buffer, re-armed after every draw for the
-- soonest time any widget says its output will change.
local timers = {}
-- Last drawn canvas per buffer, used to resolve what's under the cursor.
local canvases = {}

local function schedule_refresh(buf, win)
	local delay
	for _, widget_opts in ipairs(M.config.widgets) do
		local d = widgets.next_refresh(widget_opts)
		if d and (not delay or d < delay) then
			delay = d
		end
	end

	local timer = timers[buf]
	if not delay then
		if timer then
			timer:stop()
		end
		return
	end
	if not timer then
		timer = vim.uv.new_timer()
		timers[buf] = timer
	end
	timer:stop()
	-- libuv measures delays from a cached loop time that can be stale; refresh it
	-- so wall-clock-aligned refreshes don't fire early.
	vim.uv.update_time()
	timer:start(math.max(delay, 10), 0, function()
		vim.schedule(function()
			if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
				draw(buf, win)
			end
		end)
	end)
end

local function redraw_callback(buf, win)
	return function()
		vim.schedule(function()
			if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
				draw(buf, win)
			end
		end)
	end
end

function draw(buf, win)
	local width = vim.api.nvim_win_get_width(win)
	local height = vim.api.nvim_win_get_height(win)

	local ctx = { redraw = redraw_callback(buf, win) }
	local boxes = {}
	for _, widget_opts in ipairs(M.config.widgets) do
		boxes[#boxes + 1] = canvas.frame(widgets.render(widget_opts, width - 4, ctx))
	end

	local c = canvas.new(width, height)
	for i, pos in ipairs(layout.flow(boxes, width, height, M.config.gap)) do
		c:blit(boxes[i], pos.row, pos.col)
	end

	vim.bo[buf].modifiable = true
	c:flush(buf)
	vim.bo[buf].modifiable = false
	canvases[buf] = c
	-- Timer-driven updates otherwise wait for the next UI event to reach the screen.
	vim.cmd("redraw")

	schedule_refresh(buf, win)
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

	vim.keymap.set("n", "yy", function()
		local c = canvases[buf]
		local url = c and c:url_at(vim.fn.line("."), vim.fn.virtcol("."))
		if not url then
			vim.cmd('normal! "' .. vim.v.register .. vim.v.count1 .. "yy")
			return
		end
		vim.fn.setreg(vim.v.register, url)
		vim.notify("Copied " .. url)
	end, { buffer = buf, desc = "Copy URL under cursor" })

	vim.api.nvim_create_autocmd("VimResized", {
		buffer = buf,
		callback = redraw_callback(buf, win),
	})

	vim.api.nvim_create_autocmd("BufWipeout", {
		buffer = buf,
		callback = function()
			canvases[buf] = nil
			local timer = timers[buf]
			if timer then
				timer:stop()
				timer:close()
				timers[buf] = nil
			end
		end,
	})
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
	vim.api.nvim_set_hl(0, "StartupBorder", { link = "FloatBorder", default = true })
	vim.api.nvim_set_hl(0, "StartupNote", { bold = true, default = true })
	vim.api.nvim_set_hl(0, "StartupTitle", { link = "Title", default = true })
	vim.api.nvim_set_hl(0, "StartupLabel", { link = "Comment", default = true })
	vim.api.nvim_set_hl(0, "StartupWeatherIcon", { link = "Special", default = true })
	vim.api.nvim_set_hl(0, "StartupClock", { link = "Title", default = true })
	vim.api.nvim_set_hl(0, "StartupOk", { link = "DiagnosticOk", default = true })
	vim.api.nvim_set_hl(0, "StartupError", { link = "DiagnosticError", default = true })
	vim.api.nvim_set_hl(0, "StartupPending", { link = "DiagnosticWarn", default = true })

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
