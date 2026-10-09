-- A digital business card: name, role, bio, and social links (each copyable with yy).
local M = {}

local wrap = require("startup.widgets.note").wrap

-- Font Awesome glyphs from Nerd Fonts, chosen as one family so they match visually.
local LINKS = {
	{
		key = "github",
		icon = "\u{f09b}",
		label = function(v)
			return "github.com/" .. v
		end,
		url = function(v)
			return "https://github.com/" .. v
		end,
	},
	{
		key = "email",
		icon = "\u{f0e0}",
		label = function(v)
			return v
		end,
		url = function(v)
			return "mailto:" .. v
		end,
	},
	{
		key = "website",
		icon = "\u{f0ac}",
		label = function(v)
			return (v:gsub("^https?://", ""):gsub("/$", ""))
		end,
		url = function(v)
			return v:match("^https?://") and v or ("https://" .. v)
		end,
	},
	{
		key = "instagram",
		icon = "\u{f16d}",
		label = function(v)
			return "@" .. v:gsub("^@", "")
		end,
		url = function(v)
			return "https://instagram.com/" .. v:gsub("^@", "")
		end,
	},
}

local function centered(chunks)
	local line = { { fill = true } }
	vim.list_extend(line, chunks)
	line[#line + 1] = { fill = true }
	return line
end

function M.render(opts, max_width)
	local width = math.min(opts.width or (opts.full_width and max_width or 50), max_width)
	local lines = {}
	local function blank()
		if #lines > 0 then
			lines[#lines + 1] = ""
		end
	end

	if opts.name then
		lines[#lines + 1] = centered({ { opts.name, "StartupCardName" } })
	end
	local has_subtitle = opts.subtitle and opts.subtitle ~= ""
	local has_company = opts.company and opts.company ~= ""
	if has_subtitle or has_company then
		local role = has_subtitle and has_company and (opts.subtitle .. " @ " .. opts.company)
			or has_subtitle and opts.subtitle
			or ("@ " .. opts.company)
		lines[#lines + 1] = centered({ { role, "StartupLabel" } })
	end

	if opts.bio then
		if #lines > 0 then
			lines[#lines + 1] = ""
			lines[#lines + 1] = centered({ { string.rep("─", 8), "StartupBorder" } })
		end
		blank()
		for _, text in ipairs(wrap(opts.bio, width)) do
			lines[#lines + 1] = centered({ { text } })
		end
	end

	-- Links are left-aligned among themselves (icons in one column) and the block is centered.
	local links = {}
	local links_width = 0
	for _, link in ipairs(LINKS) do
		local value = opts[link.key]
		if value and value ~= "" then
			local label = link.label(value)
			links[#links + 1] = { icon = link.icon, label = label, url = link.url(value) }
			links_width = math.max(links_width, vim.fn.strdisplaywidth(label) + 3)
		end
	end
	if #links > 0 then
		blank()
		for _, link in ipairs(links) do
			local pad = links_width - 3 - vim.fn.strdisplaywidth(link.label)
			local line = centered({
				{ link.icon, "StartupCardIcon" },
				{ "  " .. link.label .. string.rep(" ", pad) },
			})
			line.url = link.url
			lines[#lines + 1] = line
		end
	end

	if #lines == 0 then
		return { lines = { "socials: nothing configured" }, hl = "StartupLabel" }
	end
	return { lines = lines }
end

return M
