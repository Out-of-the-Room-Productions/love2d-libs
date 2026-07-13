local Sized = require "widgets.sizedDrawable"
local margin = require "widgets.margin"
local Style = require "style"
local nscl = require "nineSlice"

---@class Panel : Sized
local Panel = {
	w = 20,
	h = 20,
	---@private
	---@type NineSliceImage
	vis = nil,
	color = Style.Color.makeColor(1, 1, 1, 1),
	---@type Sized?
	content = nil
}
function Panel:type() return "Panel" end

---comment
---@param it Sized
---@param left? number
---@param right? number
---@param up? number
---@param down? number
---@return Panel
function Panel:wrapItem(it, left, right, up, down)
	left = left or 5
	right = right or left
	up = up or left
	down = down or left

	local mar = margin.fromItem(it, up, right, down, left)
	local w, h = mar:getSizeRaw()
	return Panel:create({
		content = mar,
		w = w,
		h = h
	})
end

function Panel:resize()
	self.w, self.h = self.content:getSizeRaw()
	self.vis:setSize(self.w, self.h)
end

---@param p Panel
---@return Panel
function Panel:create(p)
	local c = 5
	p = p or {}
	p.vis = p.vis or nscl:create({
		image = Style.getCurrentStyle().panelImage,
		left = c,
		top = c,
		right = c,
		bottom = c
	})
	setmetatable(p, { __index = Panel })
	p.vis:setSize(p.w, p.h)
	return p
end

function Panel:getSizeRaw()
	return self.w, self.h
end

---@param x integer
---@param y integer
function Panel:draw(x, y)
	love.graphics.setColor(self.color:unwrap())

	self.vis:draw(x, y)
	if self.content then
		self.content:draw(x, y)
	end
end

function Panel:update(dt)
---@diagnostic disable-next-line: undefined-field
	if self.content and self.content.update then
---@diagnostic disable-next-line: undefined-field
		self.content:update(dt)
	end
end

function Panel:release(p)
	---@diagnostic disable-next-line: undefined-field
		if self.content and self.content.release then
	---@diagnostic disable-next-line: undefined-field
			self.content:release(p)
		end
	end

return Panel