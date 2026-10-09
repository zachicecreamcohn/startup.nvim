-- A grid of single-width display cells. Tracking cells rather than bytes keeps
-- multibyte border glyphs aligned; byte offsets are only computed at flush time.
local Canvas = {}
Canvas.__index = Canvas

local M = {}

local function chars(s)
	return vim.fn.split(s, "\\zs")
end

function M.new(width, height)
	local cells, hls = {}, {}
	for r = 1, height do
		cells[r] = {}
		hls[r] = {}
		for c = 1, width do
			cells[r][c] = " "
		end
	end
	return setmetatable({ width = width, height = height, cells = cells, hls = hls }, Canvas)
end

local PAD_X = 2
local PAD_Y = 1

local function width_of(s)
	return vim.fn.strdisplaywidth(s)
end

-- A content line is either a plain string or a list of { text, hl? } chunks.
local function to_chunks(line, default_hl)
	if type(line) == "string" then
		return { { line, default_hl } }
	end
	local chunks = {}
	for _, chunk in ipairs(line) do
		chunks[#chunks + 1] = { chunk[1], chunk[2] or default_hl }
	end
	return chunks
end

local function border_row(left, fill, right, width, title)
	local cells = { left }
	local hls = {}
	local col = 2
	if title then
		vim.list_extend(cells, chars("─ "))
		local title_cells = chars(title)
		vim.list_extend(cells, title_cells)
		cells[#cells + 1] = " "
		hls[#hls + 1] = { from = 1, to = 3, group = "StartupBorder" }
		hls[#hls + 1] = { from = 4, to = 3 + #title_cells, group = "StartupTitle" }
		col = #cells + 1
	end
	for _ = col, width - 1 do
		cells[#cells + 1] = fill
	end
	cells[#cells + 1] = right
	hls[#hls + 1] = { from = col, to = width, group = "StartupBorder" }
	return { cells = cells, hls = hls }
end

local function content_row(chunks, inner)
	local cells = { "│" }
	local hls = { { from = 1, to = 1, group = "StartupBorder" } }
	for _ = 1, PAD_X do
		cells[#cells + 1] = " "
	end
	for _, chunk in ipairs(chunks) do
		local from = #cells + 1
		vim.list_extend(cells, chars(chunk[1]))
		if chunk[2] and #cells >= from then
			hls[#hls + 1] = { from = from, to = #cells, group = chunk[2] }
		end
	end
	for _ = #cells, inner + PAD_X * 2 do
		cells[#cells + 1] = " "
	end
	cells[#cells + 1] = "│"
	hls[#hls + 1] = { from = #cells, to = #cells, group = "StartupBorder" }
	return { cells = cells, hls = hls }
end

-- Wraps widget content in a padded, rounded border with an optional title.
function M.frame(content)
	local lines = {}
	local inner = content.title and (width_of(content.title) + 4 - PAD_X * 2) or 0
	for i, line in ipairs(content.lines) do
		lines[i] = to_chunks(line, content.hl)
		local w = 0
		for _, chunk in ipairs(lines[i]) do
			w = w + width_of(chunk[1])
		end
		inner = math.max(inner, w)
	end
	local width = inner + PAD_X * 2 + 2

	local rows = { border_row("╭", "─", "╮", width, content.title) }
	for _ = 1, PAD_Y do
		rows[#rows + 1] = content_row({}, inner)
	end
	for _, chunks in ipairs(lines) do
		rows[#rows + 1] = content_row(chunks, inner)
	end
	for _ = 1, PAD_Y do
		rows[#rows + 1] = content_row({}, inner)
	end
	rows[#rows + 1] = border_row("╰", "─", "╯", width)

	return { rows = rows, width = width, height = #rows }
end

function Canvas:blit(box, top, left)
	for i, row in ipairs(box.rows) do
		local r = top + i
		if r > self.height then
			return
		end
		for j, ch in ipairs(row.cells) do
			local c = left + j
			if c <= self.width then
				self.cells[r][c] = ch
			end
		end
		for _, hl in ipairs(row.hls) do
			if left + hl.from <= self.width then
				table.insert(self.hls[r], {
					from = left + hl.from,
					to = math.min(left + hl.to, self.width),
					group = hl.group,
				})
			end
		end
	end
end

function Canvas:flush(buf)
	local lines, byte_offsets = {}, {}
	for r, row in ipairs(self.cells) do
		local offsets, acc = {}, 0
		for c, ch in ipairs(row) do
			offsets[c] = acc
			acc = acc + #ch
		end
		offsets[#row + 1] = acc
		byte_offsets[r] = offsets
		lines[r] = table.concat(row)
	end

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	local ns = vim.api.nvim_create_namespace("startup")
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	for r, hls in ipairs(self.hls) do
		for _, hl in ipairs(hls) do
			if hl.to >= hl.from then
				vim.api.nvim_buf_set_extmark(buf, ns, r - 1, byte_offsets[r][hl.from], {
					end_col = byte_offsets[r][hl.to + 1],
					hl_group = hl.group,
				})
			end
		end
	end
end

return M
