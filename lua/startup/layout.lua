local M = {}

-- Packs boxes left-to-right into rows that fit the screen width, then centers
-- each row horizontally and the whole block vertically.
function M.flow(boxes, width, height, gap)
	local rows = { { items = {}, width = 0, height = 0 } }
	for i, box in ipairs(boxes) do
		local row = rows[#rows]
		local needed = row.width + (#row.items > 0 and gap.x or 0) + box.width
		if #row.items > 0 and needed > width then
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
	for _, row in ipairs(rows) do
		local col = math.max(0, math.floor((width - row.width) / 2))
		for _, i in ipairs(row.items) do
			positions[i] = { row = top, col = col }
			col = col + boxes[i].width + gap.x
		end
		top = top + row.height + gap.y
	end
	return positions
end

return M
