local sized = require "widgets.sizedDrawable"

---@class Space : Sized
local Space = setmetatable({
	width = 0.0,
	height = 0.0,
}, { __index = sized })

function Space:create(w, h)
	return setmetatable({ width = w, height = h }, { __index = self })
end

function Space:draw()
end

function Space:getSizeRaw()
	return self.width, self.height
end

return Space