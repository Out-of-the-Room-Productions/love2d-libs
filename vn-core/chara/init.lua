local log = Logger:spec("VNCharaBase")

---@class VNCharaBase
local VNChara = {
    charaId = "",
    displayName = ""
}

---@param o VNCharaBase
---@return VNCharaBase
function VNChara:create(o)
    o = o or {}
    return setmetatable(o, {
        __index = self,
        __call  = self.__call
    })
end

function VNChara:__call(text)
    self:say(text)
end

function VNChara:say(text)
	log:debug(("%s(%s)"):format(self.displayName, self.charaId), text)
    coroutine.yield()
end

function VNChara:show(data)
	
end

function VNChara:hide(data)
	
end

return VNChara