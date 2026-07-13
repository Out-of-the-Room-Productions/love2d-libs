local ui = require "lib.ui"
local sized = ui.widgets.sized
local nscl  = ui.nineSlice
local text  = ui.widgets.text
local style = ui.style
local funcs = ui.funcs

---@class TextEntry : Sized, Focusable
local TextEntry = {
	---@private
	---@type Binding
	binding = nil,
	w = 100,
	mx = 4,
	my = 5,
	---@type FWord
	text = nil,
	---@type love.Font
	font = nil,
	---@private
	---@type boolean
	focus = false,
	---@private
	---@type NineSliceImage
	vis = nil,
	---@private
	animTime = 0.0,
	---@private
	lastPos = { x = 0, y = 0},
	---@type fun(text: string)?
	onAccept = nil
}

function TextEntry:getSizeRaw()
	return self.w + (self.mx * 2), self.font:getHeight() + (self.my * 2)
end

function TextEntry:draw(x, y)
	self.lastPos.x, self.lastPos.y = x, y
	self.vis:draw(x, y)
	self.text:draw(x + self.mx, y + self.my)

	local tw, th = self.text:getSizeRaw()

	if self.focus and math.sin(self.animTime) >= 0 then
		love.graphics.rectangle("fill", x + self.mx + tw + 1, y + self.my, 2, th)
	end
end

---@param key love.KeyConstant
function TextEntry:keyUp(key)
	if key == "return" and self.onAccept then
		self.onAccept(self.text.content)
	end
end

---@param focus boolean
function TextEntry:setFocus(focus)
	print("setting focus ", focus)
	self.focus = focus
	if focus then
		Input.textBuffer = self.text.content
		self:register()
		self.animTime = 0
	else
		self:unregister()
	end
end

function TextEntry:register()
	Input.Events.BufferChanged:register(self, function ()
		self.text.content = Input.textBuffer
		self.text:setDirty()
		self.binding:set(self.text.content)
	end)
	Input.Events.KeyUp:register_wrapped(self, self.keyUp)
end

function TextEntry:unregister()
	Input.Events.BufferChanged:unregister(self)
	Input.Events.KeyUp:unregister(self)
end

function TextEntry:update(dt)
	-- see if should gain focus
	local mouseOver = funcs.isPointInRect(Mouse.pos, self.lastPos, self:getSizeRaw())
	local md = Input:mouseDown(1)
	self.animTime = self.animTime + (dt * 5)

	if not self.focus and mouseOver and md then
		ui:setFocus(self)
	elseif self.focus and not mouseOver and md then
		ui:unsetFocus(self)
	end

	if mouseOver and Mouse.mainJustUp then
		Input:handleMouse()
	end

	if not self.focus then
		return
	end
end

function TextEntry:release(p)
	if not self.focus then
		return
	end

	self:unregister()
end

---@param t table
---@param path string
---@param r? boolean is row
---@param n? boolean is number
---@return Sized
function TextEntry:simple(t, path, r, n)
	local b = ui.binding:create(t, path)
	local e = self:create{
		binding = n and b:forceNumber() or b
	}
	return r and ui.util.row(path, e) or e
end

---@param t TextEntry
---@return TextEntry
function TextEntry:create(t)
	t = t or {}
	t.animTime = 0.0
	t.lastPos = { x = 0, y = 0 }
	t.binding = t.binding or error("entry has no binding")
	t.font = t.font or love.graphics.getFont()
	t.text = text.FWord:create({
		font = t.font,
		content = t.binding:get()
	})
	setmetatable(t, { __index = TextEntry })

	local w, h = t:getSizeRaw()
	t.vis = nscl:create({
		image = style.getCurrentStyle().entryImage,
		left = 2,
		right = 2,
		top = 2,
		bottom = 2,
		width = w,
		height = h,
	})
	return t
end

return sized:new(TextEntry) --[[@as TextEntry]]