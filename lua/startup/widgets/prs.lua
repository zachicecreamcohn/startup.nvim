-- Open PRs authored by you, via the `gh` CLI (must be installed and authenticated).
local M = {}

local FIELDS = "number,title,isDraft,mergeable,mergeStateStatus,reviewDecision,statusCheckRollup,updatedAt"
local REVIEW_FIELDS = FIELDS .. ",author,reviews,reviewRequests"

-- Review requests disappear once you submit a review, so "PRs I'm reviewing" is
-- the union of currently-requested and already-reviewed.
local REVIEW_SEARCHES = { "review-requested:@me", "reviewed-by:@me -author:@me" }

local ICON = {
	pass = "\u{f42e}",
	fail = "\u{f467}",
	pending = "\u{f444}",
}

local CHECK_HL = {
	pass = "StartupOk",
	fail = "StartupError",
	pending = "StartupPending",
}

local FAILED = {
	FAILURE = true,
	ERROR = true,
	TIMED_OUT = true,
	CANCELLED = true,
	ACTION_REQUIRED = true,
	STARTUP_FAILURE = true,
}

-- Keyed by the widget's opts table so each configured PR widget has its own cache.
local states = setmetatable({}, { __mode = "k" })

local function refresh_ms(opts)
	return (opts.refresh or 300) * 1000
end

-- CheckRuns report status/conclusion; legacy StatusContexts report a single state.
local function summarize_checks(rollup)
	local passed, failed, pending = 0, 0, 0
	for _, check in ipairs(rollup or {}) do
		local result = check.conclusion or check.state
		if check.__typename == "CheckRun" and check.status ~= "COMPLETED" then
			pending = pending + 1
		elseif result == "PENDING" or result == "EXPECTED" then
			pending = pending + 1
		elseif FAILED[result] then
			failed = failed + 1
		else
			passed = passed + 1
		end
	end
	local total = passed + failed + pending
	if total == 0 then
		return nil
	end
	local kind = failed > 0 and "fail" or pending > 0 and "pending" or "pass"
	return { kind = kind, text = string.format("%s %d/%d", ICON[kind], passed, total) }
end

local function merge_status(pr)
	if pr.isDraft then
		return "Draft", "StartupLabel"
	end
	if pr.mergeable == "CONFLICTING" or pr.mergeStateStatus == "DIRTY" then
		return "Conflicts", "StartupError"
	end
	local state = pr.mergeStateStatus
	if state == "CLEAN" or state == "HAS_HOOKS" then
		return "Ready to merge", "StartupOk"
	end
	if state == "BEHIND" then
		return "Behind base", "StartupPending"
	end
	if state == "UNSTABLE" then
		return "Mergeable, checks failing", "StartupPending"
	end
	-- BLOCKED, or UNKNOWN while GitHub lazily computes mergeability: explain via reviews.
	if pr.reviewDecision == "CHANGES_REQUESTED" then
		return "Changes requested", "StartupError"
	end
	if pr.reviewDecision == "REVIEW_REQUIRED" then
		return "Needs review", "StartupPending"
	end
	if pr.reviewDecision == "APPROVED" then
		return state == "BLOCKED" and "Approved, blocked" or "Approved", "StartupPending"
	end
	return state == "BLOCKED" and "Blocked" or "Unknown", "StartupLabel"
end

local function fetch(opts, state, ctx)
	state.fetching = true
	local include_reviews = opts.reviews ~= false
	local results = {}
	local pending = 0

	local function done()
		pending = pending - 1
		if pending == 0 then
			state.results = results
			state.fetched_at = vim.uv.now()
			state.fetching = false
			ctx.redraw()
		end
	end

	local function gh(args, on_json, result)
		pending = pending + 1
		vim.system(vim.list_extend({ "gh" }, args), { text = true }, function(res)
			local ok, data = pcall(vim.json.decode, res.stdout or "")
			if res.code ~= 0 or not ok then
				result.error = result.error or vim.trim(res.stderr ~= "" and res.stderr or "gh failed")
			else
				on_json(data)
			end
			done()
		end)
	end

	-- Hold one pending slot until every request is queued so a fast reply can't finish early.
	pending = 1
	if include_reviews and not state.login then
		gh({ "api", "user" }, function(user)
			state.login = user.login
		end, results)
	end

	for i, repo in ipairs(opts.repos) do
		local result = { repo = repo, authored = {}, reviewing = {} }
		results[i] = result
		local base = { "pr", "list", "--repo", repo, "--state", "open" }

		gh(vim.list_extend(vim.deepcopy(base), { "--author", "@me", "--json", FIELDS }), function(prs)
			result.authored = prs
		end, result)

		if include_reviews then
			local seen = {}
			for _, search in ipairs(REVIEW_SEARCHES) do
				gh(vim.list_extend(vim.deepcopy(base), { "--search", search, "--json", REVIEW_FIELDS }), function(prs)
					for _, pr in ipairs(prs) do
						if not seen[pr.number] then
							seen[pr.number] = true
							table.insert(result.reviewing, pr)
						end
					end
					table.sort(result.reviewing, function(a, b)
						return a.number > b.number
					end)
				end, result)
			end
		end
	end
	done()
end

