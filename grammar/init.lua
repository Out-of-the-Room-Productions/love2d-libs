local conditionPattern = "%[(.-)%]"
local grammarPattern = "{(.-)}"

local weightPattern = "%((.-)%)"
local weightFuncPattern = "%<(.-)%>"

local labelPattern = "(.-) <%-"
local rulePattern = "(.-)\n"
local contentPattern = "^.- <%- (.-)$"

local parser = {}

function parser:matchString(match)
    local o = match

    match = "return "..match
    if not match:match(weightPattern) then
        match = match.."()"
    end
    local f = load(match, nil, "t", {})
    local r = f and f() or ("<parse error at '%s'>"):format(o)
    return r
end

---parse a string and prepare it for turning into a FText
---@param str string
---@return string
function parser:preparse(str)
    str = str:gsub(conditionPattern, parser.matchString)
    str = str:gsub(grammarPattern, parser.matchString)

    return str
end

---@class GrammarContext
local GrammarContext = {
    vals = {},
    obj = {}
}
function GrammarContext:create(o)
    return setmetatable(o, { __index = GrammarContext })
end

---@class GrammarRule
local GrammarRule = {
    ---@type fun(ctx: GrammarContext):boolean
    cond = nil,
    ---@type number|fun(ctx: GrammarContext):number
    weight = 1.0,
    content = ""
}

---@param o GrammarRule
---@return GrammarRule
function GrammarRule:create(o)
    return setmetatable(o or {}, { __index = GrammarRule })
end

---@param grammar Grammar
---@param ctx GrammarContext
---@return string
function GrammarRule:resolve(grammar, ctx)
    local res = self.content:gsub(grammarPattern, function(match)
        return grammar:repl(match, ctx)
    end)
    return res
end

---@class Grammar
local Grammar = {
    ---@type table<string, GrammarRule[]>
    rules = {},
    root = "root"
}

---@return Grammar
function Grammar:new()
    return setmetatable({ rules = {} }, { __index = Grammar })
end

---@param s string
---@return Grammar
function Grammar:parse(s)
    ---@type Grammar
    local res
    if self == Grammar then
        res = Grammar:new()
    else
        res = self
    end

    s = s:gsub("(%-%-.-\n", "")	--  remove commented out rules
    s = s:gsub("\n\n", "\n")	--  remove excess newlines
    s = s:gsub("\t\n", "\t")	--  remove empty lines
    s = s:gsub("\t", "")		--  remove indentation

    local r = s:gsub(rulePattern, function(match)
        local rule = GrammarRule:create {}
        -- Logger:debug("grammar", "match: '"..(match or "nil").."'")
        ---@type string
        local label = string.match(match, labelPattern) or "nil"

        label = label:gsub(conditionPattern, function(m)
            local c = "return "..m
            rule.cond = function(ctx)
                ---@type nil|fun():boolean
                local f = load(c, nil, "t", ctx.vals)
                local fRes = f and f() or nil
                return fRes or not true
            end
            return ""
        end)

        label = label:gsub(weightPattern, function(m)
            rule.weight = tonumber(m) or 1.0
            return ""
        end)

        label = label:gsub(weightFuncPattern, function(m)
            local w = "return "..m
            rule.weight = function(ctx)
                ---@type nil|fun():number
                local f = load(w, nil, "t", ctx.vals)
                return f and f() or 1.0
            end
            return ""
        end)

        rule.content = string.match(match, contentPattern)
        -- Logger:debug("grammar", "content: '"..(rule.content or "nil").."'")

        if res.root == "root" then
            res.root = label
        end
        -- Logger:debug("grammar", "label: '"..label.."'")

        res:addRule(label, rule)
        return "KEK"
    end)

    return res
end

---@param label string
---@param rule GrammarRule
function Grammar:addRule(label, rule)
    if not self.rules[label] then
        self.rules[label] = {}
    end
    table.insert(self.rules[label], rule)
end

---@param label string
---@param ctx GrammarContext
---@return GrammarRule
function Grammar:getRule(label, ctx)
    local rules = self.rules[label] or Logger:fatal("grammar", "unable to find label "..label)
    local weights = {}

    ---@type GrammarRule[]
    local activeRules = {}
    for _, value in ipairs(rules) do
        if not value.cond or value.cond(ctx) then
            table.insert(activeRules, value)
        end
    end

    for index, value in ipairs(activeRules) do
        weights[index] = type(value.weight) == "number" and value.weight or value.weight(ctx)
    end

    if #activeRules == 0 then
        return GrammarRule:create {}
    end
    return math.weighted(weights, activeRules)
end

---@param obj table?
---@param args table?
---@param root string?
---@return string
function Grammar:resolve(obj, args, root)
    obj = obj or {}
    args = args or {}
    root = root or self.root
    local ctx = GrammarContext:create{
        vals = args or {},
        obj = obj
    }
    ctx.vals.obj = obj

    return self:getRule(root, ctx):resolve(self, ctx)
end

---@param other Grammar
function Grammar:addFrom(other)
    for key, value in pairs(other.rules) do
        if not self.rules[key] then
            self.rules[key] = {}
        end

        table.insert(self.rules[key], value)
    end
end

---@param label string
---@param ctx GrammarContext
---@return string
function Grammar:repl(label, ctx)
    local rule = self:getRule(label, ctx)
    return rule:resolve(self, ctx)
end

Grammar.Rule = GrammarRule
Grammar.Context = GrammarContext

return Grammar