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
	local default_width = opts.full_width and max_width or 40
	local width = math.min(opts.width or default_width, max_width)
	return { lines = M.wrap(opts.text or "", width), hl = "StartupNote" }
end

return M
