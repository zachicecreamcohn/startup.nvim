local M = {}

-- 3x5 pixel font; each pixel is drawn two cells wide so digits look roughly
-- square given terminal cell proportions.
local FONT = {
	["0"] = { "###", "# #", "# #", "# #", "###" },
	["1"] = { "## ", " # ", " # ", " # ", "###" },
	["2"] = { "###", "  #", "###", "#  ", "###" },
	["3"] = { "###", "  #", "###", "  #", "###" },
	["4"] = { "# #", "# #", "###", "  #", "  #" },
	["5"] = { "###", "#  ", "###", "  #", "###" },
	["6"] = { "###", "#  ", "###", "# #", "###" },
	["7"] = { "###", "  #", "  #", "  #", "  #" },
	["8"] = { "###", "# #", "###", "# #", "###" },
	["9"] = { "###", "# #", "###", "  #", "###" },
	[":"] = { " ", "#", " ", "#", " " },
}

local function big(text)
	local rows = { "", "", "", "", "" }
	for i = 1, #text do
		local glyph = FONT[text:sub(i, i)]
		for r = 1, 5 do
			local sep = i > 1 and "  " or ""
			rows[r] = rows[r] .. sep .. glyph[r]:gsub("#", "██"):gsub(" ", "  ")
		end
	end
	return rows
end

local function center(text, width)
	local pad = width - vim.fn.strdisplaywidth(text)
	local left = math.floor(pad / 2)
	return string.rep(" ", left) .. text .. string.rep(" ", pad - left)
end

-- Wake this long after a boundary so timer jitter can't land us on the old value.
local BOUNDARY_MARGIN_MS = 50

local function default_date(now)
	return os.date("%A, %B ", now) .. tonumber(os.date("%d", now))
end

function M.render(opts)
	local now = os.time()
	local hour12 = (opts.format or "12h") == "12h"
	local time
	if hour12 then
		time = tostring(tonumber(os.date("%I", now))) .. os.date(":%M", now)
	else
		time = os.date("%H:%M", now)
	end
	if opts.seconds then
		time = time .. os.date(":%S", now)
	end

	local digits = big(time)
	local width = vim.fn.strdisplaywidth(digits[1])

	local lines = {}
	for _, row in ipairs(digits) do
		lines[#lines + 1] = { { row, "StartupClock" } }
	end

	local date = opts.date_format and os.date(opts.date_format, now) or default_date(now)
	if hour12 then
		date = date .. "  ·  " .. os.date("%p", now)
	end
	width = math.max(width, vim.fn.strdisplaywidth(date))
	for i, line in ipairs(lines) do
		lines[i] = { { center(line[1][1], width), "StartupClock" } }
	end
	lines[#lines + 1] = ""
	lines[#lines + 1] = { { center(date, width), "StartupLabel" } }

	return { lines = lines }
end

function M.next_refresh(opts)
	local sec, usec = vim.uv.gettimeofday()
	local ms_into_second = math.floor(usec / 1000)
	if opts.seconds then
		return 1000 - ms_into_second + BOUNDARY_MARGIN_MS
	end
	return (60 - sec % 60) * 1000 - ms_into_second + BOUNDARY_MARGIN_MS
end

return M
