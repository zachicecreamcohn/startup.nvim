local M = {}

-- Packs boxes left-to-right into rows no wider than wrap_width (gap.x is the
-- minimum horizontal spacing), then spreads each row's boxes across wrap_width
-- like flexbox space-between. The wrap_width container and the whole block are
-- centered on screen; a row with a single box is centered.
function M.flow(boxes, width, height, gap, wrap_width)
	wrap_width = math.min(wrap_width or width, width)
	local rows = { { items = {}, width = 0, height = 0 } }
	for i, box in ipairs(boxes) do
		local row = rows[#rows]
		local needed = row.width + (#row.items > 0 and gap.x or 0) + box.width
		if #row.items > 0 and needed > wrap_width then
			row = { items = {}, width = 0, height = 0 }
			rows[#rows + 1] = row
		end
		row.width = row.width + (#row.items > 0 and gap.x or 0) + box.width
		row.height = math.max(row.height, box.height)
		row.items[#row.items + 1] = i
	end

	local total_height = (#rows - 1) * gap.y
	for _, row in ipairs(rows) do
		total_height = total_height + row.height
	end

	local positions = {}
	local top = math.max(0, math.floor((height - total_height) / 2))
	local container_left = math.floor((width - wrap_width) / 2)
	for _, row in ipairs(rows) do
		local n = #row.items
		if n == 1 then
			local i = row.items[1]
			positions[i] = { row = top, col = math.max(0, math.floor((width - boxes[i].width) / 2)) }
		else
			local content = row.width - (n - 1) * gap.x
			local free = math.max(0, wrap_width - content)
			local col = container_left
			for k, i in ipairs(row.items) do
				positions[i] = { row = top, col = col }
				-- Spread the remainder over the first gaps so spacing differs by at most 1.
				local spacing = math.floor(free / (n - 1)) + (k <= free % (n - 1) and 1 or 0)
				col = col + boxes[i].width + spacing
			end
		end
		top = top + row.height + gap.y
	end
	return positions
end

return M
