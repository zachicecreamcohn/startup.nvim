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

-- Wraps widget content in a rounded border, returning a box of rows of cells.
function M.frame(content)
	local inner = 0
	for _, line in ipairs(content.lines) do
		inner = math.max(inner, vim.fn.strdisplaywidth(line))
	end

	local rows = { { cells = chars("╭" .. string.rep("─", inner + 2) .. "╮") } }
	for _, line in ipairs(content.lines) do
		local pad = string.rep(" ", inner - vim.fn.strdisplaywidth(line))
		rows[#rows + 1] = {
			cells = chars("│ " .. line .. pad .. " │"),
			hl = content.hl and { from = 3, to = 2 + #chars(line), group = content.hl },
		}
	end
	rows[#rows + 1] = { cells = chars("╰" .. string.rep("─", inner + 2) .. "╯") }

	return { rows = rows, width = inner + 4, height = #rows }
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
		local border_end = math.min(left + #row.cells, self.width)
		table.insert(self.hls[r], { from = left + 1, to = border_end, group = "StartupBorder" })
		if row.hl then
			table.insert(self.hls[r], {
				from = left + row.hl.from,
				to = math.min(left + row.hl.to, self.width),
				group = row.hl.group,
			})
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
