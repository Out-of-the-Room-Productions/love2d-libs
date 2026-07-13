local storyPart = require "story.part"
local decision = require "story.decision"

---@alias vn.ContinueResult
---|"OK"
---|"NO_ROUTINE"
---|"WAIT"

---@class vn.Story
local Story = {
    id = "",
    ---@type table<string, vn.Story.Part>
    parts = {},
    startName = "start",
    playedParts = {},
    ---@type string[]
    partStack = {},
    ---@type table<string, string[]>
    partAfters = {},
    ---@type thread?
    routine = nil
}

---@param o vn.Story
---@return vn.Story
function Story:create(o)
    o = o or {}
    o.parts = o.parts or {}
    o.playedParts = {}
    local ret = setmetatable(o, { __index = self })
	ret:setToStart()
    return ret
end

function Story:setToStart()
	self.partStack = { self.startName or "start" }
end

---@param o vn.Story.Part
function Story:addPart(o)
    o = storyPart:create(o)
    self:addAfters(o)
    self.parts[o.id] = o
end

---@protected
---@param o vn.Story.Part
function Story:addAfters(o)
    if not self.partAfters[o.after] then
        self.partAfters[o.after] = {}
    end
    table.insert(self.partAfters[o.after], o.id)
end

function Story:getCurrentPart()
    return self.parts[self:getCurrentPartName()]
end

function Story:getCurrentPartName()
    return self.partStack[#self.partStack]
end

function Story:getRunAmount(name)
    return self.playedParts[name] or 0
end


local function getBranch(t, n)
    local i = (n * 2) - 1

    local cond = t[i]
    local func = t[i + 1]

    --[[Logger:debug("story", ("branch test: i = '%s': '%s' | '%s'"):format(
        tostring(i),
        tostring(cond),
        tostring(func)
    ))]]

    if type(cond) ~= "boolean" then
        Logger:error("story", "invalid decision: bool expected, got: "..(tostring(cond) or "nil"))
    end
    if type(func) ~= "function" then
        Logger:error("story", "invalid decision: function expected, got: "..(tostring(func) or "nil"))
    end

    return decision.Branch:create{
        condition = cond;
        play = func;
    }
end

---@param ... boolean|fun()
function Story:decision(...)
    local args = {...}
    local dec = decision.Decision:create()

    if #args % 2 == 0 then
        for i = 1, (#args / 2), 1 do
            dec:withBranch(getBranch(args, i))
        end
    else
        for i = 1, math.floor(#args / 2), 1 do
            dec:withBranch(getBranch(args, i))
        end
        dec:_else(args[#args])
    end
    dec:evaluate(self)
    Logger:verbose("story", "decision evaluation completed")
end
Story.branch = Story.decision

---@return vn.ContinueResult
function Story:continue()
    if not self.routine or coroutine.status(self.routine) == "dead" then
        self:findNextPart()
    end

    if not self.routine then
        Logger:error("story", "unable to continue story, routine is nil")
        return "NO_ROUTINE"
    end

    local _, ret = coroutine.resume(self.routine, self)

    if coroutine.status(self.routine) == "dead" then
        self.routine = nil
        Logger:verbose("story", "part completed")
        return self:continue()
	else
		return ret or "OK"
    end
end

function Story:findNextPart()
    -- Get the name of the current part
    local cPart = self:getCurrentPartName()
    -- Initialize current priority to a very small number
    local cPrio = math.tiny
    -- Initialize next part to nil
    local nPart = nil
    -- Iterate over each part that comes after the current part
    for name, partName in pairs(self.partAfters[cPart] or {}) do
        -- Get the Part object corresponding to the part name
        local p = self.parts[partName]
        -- If the part has already been played or is not active, skip to next iteration
        if self.playedParts[partName] or not p:isActive(self) then
            goto continue
        end
        -- Get the priority of the Part
        local prio = p:getPriority()
        -- If the Part has higher priority than the current highest priority, update nPart and cPrio
        if prio > cPrio then
            nPart = p
            cPrio = prio
        end
        -- Continue iterating over the parts
        ::continue::
    end
    -- If no next part was found
    if nPart == nil then
        -- If there are no more parts in the stack, output a warning message
        if #self.partStack == 0 then
            Logger:warning("story", "reached end in story "..self.id)
        else
            -- If there are still parts in the stack, remove the current part from the stack and try finding the next part again
            Logger:warning("story", "no more paths past "..cPart..", popping stack...")
            table.remove(self.partStack)
            self:findNextPart()
        end
    else
        -- If a next part was found, log a verbose message that the story is starting the next part
        Logger:verbose("story", ("story '%s' now starting part '%s'"):format(self.id, nPart.id))
        -- Add the ID of the next part to the stack
        table.insert(self.partStack, nPart.id)
        -- Update the playedParts table to indicate that the parts in the stack have been played
        for _, value in pairs(self.partStack) do
            if self.playedParts[value] then
                self.playedParts[value] = self.playedParts[value] + 1
            else
                self.playedParts[value] = 1
            end
        end

        self.routine = coroutine.create(nPart.play or function()
            Logger:error("story", "play was null for part "..nPart.id)
        end)
    end
end


return {
    Story = Story,
    Part = storyPart,
    Decision = decision
}
