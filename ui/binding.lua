---@class Binding
local UIBinding = {
	object = {},
	path = "",
	---@type string?
	type = nil
}

function UIBinding:set(val)
	local setVal = tostring(val)
	local t = (self.type or type(val))
	if t == "string" then
		setVal = "\""..setVal.."\""
	elseif t == "number" then
		local n = false
		if setVal:len() == 0 or setVal == "-" then
			setVal = "0"
		else
			if setVal:find("-", nil, true) then
				n = true
			end
			setVal = setVal:gsub("[^%.%d]+","") -- %D+
		end

		if n and setVal:len() > 0 then
			setVal = "-"..setVal
		elseif n then
			setVal = "0"
		end
	elseif t == "table" then
		error("can't bind tables")
	end
	local str = self.path.." = "..setVal
	local sf = load(str, nil, "t", self.object) or error(("error setting ui binding setter: '%s'"):format(str))
	sf()
end

function UIBinding:get()
	local str = "return "..self.path
	local gf = load(str, nil, "t", self.object) or error("error setting ui binding getter")
	return gf()
end

function UIBinding:create(o, path)
	---@type Binding
	local r = {}
	r.object = o or { v = false }
	r.path = path or "v"
	return setmetatable(r, { __index = UIBinding })
end

function UIBinding:forceNumber()
	self.type = "number"
	return self
end

---@param get fun():any
---@param set fun(val: any)
---@return Binding
function UIBinding:fromFuncs(get, set)
	return setmetatable({ get = get, set = function (_, val) set(val) end }, { __index = UIBinding })
end

return UIBinding