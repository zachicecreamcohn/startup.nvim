local M = {}

function M.wrap(text, width)
	local lines = {}
	for _, paragraph in ipairs(vim.split(text, "\n", { plain = true })) do
		local line = ""
		for word in paragraph:gmatch("%S+") do
			if line == "" then
				line = word
			elseif vim.fn.strdisplaywidth(line .. " " .. word) <= width then
				line = line .. " " .. word
			else
				lines[#lines + 1] = line
				line = word
			end
		end
		lines[#lines + 1] = line
	end
	return lines
end

function M.render(opts, max_width)
	-- When the box has a set or full width, max_width already reflects it.
	local default_width = (opts.full_width or opts.width) and max_width or 40
	local width = math.min(opts.text_width or default_width, max_width)
	return { lines = M.wrap(opts.text or "", width), hl = "StartupNote" }
end

return M
