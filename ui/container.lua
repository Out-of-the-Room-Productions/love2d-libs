local sized = require "widgets.sizedDrawable"

---@class Container : Sized
local Container = setmetatable({
    items = nil;	---@type Sized[]
}, { __index = sized })
function Container:type() return "Container" end

function Container:addItem(item)
    table.insert(self.items, item)
end

function Container:drawbox()
	
end

function Container:update(dt)
    for _, s in ipairs(self.items) do
---@diagnostic disable-next-line: undefined-field
        if s.update then
---@diagnostic disable-next-line: undefined-field
            s:update(dt)
        end
    end
end

function Container:release(p)
	for _, it in ipairs(self.items) do
---@diagnostic disable-next-line: undefined-field
		if it.release then
---@diagnostic disable-next-line: undefined-field
			it:release(p)
		end
	end
end

---@class VerticalContainer : Container
local Vertical = setmetatable({
    center = false,
    extraHeight = 0.0,
}, { __index = Container })
function Vertical:type() return "VerticalContainer" end

---Create a new vertical container
---@return VerticalContainer
---@param o VerticalContainer
function Vertical:create(o)
    o = o or {}
	o.items = o.items or {}
    o.center = o.center or false
    o.extraHeight = o.extraHeight or 0
    return setmetatable(o, { __index = self })
end

function Vertical:getSizeRaw()
    local width, height = 0, 0
    for i, item in ipairs(self.items) do
        local itemWidth, itemHeight = item:getSizeRaw()
---@diagnostic disable-next-line: undefined-field
		itemHeight = math.max(item.minHeight or 0, itemHeight)
        width = math.max(width, itemWidth)
        height = height + itemHeight
        if i < #self.items then
            height = height + self.extraHeight
        end
    end
    return width, height
end

function Vertical:draw(x, y)
    local currentY = y
    local totalWidth, height = self:getSizeCooked()
	-- love.graphics.rectangle("line", x, y, totalWidth, height)
    for i, item in ipairs(self.items) do
        local itemWidth, itemHeight = item:getSizeCooked()
---@diagnostic disable-next-line: undefined-field
		itemHeight = math.max(item.minHeight or 0, itemHeight)
        local xPos = self.center and (x + ((totalWidth - itemWidth) * 0.5)) or x
        item:draw(xPos, currentY)
        currentY = currentY + itemHeight
        if i < #self.items then
            currentY = currentY + (self.extraHeight * UICTX.scale)
        end
    end
end

---@class HorizontalContainer : Container
local Horizontal = setmetatable({
    center = false,
	extraWidth = 0
}, { __index = Container })
function Horizontal:type() return "HorizontalContainer" end

---Create a new horizontal container
---@param o HorizontalContainer
---@return HorizontalContainer
function Horizontal:create(o)
    o = o or {}
	o.items = o.items or {}
    setmetatable(o, Horizontal)
    self.__index = self
    return o
end


function Horizontal:getSizeRaw()
    local width, height = 0, 0
    for _, item in ipairs(self.items) do
        local itemWidth, itemHeight = item:getSizeRaw()
---@diagnostic disable-next-line: undefined-field
		itemWidth = math.max(item.minWidth or 0, itemWidth)
        width = width + itemWidth + self.extraWidth
        height = math.max(height, itemHeight)
    end
    return width, height
end

function Horizontal:draw(x, y)
    local currentX = x
    local _, height = self:getSizeCooked()
    for _, item in ipairs(self.items) do
        local itemWidth, itemHeight = item:getSizeCooked()
---@diagnostic disable-next-line: undefined-field
		itemWidth = math.max(item.minWidth or 0, itemWidth)
        local yPos = self.center and (y + ((height - itemHeight) * 0.5)) or y
        item:draw(currentX, yPos)
        currentX = currentX + itemWidth + (self.extraWidth * UICTX.scale)
    end
end

---@class WrapContainer : Container
local Wrap = setmetatable({
    maxWidth = math.huge
}, { __index = Container })
function Wrap:type() return "WrapContainer" end

---Create a new WrapContainer
---@param maxWidth number The maximum width for the container
---@return WrapContainer
function Wrap:create(maxWidth)
	---@type WrapContainer
    local o = {}
	o.items = {}
    o.maxWidth = maxWidth
    setmetatable(o, Wrap)
    self.__index = self
    return o
end

function Wrap:getSizeRaw()
    local width, height = 0, 0
    local currentWidth, currentHeight = 0, 0

    for _, item in ipairs(self.items) do
        local itemWidth, itemHeight = item:getSizeRaw()

        if currentWidth + itemWidth <= self.maxWidth then
            currentWidth = currentWidth + itemWidth
            currentHeight = math.max(currentHeight, itemHeight)
        else
            width = math.max(width, currentWidth)
            height = height + currentHeight
            currentWidth = itemWidth
            currentHeight = itemHeight
        end
    end
    width = math.max(width, currentWidth)
    height = height + currentHeight
    return width, height
end

function Wrap:draw(x, y)
    local currentX, currentY = x, y
    local currentWidth, currentHeight = 0, 0
	local maxw = self.maxWidth * UICTX.scale
    for _, item in ipairs(self.items) do
        local itemWidth, itemHeight = item:getSizeCooked()
        if currentWidth + itemWidth <= maxw then
            item:draw(currentX, currentY)
            currentX = currentX + itemWidth
            currentWidth = currentWidth + itemWidth
            currentHeight = math.max(currentHeight, itemHeight)
        else
            currentX = x
            currentY = currentY + currentHeight
            currentWidth = itemWidth
            currentHeight = itemHeight
            item:draw(currentX, currentY)
            currentX = currentX + itemWidth
        end
    end
end

---@class GridContainer : Container
local Grid = setmetatable({
    rows = 0,
    cols = 0
}, { __index = Container })
function Grid:type() return "GridContainer" end

--- Create a new grid container
---@param rows number The number of rows in the grid
---@param cols number The number of columns in the grid
---@return GridContainer
function Grid:create(rows, cols)
    local o = {}
    o.rows = rows
    o.cols = cols
    setmetatable(o, Grid)
    self.__index = self
    return o
end

function Grid:getSizeRaw()
    local max_width, max_height = 0, 0
    local total_width, total_height = 0, 0
    for i, item in ipairs(self.items) do
        local width, height = item:getSizeRaw()
        max_width = math.max(max_width, width)
        max_height = math.max(max_height, height)
    end

    total_width = max_width * self.cols
    total_height = max_height * self.rows

    return total_width, total_height
end

function Grid:draw(x, y)
    local max_width, max_height = 0, 0
    for i, item in ipairs(self.items) do
        local width, height = item:getSizeCooked()
        max_width = math.max(max_width, width)
        max_height = math.max(max_height, height)
    end

    local row_height = max_height
    local col_width = max_width

    local cur_x, cur_y = x, y
    for i, item in ipairs(self.items) do
        local col = (i - 1) % self.cols
        local row = math.floor((i - 1) / self.cols)

        local width, height = item:getSizeCooked()
        local x_offset = (col_width - width) / 2
        local y_offset = (row_height - height) / 2

        item:draw(cur_x + col * col_width + x_offset, cur_y + row * row_height + y_offset)
    end
end

return {
    Vertical = Vertical;
    Horizontal = Horizontal;
    Wrap = Wrap;
    Grid = Grid;
}