local sized = require "widgets.sizedDrawable"

---@class Margin: Sized
local margin = {
    ---@type Sized
    content = nil,
    ---@type number
    top = 0,
    ---@type number
    bottom = 0,
    ---@type number
    left = 0,
    ---@type number
    right = 0,
}

---create a margin from an item
---@param it Sized
---@param t? number
---@param b? number
---@param l? number
---@param r? number
---@return Margin
function margin.fromItem(it, t, r, b, l)
    t = t or 0
    return margin:create({
        content = it,
        top = t,
        right = r or t,
        bottom = b or t,
        left = l or t,
    })
end

---create a new margin
---@param o Margin
---@return Margin
function margin:create(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function margin:getSizeRaw()
    local contentWidth, contentHeight = self.content:getSizeRaw()
    return contentWidth + self.left + self.right, contentHeight + self.top + self.bottom
end

function margin:draw(x, y)
	local w, h = self.content:getSizeRaw()
	-- love.graphics.rectangle("line", x + self.left, y + self.top, w, h)
    self.content:draw(x + self.left, y + self.top)
end

function margin:update(dt)
---@diagnostic disable-next-line: undefined-field
    if self.content.update then
---@diagnostic disable-next-line: undefined-field
        self.content:update(dt)
    end
end

function margin:release(p)
---@diagnostic disable-next-line: undefined-field
	if self.content.release then
---@diagnostic disable-next-line: undefined-field
		self.content:release(p)
	end
end

function margin:setContent(content)
    self.content = content
end

margin = sized:new(margin)

---@type Margin
return margin
