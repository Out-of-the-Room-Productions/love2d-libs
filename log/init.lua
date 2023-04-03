local function makeLevel(name, l, clr)
    return {
        name = name,
        level = l,
        colorHtml = clr
    }
end

local log = {
    level = {
        off = makeLevel("off", 0),
        verbose = makeLevel("verbose", 5, "#919191"),
        debug = makeLevel("debug", 10),
        info = makeLevel("info", 15, "#85eddf"),
        warning = makeLevel("warn", 20, "#fcba03"),
        error = makeLevel("err", 25, "#fa2e00"),
    },
    handlers = {}
}
table.insert(log.handlers, function(mes, l)
    print(mes)
end)

function log:log(l, s, ...)
    local arg = {...}
    local mes = ""
    for _, value in ipairs(arg) do
        mes = mes .. tostring(value)
    end
    self:pushMessage(("<%s> %s \t(%s)"):format(s, mes, l.name), l)
end

function log:pushMessage(mes, l)
    for _, value in ipairs(self.handlers) do
        value(mes, l)
    end
end

function log:verbose(s, ...)
    self:log(self.level.verbose, s or "root", ...)
end
function log:debug(s, ...)
    self:log(self.level.debug, s or "root", ...)
end
function log:info(s, ...)
    self:log(self.level.info, s or "root", ...)
end
function log:warning(s, ...)
    self:log(self.level.warning, s or "root", ...)
end
function log:error(s, ...)
    self:log(self.level.error, s or "root", ...)
end

return log