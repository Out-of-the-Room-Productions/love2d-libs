local event = require "lib.event"

Mouse = {
    pos = {
        x = 0.0,
        y = 0.0
    },
	worldPos = {
		x = 0.0,
		y = 0.0
	},
	pdif = {
		xs = 0.0,
		ys = 0.0,
		x = 0.0,
		y = 0.0
	},
    scroll = 0.0,
	mainBtn = 1,
	mainDown = false,
	mainJustUp = false,
	mainUnhandled = false,

	secBtn = 2,
	secDown = false,
	secJustUp = false,
	secUnhandled = false,

	thBtn = 3,
	thDown = false,
	thJustUp = false,
	thUnhandled = false,
}
Input = {
	textBuffer = "",

	Events = {
		BufferChanged	= event:new(),
		KeyDown			= event:new(),
		KeyUp			= event:new(),

		Mouse = {
			MainDown	= event:new(),
			MainUp		= event:new()
		}
	}
}

---@param ev Event
---@param reg table
---@param key love.KeyConstant
---@param f fun()
local function regSpecKey(ev, reg, key, f)
	---@param k love.KeyConstant
	ev:register(reg, function (k)
		if k == key then
			f()
		end
	end)
end

---@param reg table
---@param key love.KeyConstant
---@param f fun()
function Input:registerKeyDown(reg, key, f)
	regSpecKey(self.Events.KeyDown, reg, key, f)
end

---@param reg table
---@param key love.KeyConstant
---@param f fun()
function Input:registerKeyUp(reg, key, f)
	regSpecKey(self.Events.KeyUp, reg, key, f)
end

function Input:mouseDown(b)
	-- TODO: make main/secondary changeable
	return love.mouse.isDown(b)
end

function Input:mouseJustUp(b)
	
end

---@param k love.KeyConstant
---@return boolean
function Input:isKeyDown(k)
	return love.keyboard.isDown(k)
end

function Input:update(dt)
	Mouse.pos.x, Mouse.pos.y = love.mouse.getPosition()

---@diagnostic disable-next-line: undefined-global
	if Camera then Mouse.worldPos.x, Mouse.worldPos.y = Camera:screenToWorld(Mouse.pos.x, Mouse.pos.y) end

	local mdb = Mouse.mainDown
	Mouse.mainUnhandled = Mouse.mainJustUp
	local md = love.mouse.isDown(Mouse.mainBtn)
	Mouse.mainJustUp = Mouse.mainDown and not md
	Mouse.mainDown = md
	if Mouse.mainUnhandled then
		self.Events.Mouse.MainUp(Mouse.worldPos.x, Mouse.worldPos.y)
	elseif not mdb and md then
		self.Events.Mouse.MainDown(Mouse.worldPos.x, Mouse.worldPos.y)
	end

	Mouse.secUnhandled = Mouse.secJustUp
	md = love.mouse.isDown(Mouse.secBtn)
	Mouse.secJustUp = Mouse.secDown and not md
	Mouse.secDown = md

	local sDownBefore = Mouse.thDown
	Mouse.thUnhandled = Mouse.thJustUp
	md = love.mouse.isDown(Mouse.thBtn)
	Mouse.thJustUp = Mouse.thDown and not md
	Mouse.thDown = md

	if not sDownBefore and Mouse.thDown then
		Mouse.pdif.xs, Mouse.pdif.ys = Mouse.pos.x, Mouse.pos.y
	end
	if Mouse.thDown then
		Mouse.pdif.x, Mouse.pdif.y = Mouse.pdif.xs - Mouse.pos.x, Mouse.pdif.ys - Mouse.pos.y
		Mouse.pdif.xs, Mouse.pdif.ys = Mouse.pos.x, Mouse.pos.y
	else
		Mouse.pdif.x, Mouse.pdif.y = 0, 0
	end
end

function Input:reset()
	Mouse.scroll = 0
end

function Input:handleMouse()
	Mouse.mainJustUp = false
end

function Input:handleSecondary()
	Mouse.secJustUp = false
end