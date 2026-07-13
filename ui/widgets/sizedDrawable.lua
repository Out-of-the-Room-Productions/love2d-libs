---@enum UIAnchor
UIAnchor = {
	TopLeft		= 0,
	TopRight	= 1,
	BottomLeft	= 2,
	BottomRight	= 3,
	Center		= 4
}

---@class Sized
local Sized = {
	anchor = UIAnchor.TopLeft
}

function Sized:new(o)
    o = o or {}
    return setmetatable(o, { __index = self })
end

function Sized:type()
    return "Sized"
end

---@return integer width
---@return integer height
function Sized:getSizeRaw()
    error("overload 'getSizeRaw' for " .. self:type())
    return 0, 0
end

function Sized:getSizeCooked()
	local w, h = self:getSizeRaw()
	return w * UICTX.scale, h * UICTX.scale
end

function Sized:getAdjustedSize(w, h)
	return w * UICTX.scale, h * UICTX.scale
end

---@type table<integer, fun(d:Sized,x:number,y:number):number, number>
local anchor_funcs = {
	[UIAnchor.TopLeft] = function (d, x, y)
		return x, y
	end;
	[UIAnchor.TopRight] = function (d, x, y)
		local w, _ = d:getSizeCooked()
		return x - w, y
	end,
	[UIAnchor.BottomLeft] = function (d, x, y)
		local _, h = d:getSizeCooked()
		return x, y - h
	end,
	[UIAnchor.BottomRight] = function (d, x, y)
		local w, h = d:getSizeCooked()
		return x - w, y - h
	end,
	[UIAnchor.Center] = function (d, x, y)
		local w, h = d:getSizeCooked()
		return x - (w * .5), y - (h * .5)
	end
}

---@param x any
---@param y any
---@return number x
---@return number y
function Sized:getAnchorPos(x, y)
	local f = anchor_funcs[self.anchor];
	if f then
		x, y = f(self, x, y)
	else
		print(("invalid sized anchor : '%s'"):format(tostring(self.anchor)))
	end
	return x, y
end

---@param x integer x position
---@param y integer y position
function Sized:draw(x, y)
    error("overload the draw method for " .. self:type())
end

return Sized