-- Uses Open-Meteo (https://open-meteo.com): free, no API key.
local M = {}

local GEOCODE_URL = "https://geocoding-api.open-meteo.com/v1/search"
local FORECAST_URL = "https://api.open-meteo.com/v1/forecast"

-- Nerd Font weather glyphs; emoji are avoided because they render double-width
-- and break the single-cell canvas alignment.
local ICON = {
	sunny = "\u{e30d}",
	mostly_clear = "\u{e30c}",
	partly_cloudy = "\u{e302}",
	cloudy = "\u{e312}",
	fog = "\u{e313}",
	sprinkle = "\u{e31b}",
	rain = "\u{e318}",
	rain_mix = "\u{e316}",
	showers = "\u{e319}",
	snow = "\u{e31a}",
	thunderstorm = "\u{e31d}",
	hail = "\u{e314}",
}

-- WMO weather interpretation codes
local CONDITIONS = {
	[0] = { ICON.sunny, "Clear" },
	[1] = { ICON.mostly_clear, "Mostly clear" },
	[2] = { ICON.partly_cloudy, "Partly cloudy" },
	[3] = { ICON.cloudy, "Overcast" },
	[45] = { ICON.fog, "Fog" },
	[48] = { ICON.fog, "Rime fog" },
	[51] = { ICON.sprinkle, "Light drizzle" },
	[53] = { ICON.sprinkle, "Drizzle" },
	[55] = { ICON.sprinkle, "Heavy drizzle" },
	[56] = { ICON.rain_mix, "Freezing drizzle" },
	[57] = { ICON.rain_mix, "Freezing drizzle" },
	[61] = { ICON.rain, "Light rain" },
	[63] = { ICON.rain, "Rain" },
	[65] = { ICON.rain, "Heavy rain" },
	[66] = { ICON.rain_mix, "Freezing rain" },
	[67] = { ICON.rain_mix, "Freezing rain" },
	[71] = { ICON.snow, "Light snow" },
	[73] = { ICON.snow, "Snow" },
	[75] = { ICON.snow, "Heavy snow" },
	[77] = { ICON.snow, "Snow grains" },
	[80] = { ICON.showers, "Rain showers" },
	[81] = { ICON.showers, "Rain showers" },
	[82] = { ICON.showers, "Violent showers" },
	[85] = { ICON.snow, "Snow showers" },
	[86] = { ICON.snow, "Snow showers" },
	[95] = { ICON.thunderstorm, "Thunderstorm" },
	[96] = { ICON.hail, "Thunderstorm, hail" },
	[99] = { ICON.hail, "Thunderstorm, hail" },
}

-- Keyed by the widget's opts table so each configured weather widget fetches once per session.
local states = setmetatable({}, { __mode = "k" })

local function get_json(url, params, callback)
	local query = {}
	for k, v in pairs(params) do
		query[#query + 1] = k .. "=" .. vim.uri_encode(tostring(v))
	end
	vim.system({ "curl", "-sfL", "--max-time", "10", url .. "?" .. table.concat(query, "&") }, { text = true }, function(res)
		if res.code ~= 0 then
			return callback("request failed (curl exit " .. res.code .. ")")
		end
		local ok, data = pcall(vim.json.decode, res.stdout)
		if not ok then
			return callback("invalid response")
		end
		callback(nil, data)
	end)
end

local function resolve_location(opts, callback)
	if opts.latitude and opts.longitude then
		return callback(nil, { lat = opts.latitude, lon = opts.longitude, name = opts.location })
	end
	if not opts.location then
		return callback("set `location` or `latitude`/`longitude`")
	end
	get_json(GEOCODE_URL, { name = opts.location, count = 1 }, function(err, data)
		local place = data and data.results and data.results[1]
		if err or not place then
			return callback(err or ("location not found: " .. opts.location))
		end
		callback(nil, { lat = place.latitude, lon = place.longitude, name = place.name })
	end)
end

local function fetch(opts, state, ctx)
	local imperial = (opts.units or "imperial") == "imperial"
	resolve_location(opts, function(err, loc)
		if err then
			state.error = err
			return ctx.redraw()
		end
		get_json(FORECAST_URL, {
			latitude = loc.lat,
			longitude = loc.lon,
			current = "temperature_2m,apparent_temperature,weather_code,wind_speed_10m",
			daily = "temperature_2m_max,temperature_2m_min",
			forecast_days = 1,
			temperature_unit = imperial and "fahrenheit" or "celsius",
			wind_speed_unit = imperial and "mph" or "kmh",
			timezone = "auto",
		}, function(ferr, data)
			if ferr or not data.current then
				state.error = ferr or "unexpected response"
			else
				state.data = data
				state.place = loc.name
			end
			ctx.redraw()
		end)
	end)
end

local function format(state)
	local cur, daily = state.data.current, state.data.daily
	local units = state.data.current_units
	local condition = CONDITIONS[cur.weather_code] or { "?", "Unknown" }
	local function temp(v)
		return string.format("%d%s", math.floor(v + 0.5), units.temperature_2m)
	end
	local wind_unit = units.wind_speed_10m == "mp/h" and "mph" or units.wind_speed_10m
	local function row(label, value)
		return { { string.format("%-12s", label), "StartupLabel" }, { value } }
	end
	return {
		{ { state.place or "", "StartupLabel" } },
		{ { condition[1], "StartupWeatherIcon" }, { "  " .. temp(cur.temperature_2m), "StartupTitle" }, { "  " .. condition[2] } },
		"",
		row("Feels like", temp(cur.apparent_temperature)),
		row("High / Low", temp(daily.temperature_2m_max[1]) .. " / " .. temp(daily.temperature_2m_min[1])),
		row("Wind", string.format("%d %s", math.floor(cur.wind_speed_10m + 0.5), wind_unit)),
	}
end

function M.render(opts, _, ctx)
	local state = states[opts]
	if not state then
		state = {}
		states[opts] = state
		fetch(opts, state, ctx)
	end

	if state.error then
		return { lines = { "Weather: " .. state.error }, hl = "ErrorMsg" }
	end
	if not state.data then
		return { lines = { "Loading weather…" }, hl = "StartupLabel" }
	end
	return { lines = format(state) }
end

return M
