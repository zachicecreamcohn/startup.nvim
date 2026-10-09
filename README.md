# startup.nvim

```lua
opts = {
	gap = { x = 2, y = 1 }, -- optional
	widgets = {
		-- every widget also takes `title` (optional)
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
			type = "prs", -- PRs you authored or are reviewing, via the `gh` CLI
			repos = { "owner/repo" },
			refresh = 300, -- optional: seconds between refetches
			active_within = 14, -- optional: days of activity to be listed; false for all
			reviews = true, -- optional: include PRs you're requested on / have reviewed
			title_width = 50, -- optional
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
