local sized = require "widgets.sizedDrawable"
local funcs = require "funcs"

local scissor = {
    stack = {},
}

local function pack(...)
    return {...}
end

---@param x number
---@param y number
---@param w number
---@param h number
---@param i? boolean
function scissor:push(x, y, w, h, i)
    table.insert(self.stack, pack(love.graphics.getScissor()))
	if i then
		love.graphics.intersectScissor(x, y, w, h)
	else
		love.graphics.setScissor(x, y, w, h)
	end
end
function scissor:pop()
    local x, y, w, h = unpack(self.stack[#self.stack])
    table.remove(self.stack)
    love.graphics.setScissor(x, y, w, h)
end

---@class LayerItem
local LayerItem = {
    x = 0,
    y = 0,
    ---@type Sized
    item = nil
}
function LayerItem.type() return "LayerItem" end

---comment
---@param o Sized
---@return LayerItem
function LayerItem:fromSized(o)
    local i = {}
    setmetatable(i, LayerItem)
    self.__index = self
    i.item = o
    return i
end

---@class Layer : Sized
local Layer = {
    items = {};	---@type LayerItem[]
    w = nil;	---@type number?
    h = nil;	---@type number?

	doscissor = true;
}
function Layer.type() return "Layer" end

function Layer:new(o)
    o = o or {}
    setmetatable(o, { __index = self })
    return o
end

---@param o Layer
---@return Layer
function Layer:create(o)
    o = o or {}
    o.items = o.items or {}
    setmetatable(o, { __index = self })
    return o
end

---@protected
function Layer:drawItems(x, y)
    for _, it in ipairs(self.items) do
        it.item:draw(x + it.x, y + it.y)
    end
end

---@param x integer
---@param y integer
function Layer:draw(x, y)
    if self.doscissor and self.w and self.h then
        scissor:push(x, y, self.w, self.h)
    end

    self:drawItems(x, y)

    if self.doscissor and self.w and self.h then
        scissor:pop()
    end
end

---@protected
function Layer:updateItems(dt)
    for _, it in ipairs(self.items) do
---@diagnostic disable-next-line: undefined-field
        if it.item.update then
---@diagnostic disable-next-line: undefined-field
            it.item:update(dt)
        end
    end
end

function Layer:update(dt)
    self:updateItems(dt)
end

function Layer:release(p)
	for _, it in ipairs(self.items) do
---@diagnostic disable-next-line: undefined-field
		if it.item.release then it.item:release(p) end
	end
end

---@param it Sized
---@param x? number
---@param y? number
function Layer:addItem(it, x, y)
    local li = LayerItem:fromSized(it)
    li.x = x or 0
    li.y = y or 0
    table.insert(self.items, li)
end

function Layer:getSizeRaw()
    local width = 0
    local height = 0

    for _, it in ipairs(self.items) do
        local itemWidth, itemHeight = it.item:getSizeRaw()
        width = math.max(width, it.x + itemWidth)
        height = math.max(height, it.y + itemHeight)
    end

	if self.w then
---@diagnostic disable-next-line: cast-local-type
		width = math.max(self.w, width)
	end
	if self.h then
---@diagnostic disable-next-line: cast-local-type
		height = math.max(self.h, height)
	end

    return width, height
end

---@class ScrollLayer: Layer
local Scroll = {
    ---@type ScrollDirection?
    dir = nil,
    position = 0,
    target = 0,
    scrollBarWidth = 10,
    lastPos = {x = 0, y = 0},
}

---@enum ScrollDirection
Scroll.Direction = {
    vertical = 0,
    horizontal = 1,
}

---create a new scroll layer
---@param o ScrollLayer
---@return ScrollLayer
function Scroll:create(o)
    o = o or {}
    o.items = o.items or {}
    o.dir = o.dir or self.Direction.vertical
    o.scrollBarWidth = o.scrollBarWidth or 10
    o.position = o.position or 0
    o.target = o.target or 0
    o.lastPos = { x = 0, y = 0 }
    setmetatable(o, Scroll)
    self.__index = self
    return o
end

function Scroll:update(dt)
    self:updateItems(dt)
    self:scroll(Mouse.scroll)

    self.position = funcs.lerp(self.position, self.target, 10 * dt)
end

function Scroll:scroll(amt)
    if not funcs.isPointInRect(Mouse.pos, self.lastPos, self.w, self.h) then
        return
    end

    self.target = self.target - (amt * 15)
    -- consume scroll, so not everything scrolls (only most inner should scroll)
    Mouse.scroll = 0
end

function Scroll:draw(x, y)
    self.lastPos.x, self.lastPos.y = x, y
    -- Calculate the size of the scrollbar track
    local trackSize
    local contentWidth, contentHeight = self:getSizeCooked()
    if self.dir == Scroll.Direction.vertical then
        trackSize = self.h
    else
        trackSize = self.w
    end

    -- Calculate the size of the scrollbar based on the visible content and total content
    local visibleContent
    if self.dir == Scroll.Direction.vertical then
        visibleContent = self.h
    else
        visibleContent = self.w
    end
    local totalContent
    if self.dir == Scroll.Direction.vertical then
        totalContent = contentHeight
    else
        totalContent = contentWidth
    end
    local scrollbarSize = trackSize * (visibleContent / totalContent)

    -- Calculate the position of the scrollbar thumb based on the scroll position
    local thumbPos = self.position / totalContent * trackSize

    -- Determine the maximum scroll position
    local maxScrollPos
    if self.dir == self.Direction.vertical then
        maxScrollPos = contentHeight - self.h
    else
        maxScrollPos = contentWidth - self.w
    end

    -- Clamp the scroll position to prevent scrolling past the content boundaries
    self.target = math.max(0, math.min(self.target, maxScrollPos))
    self.position = math.max(0, math.min(self.position, maxScrollPos))

    -- Draw the scrollbar track
    love.graphics.setColor(0.5, 0.5, 0.5, 0.2)
    if self.dir == Scroll.Direction.vertical then
        love.graphics.rectangle("fill", x + self.w - self.scrollBarWidth, y, self.scrollBarWidth, self.h)
    else
        love.graphics.rectangle("fill", x, y + self.h - self.scrollBarWidth, self.w, self.scrollBarWidth)
    end

    -- Draw the scrollbar thumb
    love.graphics.setColor(0, 0, 0, 0.8)
    if self.dir == Scroll.Direction.vertical then
        love.graphics.rectangle("fill", x + self.w - self.scrollBarWidth, y + thumbPos, self.scrollBarWidth, scrollbarSize)
    else
        love.graphics.rectangle("fill", x + thumbPos, y + self.h - self.scrollBarWidth, scrollbarSize, self.scrollBarWidth)
    end

    if self.w and self.h then
        if self.dir == Scroll.Direction.vertical then
            scissor:push(x, y, self.w, self.h)
        else
            scissor:push(x, y, self.w, self.h)
        end
    end

    -- Draw the layer content
    if self.dir == Scroll.Direction.vertical then
        self:drawItems(x, y - self.position)
    else
        self:drawItems(x - self.position, y)
    end

    if self.w and self.h then
        scissor:pop()
    end
	love.graphics.setColor(1, 1, 1)
end

function Scroll:setPosition(offset)
    self.position = offset
end

function Scroll:getSizeRaw()
	local cW, cH = Layer.getSizeRaw(self)
	return self.w or cW, self.h or cH
end

---@class LayerRet
local ret = {
    Layer = sized:new(Layer) --[[@as Layer]];
    Scroll = Layer:new(Scroll) --[[@as ScrollLayer]];
    Scissor = scissor;
	---@param self LayerRet
	---@param o Layer
	---@return Layer
	new = function(self, o)
		return self.Layer:new(o)
	end
}
return ret