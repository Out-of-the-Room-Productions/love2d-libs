---@class CenterBox : Sized
local CenterBox = {
	---@type Sized
	content = nil,
	w = 0,
	h = 0
}

---@param b CenterBox
---@return CenterBox
function CenterBox:create(b)
	return setmetatable(b or {}, { __index = CenterBox })
end

---@param s Sized
---@param w number?
---@param h number?
---@return CenterBox
function CenterBox:wrap(s, w, h)
	local iw, ih = s:getSizeRaw();
	return self:create {
		content = s;
		w = w or iw;
		h = h or ih;
	}
end

function CenterBox:draw(x, y)
	if not self.content then
		return
	end
	local cw, ch = self.content:getSizeCooked()
	-- love.graphics.rectangle("line", x, y, self.w, self.h)
	self.content:draw(
		x + ((self.w - cw) * 0.5),
		y + ((self.h - ch) * 0.5)
	)
end

function CenterBox:getSizeRaw()
	return self.w, self.h
end

function CenterBox:update(dt)
---@diagnostic disable-next-line: undefined-field
	if self.content and self.content.update then
---@diagnostic disable-next-line: undefined-field
		self.content:update(dt)
	end
end

return CenterBox