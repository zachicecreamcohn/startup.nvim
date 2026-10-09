-- A widget type is a module at startup.widgets.<type> exporting
-- render(opts, max_width, ctx) -> { lines = Line[], hl = string?, title = string? }
-- where Line is a string or a list of { text, hl? } chunks.
-- Time-based widgets may also export next_refresh(opts) -> ms until their output changes.
-- Async widgets render a placeholder and call ctx.redraw() once data arrives.
local M = {}

local function load(type)
	local ok, widget = pcall(require, "startup.widgets." .. tostring(type))
	return ok and widget or nil
end

function M.next_refresh(opts)
	local widget = load(opts.type)
	return widget and widget.next_refresh and widget.next_refresh(opts) or nil
end

function M.render(opts, max_width, ctx)
	local widget = load(opts.type)
	if not widget then
		return { lines = { "unknown widget type: " .. tostring(opts.type) }, hl = "ErrorMsg" }
	end
	local content = widget.render(opts, max_width, ctx)
	content.title = opts.title or content.title
	return content
end

return M
