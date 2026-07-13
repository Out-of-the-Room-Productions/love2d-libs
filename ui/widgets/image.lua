local Sized = require "widgets.sizedDrawable"

---@class SizedImage : Sized
local SizedImage = {
	texture	= nil, ---@type love.Texture
	data	= nil, ---@type love.ImageData?
	width 	= 0.0,
	height 	= 0.0
}
function SizedImage:type() return "SizedImage" end

function SizedImage:new()
	return setmetatable({}, { __index = self })
end

---@param tex love.Texture
function SizedImage:setTexture(tex)
	self.texture 	= tex
	self.width		= self.texture:getWidth()
	self.height		= self.texture:getHeight()
end

---@param imdata love.ImageData
function SizedImage:setData(imdata)
	self.texture = nil
	self.data = imdata
end

function SizedImage:updateImage()
	if not self.data then
		error("cant update sized image without data")
	end
	local t = self.texture--[[@as love.Image]]
	if self.texture then
		t:replacePixels(self.data, 0, nil, nil, nil, false)
	else
		self.texture = love.graphics.newImage(self.data)
	end
end

---@param imdata love.ImageData
---@return SizedImage
function SizedImage:fromData(imdata)
	local ins = self:new()
	ins:setData(imdata)
	return ins
end

function SizedImage:getSizeRaw()
	return self.width, self.height
end

function SizedImage:draw(x, y)
	if not self.texture then
		if self.data then
			self:updateImage()
		else
			return
		end
	end
	love.graphics.draw(self.texture, x, y)
end

return SizedImage