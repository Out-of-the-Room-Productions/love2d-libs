local ui = require "lib.ui"
local event = require "lib.event"

---@class EventBinding : Binding
local EventBinding = {
	---@type Event
	event = nil
}

---@param b Binding
---@param e Event
---@return EventBinding
function EventBinding:fromBinding(b, e)
	b.event = e
	e:register(b, function (...)
		b:set(b:get())
	end)
	return setmetatable(b, { __index = setmetatable(EventBinding, ui.binding) }) --[[@as EventBinding]]
end

function EventBinding:release(p)
	self.event:unregister(self)
end

return EventBinding