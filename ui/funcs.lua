local ret = {}

function ret.lerp(v0, v1, t)
    return v0 + t * (v1 - v0)
end

---@param p1 table x: number, y: number
---@param p2 table x: number, y: number
---@param width number
---@param height number
---@return boolean
function ret.isPointInRect(p1, p2, width, height)
	return (p1.x >= p2.x and p1.x <= p2.x + width)
		and (height > 0
			and (p1.y >= p2.y and p1.y <= p2.y + height)
			or (p1.y <= p2.y and p1.y - height >= p2.y))
end

---@param it Sized
---@param x? number
---@param y? number
---@return boolean
function ret.isMouseInSized(it, x, y)
	local w, h = it:getSizeRaw()
	return ret.isPointInRect(
		Mouse.pos,
---@diagnostic disable-next-line: undefined-field
		{ x = it.x or x or 0, y = it.y or y or 0 },
		w,
		h
	)
end

return ret