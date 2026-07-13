local ui = require "lib.ui"
local sized = ui.widgets.sized

local ttextrasize = 5
---@type table<table, Tooltip>
local tts = {}

---@class Tooltip : Sized
local Tooltip = {
	x = 0,
	y = 0,
	z = 0,
	---@type Sized
	content = nil,
	parent = nil,
}

DEEP = DEEP or require "lib.uie.deep"

---@param o Tooltip
---@return Tooltip
function Tooltip:create(o)
	return setmetatable(o or {}, { __index = self })
end

function Tooltip:getSizeRaw()
	return self.content:getSizeRaw()
end

function Tooltip:globalUpdate(dt)
	local rem = {}
	for _, tt in pairs(tts) do
---@diagnostic disable-next-line: undefined-field
		if tt.content.update then tt.content:update(dt) end

		local tw, th = tt:getSizeRaw()

		local inr = ui.funcs.isPointInRect(Mouse.pos, { x = tt.x - ttextrasize, y = tt.y - ttextrasize }, tw + (ttextrasize * 2), th + (ttextrasize * 2))
		if not inr then
			table.insert(rem, tt)
		end
	end
	for _, value in pairs(rem) do
		table.removeItem(tts, value)
	end
end

function Tooltip:globalDraw()
	for _, tt in pairs(tts) do
		DEEP.queue(tt.z, function ()
			tt.content:draw(tt.x, tt.y)
		end)
	end
end


function Tooltip:options(opts)
	local tt = Tooltip:create{
		x = Mouse.pos.x,
		y = Mouse.pos.y,
	}

	local vbox = ui.container.Vertical:create{
		extraHeight = 2
	}

	for _, opt in pairs(opts) do
		vbox:addItem(ui.widgets.button.basicFromString(opt[1], opt[2]))
	end

	tt.content = ui.widgets.panel:wrapItem(vbox)
	table.insert(tts, tt)
end


return sized:new(Tooltip)--[[@as Tooltip]]