local function my_review_status(pr, login)
	local requested = false
	for _, request in ipairs(pr.reviewRequests or {}) do
		if request.login == login then
			requested = true
		end
	end

	local latest, has_draft
	for _, review in ipairs(pr.reviews or {}) do
		if review.author and review.author.login == login then
			if review.state == "PENDING" then
				has_draft = true
			else
				latest = review.state
			end
		end
	end

	if requested then
		return latest and "Re-review requested" or "Review requested", "StartupPending"
	end
	if latest == "APPROVED" then
		return "Approved by you", "StartupOk"
	end
	if latest == "CHANGES_REQUESTED" then
		return "You requested changes", "StartupError"
	end
	if latest == "COMMENTED" then
		return "You commented", "StartupLabel"
	end
	if latest == "DISMISSED" then
		return "Your review was dismissed", "StartupLabel"
	end
	if has_draft then
		return "Draft review", "StartupPending"
	end
	return "Team review requested", "StartupPending"
end

local function pad(text, width)
	return text .. string.rep(" ", width - vim.fn.strdisplaywidth(text))
end

-- updatedAt covers commits, comments, reviews, review requests, and edits, but not
-- check runs, so those timestamps are folded in too. ISO-8601 UTC strings compare
-- correctly as plain strings.
local function last_activity(pr)
	local latest = pr.updatedAt or ""
	for _, check in ipairs(pr.statusCheckRollup or {}) do
		for _, t in ipairs({ check.startedAt, check.completedAt }) do
			if t and t > latest then
				latest = t
			end
		end
	end
	return latest
end

local function recent(prs, days)
	if not days then
		return prs
	end
	local cutoff = os.date("!%Y-%m-%dT%H:%M:%SZ", os.time() - days * 86400)
	return vim.tbl_filter(function(pr)
		return last_activity(pr) >= cutoff
	end, prs)
end

local function truncate(text, width)
	if vim.fn.strdisplaywidth(text) <= width then
		return pad(text, width)
	end
	return vim.fn.strcharpart(text, 0, width - 1) .. "…"
end

local function checks_chunk(pr)
	local checks = summarize_checks(pr.statusCheckRollup)
	return { pad(checks and checks.text or "–", 8), checks and CHECK_HL[checks.kind] or "StartupLabel" }
end

local AUTHOR_WIDTH = 16

local function authored_row(pr, title_width)
	local status, status_hl = merge_status(pr)
	return {
		{ string.format("#%-6d ", pr.number), "StartupLabel" },
		{ truncate(pr.title, title_width) .. "  " },
		checks_chunk(pr),
		{ "  " },
		{ status, status_hl },
	}
end

local function reviewing_row(pr, title_width, login)
	local status, status_hl = my_review_status(pr, login)
	return {
		{ string.format("#%-6d ", pr.number), "StartupLabel" },
		{ truncate(pr.title, title_width) .. "  " },
		{ truncate("@" .. pr.author.login, AUTHOR_WIDTH) .. "  ", "StartupLabel" },
		checks_chunk(pr),
		{ "  " },
		{ status, status_hl },
	}
end

local function section(lines, heading, results, key, show_repo, active_within, row)
	if #lines > 0 then
		lines[#lines + 1] = ""
		lines[#lines + 1] = ""
	end
	lines[#lines + 1] = { { heading, "StartupTitle" } }
	for i, result in ipairs(results) do
		local prs = recent(result[key], active_within)
		if show_repo then
			if i > 1 then
				lines[#lines + 1] = ""
			end
			lines[#lines + 1] = { { result.repo, "StartupLabel" } }
		end
		local indent = show_repo and { "  " } or { "" }
		if result.error then
			lines[#lines + 1] = { indent, { (result.error:gsub("\n.*", "")), "StartupError" } }
		elseif #prs == 0 then
			lines[#lines + 1] = { indent, { "None recently active", "StartupLabel" } }
		end
		if not result.error then
			for _, pr in ipairs(prs) do
				lines[#lines + 1] = { indent, unpack(row(pr)) }
			end
		end
	end
end

local function format(opts, results, login, max_width)
	local title_width = math.min(opts.title_width or 50, math.max(10, max_width - 65))
	local show_repo = #results > 1
	local active_within = opts.active_within == nil and 14 or opts.active_within or nil
	local lines = {}
	section(lines, "Authored", results, "authored", show_repo, active_within, function(pr)
		return authored_row(pr, title_width)
	end)
	if opts.reviews ~= false then
		section(lines, "Reviewing", results, "reviewing", show_repo, active_within, function(pr)
			return reviewing_row(pr, title_width, login)
		end)
	end
	return lines
end

function M.render(opts, max_width, ctx)
	if not opts.repos or #opts.repos == 0 then
		return { lines = { "prs: set `repos`" }, hl = "ErrorMsg" }
	end

	local state = states[opts]
	if not state then
		state = {}
		states[opts] = state
	end
	local stale = not state.fetched_at or vim.uv.now() - state.fetched_at >= refresh_ms(opts)
	if stale and not state.fetching then
		fetch(opts, state, ctx)
	end

	if not state.results then
		return { lines = { "Loading PRs…" }, hl = "StartupLabel" }
	end
	return { lines = format(opts, state.results, state.login, max_width) }
end

function M.next_refresh(opts)
	local state = states[opts]
	-- While a fetch is in flight its completion triggers the redraw.
	if not state or state.fetching or not state.fetched_at then
		return nil
	end
	return math.max(0, refresh_ms(opts) - (vim.uv.now() - state.fetched_at))
end

return M
