---@class StoryPart
local StoryPart = {
    id = "",
    after = "",
    priority = 0.0,
    ---@type function?
    play = nil
}

---@param o StoryPart
---@return StoryPart
function StoryPart:create(o)
    o = o or {}
    return setmetatable(o, { __index = StoryPart })
end

---Get this part's priority
---@param self StoryPart
---@return number
function StoryPart.getPriority(self, story)
    return self.priority or 0.0
end

---Check whether the part is active or not
---@param self StoryPart
---@param story Story
---@return boolean
function StoryPart.isActive(self, story)
    return true
end

return StoryPart