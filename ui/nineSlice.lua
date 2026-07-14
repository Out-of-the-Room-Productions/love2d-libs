local sized = require "widgets.sizedDrawable"

---@class NineSliceImage : Sized
local nineSliceImage = {
    ---@type love.Image
    image = nil,
    ---@type number
    left = 0,
    ---@type number
    top = 0,
    ---@type number
    right = 0,
    ---@type number
    bottom = 0,
    ---@type number?
    width = nil,
    ---@type number?
    height = nil,
    ---@type table<string, love.Quad>
    quads = {}
}

function nineSliceImage.type() return "NineSliceImage" end

--- Constructor
---@param o NineSliceImage
---@return NineSliceImage
function nineSliceImage:create(o)
    o = o or {}
    local imW, imH = o.image:getDimensions()
    o.width = o.width or imW
    o.height = o.height or imH
    o.quads = {
        topLeft = love.graphics.newQuad(0, 0, o.left, o.top, imW, imH),
        topRight = love.graphics.newQuad(imW - o.right, 0, o.right, o.top, imW, imH),
        bottomLeft = love.graphics.newQuad(0, imH - o.bottom, o.left, o.bottom, imW, imH),
        bottomRight = love.graphics.newQuad(imW - o.right, imH - o.bottom, o.right, o.bottom, imW, imH),

        left = love.graphics.newQuad(0, o.top, o.left, imH - o.top - o.bottom, imW, imH),
        right = love.graphics.newQuad(imW - o.right, o.top, o.right, imH - o.top - o.bottom, imW, imH),
        top = love.graphics.newQuad(o.left, 0, imW - o.left - o.right, o.top, imW, imH),
        bottom = love.graphics.newQuad(o.left, imH - o.bottom, imW - o.left - o.right, o.bottom, imW, imH),

        center = love.graphics.newQuad(o.left, o.top, imW - o.left - o.right, imH - o.top - o.bottom, imW, imH),
    }

    o = setmetatable(o, { __index = self })
    return o
end

function nineSliceImage:setSize(x, y)
    self.width, self.height = x, y
end

function nineSliceImage:draw(x, y)
    local cW, cH = 0.0, 0.0
    love.graphics.draw(self.image, self.quads.topLeft, x, y)
    love.graphics.draw(self.image, self.quads.topRight, x + self.width - self.right, y)
    love.graphics.draw(self.image, self.quads.bottomLeft, x, y + self.height - self.bottom)
    love.graphics.draw(self.image, self.quads.bottomRight, x + self.width - self.right, y + self.height - self.bottom)

    _, _, cW, cH = self.quads.center:getViewport()
    cW = (1 / cW) * (self.width - self.left - self.right)
    cH = (1 / cH) * (self.height - self.top - self.bottom)
    love.graphics.draw(self.image, self.quads.left, x, y + self.top, 0, 1, cH)
    love.graphics.draw(self.image, self.quads.right, x + self.width - self.right, y + self.top, 0, 1, cH)
    love.graphics.draw(self.image, self.quads.top, x + self.left, y, 0, cW, 1)
    love.graphics.draw(self.image, self.quads.bottom, x + self.left, y + self.height - self.bottom, 0, cW, 1)

    love.graphics.draw(self.image, self.quads.center, x + self.left, y + self.top, 0, cW, cH)
end

return sized:new(nineSliceImage) --[[@as NineSliceImage]]