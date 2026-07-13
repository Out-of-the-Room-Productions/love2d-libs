---@diagnostic disable: different-requires
local fPath = (...).."."
local require_o = require

require = function(m)
	return require_o(fPath .. m)
end

---@class UI.Context
---@field scale number

UICTX = UICTX or { --[[@as UI.Context]]
	scale = 1.0;
}
local util = {}

local ui = {
	screens 	= require "screens",
	widgets = {
		panel	= require "widgets.panel",
		text 	= require "widgets.text",
		button 	= require "widgets.button",
		sized 	= require "widgets.sizedDrawable",
		margin	= require "widgets.margin",
		center	= require "widgets.centerBox",
		space	= require "widgets.space",
		image	= require "widgets.image",
	},
	container 	= require "container",
	funcs		= require "funcs",
	layer		= require "layer",
	nineSlice	= require "nineSlice",
	style		= require "style",
	binding		= require "binding",

	util = util,
	---@type Focusable?
	focused = nil
}

---@param lab string
---@param it Sized
---@param w number?
---@return Sized
function util.row(lab, it, w)
	w = w or 60
	local row = ui.container.Horizontal:create{
		center = true
	}
	local l = ui.widgets.text.FWord:fromString(lab)
	l.minWidth = w
	row:addItem(l)
	row:addItem(it)
	return row
end

---@param foc Focusable
function ui:unsetFocus(foc)
	if self.focused and self.focused == foc then
		self.focused:setFocus(false)
	end
end

---@param foc Focusable?
function ui:setFocus(foc)
	self:unsetFocus(self.focused)
	if foc then
		foc:setFocus(true)
		self.focused = foc
	end
end

require = require_o
return ui
