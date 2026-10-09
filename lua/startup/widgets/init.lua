-- A widget type is a module at startup.widgets.<type> exporting
-- render(opts, max_width, ctx) -> { lines = Line[], hl = string?, title = string? }
-- where Line is a string or a list of { text, hl? } chunks.
-- Async widgets render a placeholder and call ctx.redraw() once data arrives.
local M = {}

function M.render(opts, max_width, ctx)
	local ok, widget = pcall(require, "startup.widgets." .. tostring(opts.type))
	if not ok then
		return { lines = { "unknown widget type: " .. tostring(opts.type) }, hl = "ErrorMsg" }
	end
	local content = widget.render(opts, max_width, ctx)
	content.title = opts.title or content.title
	return content
end

return M
