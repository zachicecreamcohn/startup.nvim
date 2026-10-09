# startup.nvim

```lua
opts = {
	-- optional, in columns/lines: x = minimum space between widgets (used for
	-- wrapping), y = blank lines between rows
	gap = { x = 2, y = 1 },
	-- optional, in columns: rows wrap past this width and widgets are spread
	-- across it (flexbox space-between); defaults to the window width
	max_width = 120,
	widgets = {
		-- every widget also takes (optional):
		--   title = "..."        shown in the top border
		--   full_width = true    span the whole max_width on its own row
		{
			type = "note",
			text = "I'll be right back.",
			width = 40, -- optional
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
