---@type Style
CurrentStyle = CurrentStyle or {}

---@class Color
local color = {
    r = 1.0,
    g = 1.0,
    b = 1.0,
    a = 1.0
}

---make a new color
---@param r number?
---@param g number?
---@param b number?
---@param a number?
---@return Color
function color.makeColor(r, g, b, a)
    local c = {
        r = r,
        g = g,
        b = b,
        a = a
    }
    setmetatable(c, { __index = color })
    c.__index = c
    return c
end

function color.pack(t)
    return color.makeColor(t[1] or 1, t[2] or 1, t[3] or 1, t[4] or 1)
end

---@return number r
---@return number g
---@return number b
---@return number a
function color:unwrap()
    return self.r or 1, self.g or 1, self.b or 1, self.a or 1
end

---@param html string
---@return Color
function color.html(html)
    if html:sub(1, 1) == "#" then
        html = html:sub(2)
    end

    local l = html:len()
    if l < 6 then
        error("html color too short: "..html)
    end
    local t = {}
    for i = 1, l, 2 do
        local s = html:sub(i, i + 1)
        local n = tonumber(s, 16) / 256.0
        table.insert(t, n)
    end
    return color.pack(t)
end

---@class Style
local Style = {
	---@type love.Font?
    font = love.graphics.getFont(),
	---@type Color[]?
    buttonColors = {
        color.makeColor(0.3, 0.3, 0.3),
        color.makeColor(0.5, 0.5, 0.5),
        color.makeColor(0.15, 0.15, 0.15)
    },
    ---@type love.Image?
    buttonImage = nil,
	---@type love.Image?
	panelImage = nil,
	---@type love.Image?
	entryImage = nil,
	---@type love.Image?
	tickImage = nil,
	---@type love.Image?
	arrowImage = nil,
	---@type love.Image?
	tabImage = nil,
}

---create a new style
---@param o Style
---@return Style
function Style:new(o)
    o = o or {}
    setmetatable(o, { __index = Style })
    self.__index = self
    return o
end

return {
	---@param o Style
	---@return Style
	new = function(o)
		return Style:new(o)
	end,
    ---@type Style
    Default = Style,
    Color = color,
	getCurrentStyle = function() return CurrentStyle end
}
