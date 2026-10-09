-- A widget type is a module at startup.widgets.<type> exporting
-- render(opts, max_width) -> { lines = string[], hl = string? }
local M = {}

function M.render(opts, max_width)
	local ok, widget = pcall(require, "startup.widgets." .. tostring(opts.type))
	if not ok then
		return { lines = { "unknown widget type: " .. tostring(opts.type) }, hl = "ErrorMsg" }
	end
	return widget.render(opts, max_width)
end

return M
