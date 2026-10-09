local M = {}

-- Splits `total` into `n` integer parts that differ by at most 1.
local function share(total, n, k)
	return math.floor(total / n) + (k <= total % n and 1 or 0)
end

-- Packs boxes left-to-right into rows no wider than wrap_width (gap.x is the
-- minimum horizontal spacing), then positions each row within a wrap_width
-- container centered on screen:
--   * boxes with fill_width grow to absorb the row's free space (like flex-grow),
--     leaving exactly gap.x between boxes;
--   * otherwise boxes spread like flexbox space-between, and a lone box is centered.
-- Boxes with fill_height stretch to their row's tallest box.
-- Returns, per box, { row, col, width, height } with the box's final size.
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
		local free = math.max(0, wrap_width - row.width)
		local growers = 0
		for _, i in ipairs(row.items) do
			if boxes[i].fill_width then
				growers = growers + 1
			end
		end

		local function place(i, col, w)
			local box = boxes[i]
			positions[i] = {
				row = top,
				col = col,
				width = w,
				height = box.fill_height and row.height or box.height,
			}
		end

		if growers > 0 then
			local col, grower = container_left, 0
			for _, i in ipairs(row.items) do
				local w = boxes[i].width
				if boxes[i].fill_width then
					grower = grower + 1
					w = w + share(free, growers, grower)
				end
				place(i, col, w)
				col = col + w + gap.x
			end
		elseif n == 1 then
			local i = row.items[1]
			place(i, math.max(0, math.floor((width - boxes[i].width) / 2)), boxes[i].width)
		else
			-- Free space plus the minimum gaps, redistributed evenly between boxes.
			local spread = free + (n - 1) * gap.x
			local col = container_left
			for k, i in ipairs(row.items) do
				place(i, col, boxes[i].width)
				col = col + boxes[i].width + share(spread, n - 1, k)
			end
		end
		top = top + row.height + gap.y
	end
	return positions
end

return M
