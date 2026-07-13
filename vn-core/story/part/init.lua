---@class vn.Story.Part
local StoryPart = {
    id = "",
    after = "",
    priority = 0.0,
    ---@type function?
    play = nil
}

---@param o vn.Story.Part
---@return vn.Story.Part
function StoryPart:create(o)
    o = o or {}
    return setmetatable(o, { __index = StoryPart })
end

---Get this part's priority
---@param self vn.Story.Part
---@return number
function StoryPart.getPriority(self, story)
    return self.priority or 0.0
end

---Check whether the part is active or not
---@param self vn.Story.Part
---@param story vn.Story
---@return boolean
function StoryPart.isActive(self, story)
    return true
end

return StoryPart