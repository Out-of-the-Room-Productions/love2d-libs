

---@class VNChara
local VNChara = {
    charaId = "",
    displayName = ""
}

---@param o VNChara
---@return VNChara
function VNChara:create(o)
    o = o or {}
    return setmetatable(o, {
        __index = VNChara,
        __call = VNChara.__call
    })
end

---@private
function VNChara:__call(text)
    self:say(text)
end

---@private
function VNChara:say(text)
    Logger:debug(self.displayName, text)
    coroutine.yield()
end

return VNChara