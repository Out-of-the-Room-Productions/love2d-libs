local layer = require "layer"

---@class Screen
local Screen = {
	stack = "",
	---@type Layer
	layer = nil,
	---@type fun(self: Screen, o: Screen): Screen
	setup = function(self, o) error("override setup function for ui!") end,
	---@type fun(self: Screen, dt: number)
	update = function(self, dt) self.layer:update(dt) end,
	---@type fun(self: Screen)
	draw = function(self) self.layer:draw(0, 0) end,
	---@type fun(self: Screen, w: integer, h: integer)
	resize = function(self, w, h) end,
	---@type fun(self: Screen, permanent: boolean)
	release = function(self, permanent) self.layer:release(permanent) end,
	---@type fun(self: Screen, new: boolean)
	show = function(self, new) end
}

---@class ScreenStack
local ScreenStack = {
	zLevel = 0,
	---@type Screen[]
	values = {}
}
function ScreenStack:new(o)
	o = o or {}
	o.values = o.values or {}
	setmetatable(o, { __index = ScreenStack })
	self.__index = self
	return o
end

function ScreenStack:push(scr)
	local t = self:getTop()
	if t then
		-- release, but only hide
		t:release(false)
	end
	table.insert(self.values, scr)
	-- true, because the ui is new
	scr:show(true)
end
function ScreenStack:pop()
	local t = self:getTop()
	if t then
		t:release(true)
	end

	table.remove(self.values)
	if #self.values > 0 then
		self:getTop():show(false)
	end
end

function ScreenStack:resize(w, h)
	for _, scr in pairs(self.values) do
		scr:resize(w, h)
	end
end

---get the top of the stack
---@return Screen
function ScreenStack:getTop()
	return self.values[#self.values]
end

local UI_STACKS = {
	---@type ScreenStack[]
	values = {},
	main = ""
}

function UI_STACKS:refresh()
	table.sort(self.values, function (a, b)
		return a.zLevel > b.zLevel
	end)
end

function UI_STACKS:initStack(name, zLevel)
	if not zLevel then zLevel = 0 end
	self.values[name] = ScreenStack:new({
		zLevel = zLevel
	})
end

---push and exisitng screen to a stack
---@param scr Screen
---@param name? string
function UI_STACKS:pushScreen(scr, name)
	name = name or self.main
	scr.stack = name
	if not self.values[name] then self.values[name] = ScreenStack:new({}) end
	self.values[name]:push(scr)
	self:refresh()
end

---@param scr Screen
---@param name? string
---@param args? table The arguments for the screen's setup
function UI_STACKS:push(scr, name, args)
	self:pushScreen(scr:setup(args or {}), name)
end

---@see Screen.replace
---@param scr Screen Pre-setup screen
---@param name? string
function UI_STACKS:replaceScreen(scr, name)
	name = name or self.main
	self:pop(name)
	self:pushScreen(scr, name)
end

---comment
---@param scr Screen Non-setup screen
---@param name? string
---@param args? table Screen argunemts
function UI_STACKS:replace(scr, name, args)
	self:replaceScreen(scr:setup(args or {}))
end

function UI_STACKS:pop(name)
	local st = self.values[name]
	if not st then return end

	st:pop()
	if #st.values == 0 then
		self.values[name] = nil
	end
	self:refresh()
end

function UI_STACKS:resize(w, h)
	for _, scr in pairs(self.values) do
		scr:resize(w, h)
	end
end

function UI_STACKS:update(dt)
	--todo: reverse order
	for _, scr in pairs(self.values) do
		scr:getTop():update(dt)
	end
end

function UI_STACKS:draw()
	for _, scr in pairs(self.values) do
		scr:getTop():draw()
	end
end

---create a new screen from a table
---@param o Screen
---@return Screen
function Screen:new(o)
	o = o or {}
	o.stack = ""
	o.layer = layer.Layer:create{}
	setmetatable(o, { __index = self })
	return o
end

---@protected
---push a new screen onto the current stack/selected stack
---@param scr Screen
---@param st? string
function Screen:push(scr, st)
	st = st or self.stack
	UI_STACKS:push(scr, st)
end

---@protected
function Screen:pop()
	UI_STACKS:pop(self.stack)
end

---@protected
---pop the current stack, then push to the current stack, functionally replacing the current screen
---@param scr Screen
function Screen:replace(scr)
	self:pop()
	self:push(scr)
end

return {
	---@type Screen
	Screen = Screen,
	Stacks = UI_STACKS,
}