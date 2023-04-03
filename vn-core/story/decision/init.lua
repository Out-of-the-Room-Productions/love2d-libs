---@class Decision
local Decision = {
    ---@type Branch[]
    branches = {}
}

---@class Branch
local Branch = {
    condition = true,
    play = function()
    end
}

---@param o Branch
---@return Branch
function Branch:create(o)
    return setmetatable(o, { __index = Branch })
end

---@return Decision
function Decision:create()
    return setmetatable({ branches = {} }, { __index = Decision })
end

---@param branch Branch
function Decision:withBranch(branch)
    table.insert(self.branches, branch)
end

---add an else if block to the Decision
---@param condition boolean
---@param f function
function Decision:_elseif(condition, f)
    self:withBranch(Branch:create{
        condition = condition,
        play = f
    })
end
function Decision:_else(f)
    self:withBranch(Branch:create{
        condition = true,
        play = f
    })
end

function Decision:evaluate(story)
    for _, value in ipairs(self.branches) do
        if value.condition then
            Globals.runSubRoutine(value.play)
            Logger:verbose("decision", "returned from subRoutine")
            return
        end
    end
end

return {
    Decision = Decision,
    Branch = Branch
}