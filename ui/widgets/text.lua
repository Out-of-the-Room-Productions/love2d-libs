local Sized = require "widgets.sizedDrawable"
local Style = require "style"

---@class FWord : Sized
local FWord = {
    newline = false,
    content = "",
    ---@type love.Font?
    font = nil,
    ---@type table Color
    rgba = {},
}
function FWord:type() return "FWord" end



---create a new FWord
---@param w FWord
---@return FWord
function FWord:create(w)
    w = w or {}
    setmetatable(w, { __index = FWord })
    setmetatable(self.rgba, { __index = Style.Color.makeColor() })
    self.__index = self
    return w
end

---get and cache the word's font
---@return love.Font
function FWord:getFont()
    self.font = self.font or CurrentStyle.font
    return self.font
end

---change word color
---@param r number
---@param g number
---@param b number
---@param a? number
function FWord:setColor(r, g, b, a)
    self.rgba = Style.Color.makeColor(r, g, b, a)
end

function FWord:getColor()
    self.rgba = self.rgba or Style.Color.makeColor()
    return self.rgba
end

---@param self FWord
function FWord:getSizeRaw()
    self.font = self:getFont()
	-- print(self.content)
    self.w = self.w or self.font:getWidth(self.content)
    self.h = self.h or self.font:getHeight()
    return self.w, self.h
end

function FWord:setDirty()
	self.w = nil
	self.h = nil
end

---create a word from a string
---@param s string
---@return FWord
function FWord:fromString(s)
	if type(s) ~= "string" then
		s = tostring(s)
	end
    local w = FWord:create{}
    if s:sub(1, 1) == "\n" then
        s = s:sub(2)
        w.newline = true
    end
    w.content = s
    return w
end

function FWord:draw(x, y, grow)
    love.graphics.setColor(self.rgba.r, self.rgba.g, self.rgba.b, self.rgba.a)
    love.graphics.setFont(self:getFont())
    love.graphics.print(self.content, x, y, 0, UICTX.scale, UICTX.scale)
end


---@class FText: Sized
local FText = {
    ---@type FWord[]
    content = {},
    ---@type number
    w = math.huge,
    ---@private
    spaceSize = love.graphics.getFont():getWidth(" "),
}

function FText:type() return "FText" end

---create a new FText
---@param w FText
---@return FText
function FText:create(w)
    w = w or {}
    setmetatable(w, FText)
    self.__index = self
    return w
end

function FText:getSizeRaw()
    local availableW = self.w or math.huge
    local totalH, totalW, currentH, currentW = 0, 0, 0, 0
    for i, value in ipairs(self.content) do
        local vW, vH = value:getSizeRaw()
        currentH = math.max(currentH, vH)

        if value.newline or currentW + vW > availableW then
            totalW = math.max(totalW, currentW)
            totalH = totalH + currentH
            currentW = 0
        end

        currentW = currentW + vW + self.spaceSize
    end

    totalW = math.max(totalW, currentW)
    totalH = totalH + currentH

    return totalW, totalH
end

function FText:draw(x, y)
    local currentX, currentY = x, y
    local availableW = (self.w or math.huge) * UICTX.scale

    for _, w in ipairs(self.content) do
        local wordW, wordH = w:getSizeCooked()

        if w.newline or currentX + wordW - x > availableW then
            currentX = x
            currentY = currentY + wordH
        end

        w:draw(currentX, currentY)
        currentX = currentX + wordW + self.spaceSize
    end
end

function FText:fromString(str, w)
    w = w or math.huge
    local words = {}
    for cStr in str:gmatch("[^ ]+") do
        table.insert(words, FWord:fromString(cStr))
    end
    local ftext = FText:create({content = words, w = w})
    return ftext
end

function FText:addWord(w)
    table.insert(self.content, w)
end

---comment
---@param r number
---@param g number
---@param b number
---@param a? number
function FText:setColor(r, g, b, a)
    local clr = Style.Color.makeColor(r, g, b, a)
    for _, w in ipairs(self.content) do
        w.rgba = clr
    end
end

--- Implement the __add metamethod to combine FWord instances into an FText instance
---@param a FWord
---@param b FWord
---@return FText
function FWord.__add(a, b)
    return FText:create({content = {a, b}})
end

--- Implement the __add metamethod to combine FText instances
---@param a FText
---@param b FText|FWord
---@return FText
function FText.__add(a, b)
    local newText = a
    if type(b) == "table" and getmetatable(b) == FWord then
        a:addWord(b)
    elseif type(b) == "table" and getmetatable(b) == FText then
        --[[for _, w in ipairs(a.content) do
            newText:addWord(w)
        end]]
---@diagnostic disable-next-line: param-type-mismatch
        for _, w in ipairs(b.content) do
            newText:addWord(w)
        end
    else
        error("Invalid operand for FText + operator")
    end
    return newText
end

return {
    FText = Sized:new(FText) --[[@as FText]],
    FWord = Sized:new(FWord) --[[@as FWord]],
}