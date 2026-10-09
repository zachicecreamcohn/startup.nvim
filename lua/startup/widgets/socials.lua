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

local ROLE_ICON = {
	subtitle = "\u{f0b1}", -- briefcase
	company = "\u{f1ad}", -- building
}

local function centered(chunks)
	local line = { { fill = true } }
	vim.list_extend(line, chunks)
	line[#line + 1] = { fill = true }
	return line
end

function M.render(opts, max_width)
	local default_width = (opts.full_width or opts.width) and max_width or 50
	local width = math.min(opts.text_width or default_width, max_width)
	local lines = {}
	local function blank()
		if #lines > 0 then
			lines[#lines + 1] = ""
		end
	end

	if opts.name then
		lines[#lines + 1] = centered({ { opts.name, "StartupCardName" } })
	end
	local function present(v)
		return v ~= nil and v ~= ""
	end

	local role = {}
	if present(opts.subtitle) then
		role[#role + 1] = { icon = ROLE_ICON.subtitle, label = opts.subtitle }
	end
	if present(opts.company) then
		role[#role + 1] = { icon = ROLE_ICON.company, label = opts.company }
	end

	local links = {}
	for _, link in ipairs(LINKS) do
		local value = opts[link.key]
		if present(value) then
			links[#links + 1] = { icon = link.icon, label = link.label(value), url = link.url(value) }
		end
	end

	-- Role and link rows share one width so their icons line up in a single column,
	-- and that block is centered as a whole.
	local list_width = 0
	for _, item in ipairs(vim.list_extend(vim.deepcopy(role), links)) do
		list_width = math.max(list_width, vim.fn.strdisplaywidth(item.label) + 3)
	end
	local function add_list(items)
		for _, item in ipairs(items) do
			local pad = list_width - 3 - vim.fn.strdisplaywidth(item.label)
			local line = centered({
				{ item.icon, "StartupCardIcon" },
				{ "  " .. item.label .. string.rep(" ", pad), not item.url and "StartupLabel" or nil },
			})
			line.url = item.url
			lines[#lines + 1] = line
		end
	end

	if #role > 0 then
		blank()
		add_list(role)
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

	if #links > 0 then
		blank()
		add_list(links)
	end

	if #lines == 0 then
		return { lines = { "socials: nothing configured" }, hl = "StartupLabel" }
	end
	return { lines = lines }
end

return M
