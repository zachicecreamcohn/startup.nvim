-- Startup stats from lazy.nvim. startuptime is only final once lazy fires
-- LazyVimStarted (after UIEnter), which is later than our VimEnter render.
local M = {}

local waiting = false

function M.render(_, _, ctx)
	local ok, lazy = pcall(require, "lazy")
	if not ok then
		return { lines = { "lazy.nvim not found" }, hl = "ErrorMsg" }
	end

	local stats = lazy.stats()
	if stats.startuptime == 0 then
		if not waiting then
			waiting = true
			vim.api.nvim_create_autocmd("User", {
				pattern = "LazyVimStarted",
				once = true,
				callback = ctx.redraw,
			})
		end
		return { lines = { "Measuring startup…" }, hl = "StartupLabel" }
	end

	local function row(label, value)
		return { { string.format("%-10s", label), "StartupLabel" }, { value } }
	end
	return {
		lines = {
			row("Startup", string.format("%.1f ms", stats.startuptime)),
			row("Plugins", string.format("%d / %d loaded", stats.loaded, stats.count)),
		},
	}
end

return M
