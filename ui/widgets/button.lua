local Sized = require "widgets.sizedDrawable"
local text = require "widgets.text"
local nscl = require "nineSlice"
local funcs = require "funcs"
local layer = require "layer"
local style = require "style"

local ret = {}

local WIDTH = 100
local HEIGHT = 20
local GROWSPEED = 20

---@enum buttonState
ret.state = {
	normal = 1,
	hovered = 2,
	clicked = 3,
}

---@class Button : Sized
local Button = setmetatable({
	w			= WIDTH;
	h			= HEIGHT;
	content		= nil;				---@type Sized
	state		= ret.state.normal;	---@type buttonState
	---@protected
	lastPos		= { x = 0, y = 0 };
	onPress		= nil;				---@type fun()
	growAmt		= 0.0;
	---@private
	currentGrow = 0.0;
	---@private
	---@type NineSliceImage
	vis			= {};
	color		= style.Color.makeColor(1, 1, 1);
}, { __index = Sized })

function Button:draw(x, y)
	local r, g, b, a = CurrentStyle.buttonColors[self.state]:unwrap()
	love.graphics.setColor(
		r * self.color.r,
		g * self.color.g,
		b * self.color.b,
		a * self.color.a
	)

	self.vis:setSize(
		(self.w + self.currentGrow) * UICTX.scale,
		(self.h + self.currentGrow) * UICTX.scale
	)
	self.vis:draw(
		x - (self.currentGrow * .5 * UICTX.scale),
		y - (self.currentGrow * .5 * UICTX.scale)
	)

	self.lastPos.x, self.lastPos.y = x, y

	local wW, wH = self.content:getSizeCooked()
	self.content:draw(
		x + (((self.w * UICTX.scale) - wW) / 2),
		y + (((self.h * UICTX.scale) - wH) / 2),
		self.currentGrow			---@diagnostic disable-line: redundant-parameter
	)
	love.graphics.setColor(1, 1, 1, 1)
end

function Button:getSizeRaw()
	return self.w, self.h
end

function Button:update(dt)
	local x, y = self:getAnchorPos(self.lastPos.x, self.lastPos.y)
	local w, h = self:getAdjustedSize(self.w, self.h)
	if not funcs.isPointInRect(Mouse.pos, { x = x, y = y }, w, h) then
		if self.state ~= ret.state.normal then
			self.state = ret.state.normal
		end
		self.currentGrow = funcs.lerp(self.currentGrow, 0, dt * GROWSPEED)
		return
	end
	local md = Input:mouseDown(1)
	if not md and self.state == ret.state.normal then
		self.state = ret.state.hovered
	end

	if self.state == ret.state.hovered and md then
		self.state = ret.state.clicked
	end

	if self.state == ret.state.hovered then
		self.currentGrow = funcs.lerp(self.currentGrow, self.growAmt, dt * GROWSPEED)
	elseif self.state == ret.state.clicked then
		self.currentGrow = funcs.lerp(self.currentGrow, -self.growAmt, dt * GROWSPEED)
	end

	if self.state ~= ret.state.clicked or md then
		return
	end

	if self.onPress then
		self.onPress()
		Input:handleMouse()
	end
	self.state = ret.state.normal
end

---create a basic button
---@param btn Button
---@return Button
function ret.basic(btn, fun)
	btn = btn or {}
	btn.onPress = fun
---@diagnostic disable-next-line: invisible
	btn.lastPos = { x = 0, y = 0 }
	btn.w = btn.w or WIDTH
	btn.h = btn.h or HEIGHT
	btn.growAmt = btn.growAmt or 4
---@diagnostic disable-next-line: invisible
	btn.currentGrow = 0
---@diagnostic disable-next-line: invisible
	btn.vis = nscl:create({
		image = CurrentStyle.buttonImage,
		left = 4,
		top = 4,
		right = 4,
		bottom = 4
	})
---@diagnostic disable-next-line: invisible
	btn.vis:setSize(btn.w, btn.h)
	setmetatable(btn, { __index = Button })
	btn.__index = btn
	return btn
end

---create a button from a string
---@param str string
---@param fun function
---@param o Button?
---@return Button
function ret.basicFromString(str, fun, o)
	o = o or {}
	o.content = text.FText:fromString(str)
	return ret.basic(o, fun)
end


---@class ButtonImage : Sized
local Image = {
	---@type love.Texture
	image = nil,
	w = 0,
	h = 0,
	scale = 1.0,
	color = style.Color.makeColor(1, 1, 1, 1)
}

---@param im love.Texture
---@param i ButtonImage
---@return any
function Image:create(im, i)
	i = i or {}
	i.image = im
	return setmetatable(i, { __index = Image })
end

function Image:draw(x, y, grow)
	grow = grow or 0
	layer.Scissor:push(x + 2, y + 2, self.w - 4, self.h - 4, true)
	local iw, ih = self.image:getWidth(), self.image:getHeight()
	love.graphics.setColor(self.color:unwrap())
	love.graphics.draw(
		self.image,
		x + (iw * 0.5 * self.scale),
		y + (ih * 0.5 * self.scale),
		0,
		self.scale + (grow / iw * 2 * self.scale),
		self.scale + (grow / ih * 2 * self.scale),
		iw * 0.5,
		ih * 0.5
	)
	love.graphics.setColor(1, 1, 1, 1)
	layer.Scissor:pop()
end

function Image:getSizeRaw()
	return self.w, self.h
end

---@param im love.Texture
---@param fun function
---@param w? number
---@param h? number
---@param imScale? number
---@return Button
---@overload fun(im: love.Image, fn: fun())
function ret.newImageButton(im, w, h, imScale, fun)
	if type(w) == "function" then
		fun = w
		w = nil
	end
	local iw, ih = im:getWidth(), im:getHeight()
	w = w or iw
	h = h or ih
	imScale = imScale or math.min(w / iw, h / ih)
	return ret.basic({
		content = Image:create(im, {
			w = w,
			h = h,
			scale = imScale
		}),
		w = w,
		h = h
	}, fun)
end

---@param val boolean
---@return Color
local function getTickColor(val)
	return val and style.Color.makeColor(1, 0, 0, 1) or style.Color.makeColor(0, 0, 0, 0)
end

---@param binding Binding
---@param w? number
---@param h? number
---@return Button
function ret.newTickBox(binding, w, h)
	w = w or 16
	h = h or w
	local val = binding:get() --[[@as boolean]]
	local btn = ret.newImageButton(CurrentStyle.tickImage, nil, nil, nil, function () end)
	local im = btn.content --[[@as ButtonImage]]
	im.color = getTickColor(val)
	local oSet = binding.set
---@diagnostic disable-next-line: duplicate-set-field
	binding.set = function (self, val)
		oSet(self, val)
		im.color = getTickColor(val)
	end
	btn.onPress = function ()
		binding:set(not binding:get())
	end
	function btn:release(p)
---@diagnostic disable-next-line: undefined-field
		if binding.release then
---@diagnostic disable-next-line: undefined-field
			binding:release(p)
		end
	end
	return btn
end


return ret