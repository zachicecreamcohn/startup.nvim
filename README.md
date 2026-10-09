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
	},
}
```
