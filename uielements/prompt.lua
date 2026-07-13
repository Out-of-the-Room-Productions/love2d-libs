local ui = require "lib.ui"
local entry = require "lib.uie.entry"
local locale = require "lib.locale"

local textstack = "TEXTPROMPT"
local promptstack = "PROMPT"

local lscope = locale:makeScope("general")

---@class Prompt : Screen
local Prompt = setmetatable({
	---@type Layer
	layer = nil,
	label = "",
	w = 300,
	h = 170
}, { __index = ui.screens.Screen })

function Prompt:draw()
	self.layer:draw(0, 0)
end

function Prompt:update(dt)
	self.layer:update(dt)
end

---@nodiscard
---@return VerticalContainer
---@return HorizontalContainer
function Prompt:basicSetup()
	self.layer = ui.layer.Layer:create{}
	local ww, wh = love.window.getMode()
	local vbox = ui.container.Vertical:create({
		center = true,
		extraHeight = 25
	})

	local evbox = ui.container.Vertical:create({
		center = true,
		extraHeight = 25
	})

	vbox:addItem(ui.widgets.text.FText:fromString(self.label))
	vbox:addItem(evbox)

	local hbox = ui.container.Horizontal:create({ extraWidth = 20 })
	vbox:addItem(hbox)

	local contentCenter = ui.widgets.center:create({
		w = self.w,
		h = self.h,
		content = vbox
	})

	local mainCenter = ui.widgets.center:create({
		w = ww,
		h = wh,
		content = ui.widgets.panel:wrapItem(contentCenter)
	})

	self.layer:addItem(mainCenter, 0, 0)
	return evbox, hbox
end

function Prompt:setup(a)
	self.label = a.label or self.label
	self.w = a.w or self.w
	self.h = a.h or self.h
	local opts = a.opts

	local vbox, hbox = self:basicSetup()
	for _, opt in pairs(opts) do
		hbox:addItem(ui.widgets.button.basicFromString(opt[1], function ()
			opt[2]()
			self:pop()
		end))
	end

	return self
end

---@class TextPrompt : Prompt
local TextPrompt = setmetatable({
	text = "",
}, { __index = Prompt })

function TextPrompt:setup(a)
	self.label = a.label or self.label
	self.w = a.w or self.w
	self.h = a.h or self.h

	local acc = function ()
		a.apply(self.text)
		self:pop()
	end

	local vbox, hbox = self:basicSetup()
	local en = entry:create{
		binding = ui.binding:create(self, "text"),
		onAccept = acc
	}
	vbox:addItem(en)
	hbox:addItem(ui.widgets.button.basicFromString(lscope:getString("cancel"), function ()
		self:pop()
	end))
	hbox:addItem(ui.widgets.button.basicFromString(lscope:getString("accept"), acc))
	ui:setFocus(en)
	return self
end



local ret = {}

---@param l string
---@param f fun(text: string)
---@param w? number
---@param h? number
function ret:textPrompt(l, f, w, h)
	local st = ui.screens.Stacks
	st:initStack(textstack, 20)
	st:push(setmetatable({ text = "" }, { __index = TextPrompt }), textstack, {
		label = l or "Your label here",
		w = w,
		h = h,
		apply = f
	})
end

---@param l string
---@param w? number
---@param h? number
---@param ... table
function ret:prompt(l, w, h, ...)
	local st = ui.screens.Stacks
	st:initStack(promptstack, 20)
	st:push(setmetatable({}, { __index = Prompt }), promptstack, {
		label = l,
		w = w,
		h = h,
		opts = {...}
	})
end

local function emptyfunction()
	
end

---@param l string
---@param yf fun()
---@param nf? fun()
function ret:yesNo(l, yf, nf)
	self:prompt(l, nil, nil,
		{ lscope:getString("no"), nf or emptyfunction },
		{ lscope:getString("yes"), yf or emptyfunction }
	)
end

return ret