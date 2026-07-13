---@class LocaleKey
local LocaleKey = {
	content = ""
}

---@param a LocaleKey
---@param b LocaleKey|string
---@return LocaleKey
function LocaleKey.__add(a, b)
	if type(b) == "string" then
		return a:addTo(b)
	elseif getmetatable(b) == LocaleKey then
		return a:addTo(b.content)
	else
		error("invalid add type for locale key")
	end
end

---@param s string
---@return LocaleKey
function LocaleKey:addTo(s)
	self.content = self.content.."."..(s or error("tried to add nil to locale key"))
	return self
end

---@param k string
---@return LocaleKey
function LocaleKey:with(k)
	return LocaleKey:new(self.content.."."..(k or error("tried to add nil to locale key")))
end

---@param c? string
---@return LocaleKey
function LocaleKey:new(c)
	c = c or ""
	return setmetatable({ content = c }, { __index = LocaleKey })
end

---@class Locale
local Locale = {
	curLang = "",
	---@type fun()?
	addExtra = nil
}

local auto, assign

local _Root = {}
local _Collected = {}
local _FinalizedKeys = {}

function auto(tab, key)
    return setmetatable({}, {
        __index = auto,
        __newindex = assign,
        parent = tab,
        key = key,
    })
end

local meta = {
    __index = auto,
}

-- The if statement below prevents the table from being
-- created if the value assigned is nil. This is, I think,
-- technically correct but it might be desirable to use
-- assignment to nil to force a table into existence.

function assign(tab, key, val)
    -- if val ~= nil then
    local oldmt = getmetatable(tab)
    oldmt.parent[oldmt.key] = tab
    setmetatable(tab, meta)
    rawset(tab, key, val)
    -- end
end



local localemt = {}
function localemt:__index(key)
    if _Root[key] then
        return _Root[key]
    end
    local val = auto(_Root, key)
    _Root[key] = val
    return val
end

function localemt:__newindex(key, val)
    assert(type(val) == "table", "value was not table")
    local blank = auto(_Root, key)
    local mt = getmetatable(blank)
    _Root[key] = setmetatable(val, mt)
end

local finalize
function finalize(t, trail)
    t = setmetatable(t, nil)
    for k, v in pairs(t) do
        if type(k) ~= "string" or k:sub(1, 1) ~= "_" then
            trail[#trail + 1] = k
            if type(v) == "table" then
                if type(v[1]) == "string" then
                    local key = table.concat(trail, ".")
                    _FinalizedKeys[key] = setmetatable(v, nil)
                else
                    finalize(v, trail)
                end
            else
                local key = table.concat(trail, ".")
                _FinalizedKeys[key] = v
            end
            trail[#trail] = nil
        end
    end
end

function _BeforeLoad()
    _Root = {}
end

function _AfterLoad()
    _Collected = table.merge(_Collected, _Root)
end

_Finalize = function()
    finalize(_Collected, {})
end

---@param lang? string the lang code
---@return Locale
function Locale:setup(lang)
	lang = lang or self.curLang or error("need lang for locale setup")
	self.curLang = lang
	_BeforeLoad()
	_FinalizedKeys = {}

	local l = {}
	local globalmt = getmetatable(_G)
	setmetatable(_G, localemt)

	local reqPaths = Funcs.getRequirePaths("data/locale/"..lang)
	for _, p in ipairs(reqPaths) do
		require(p)
	end

	if self.addExtra then
		self.addExtra()
	end

	_AfterLoad()
	_Finalize()

	setmetatable(_G, globalmt)
	return setmetatable(l, { __index = Locale })
end

---@param key LocaleKey|string
---@return string
function Locale:getString(key)
	local k
	if type(key) == "string" then
		k = key
	elseif getmetatable(key) == LocaleKey then
		k = key.content
	end
	return _FinalizedKeys[k or error("invalid key type for get string")] or ("<missing key: "..k..">")
end

---@class LocaleScope
local LocaleScope = {
	---@type LocaleKey
	key = nil
}

---@param key string
---@return LocaleKey
function LocaleScope:getKey(key)
	return self.key:with(key)
end

function LocaleScope:getString(key)
	return self.key:with(key):getString()
end

function Locale:makeScope(key)
	return setmetatable({ key = LocaleKey:new(key) }, { __index = LocaleScope })
end

---@return string
function LocaleKey:getString()
	return Locale:getString(self.content)
end

---@param scope LocaleScope
---@return string
function string.localize(s, scope)
	return scope:getKey(s):getString()
end

return Locale