# startup.nvim

```lua
opts = {
	-- optional, in columns/lines: x = minimum space between widgets (used for
	-- wrapping), y = blank lines between rows
	gap = { x = 2, y = 1 },
	-- optional, in columns: rows wrap past this width and widgets are spread
	-- across it (flexbox space-between); defaults to the window width
	max_width = 120,
	fill_lone_widgets = true, -- optional: a widget alone on its row stretches to max_width
	widgets = {
		-- every widget also takes (optional):
		--   title = "..."        shown in the top border
		--   width = 40           box width in columns (grows if content needs more)
		--   height = 12          box height in lines (grows if content needs more)
		--   full_width = true    span the whole max_width on its own row
		--   fill_width = true    grow to take up the row's free space
		--   fill_height = true   stretch to the height of the tallest widget in its row
		--   dynamic_centering = true   keep content centered when the box is stretched
		{
			type = "note",
			text = "I'll be right back.",
			text_width = 40, -- optional: wrap width; defaults to 40, or the box width with width/full_width
		},
		{
			type = "clock",
			format = "12h", -- optional: "12h" | "24h"
			seconds = false, -- optional
			date_format = "%A, %B %d", -- optional: os.date format
		},
		{
			type = "weather",
			location = "New York", -- or latitude + longitude
			latitude = 40.71, -- optional
			longitude = -74.0, -- optional
			units = "imperial", -- optional: "imperial" | "metric"
		},
		{
			type = "stats", -- lazy.nvim startup time and plugin counts
		},
		{
			type = "socials", -- business card; every field optional, links copyable with yy
			name = "Ada Lovelace",
			subtitle = "Software Engineer",
			company = "Analytical Engines",
			bio = "Longer free-form text, word-wrapped.",
			github = "username",
			email = "me@example.com",
			website = "example.com",
			instagram = "handle",
			text_width = 50, -- optional: bio wrap width; defaults to 50, or the box width with width/full_width
		},
		{
			type = "prs", -- PRs you authored or are reviewing, via the `gh` CLI; `yy` on a row copies its URL
			repos = { "owner/repo" },
			refresh = 300, -- optional: seconds between refetches
			active_within = 14, -- optional: days of activity to be listed; false for all
			reviews = true, -- optional: include PRs you're requested on / have reviewed
			title_width = 50, -- optional: cap on title length; defaults to the available width
		},
	},
}
```

## lazy.nvim

```lua
{
	"zachicecreamcohn/startup.nvim",
	lazy = false,
	opts = {
		widgets = {
			{ type = "note", text = "I'll be right back." },
			{ type = "clock", seconds = true },
			{ type = "weather", location = "New York" },
		},
	},
}
```
