local funcs = {}

function funcs.runSubRoutine(f)
    local co = coroutine.create(f)

    while true do
        local y = coroutine.resume(co)
        local s = coroutine.status(co)
        Logger:debug("subRoutine", y, "\t", s)
        if s == "dead" then
            Logger:verbose("subRoutine", "routine is dead, returning")
            return
        else
            coroutine.yield(y, s)
        end
    end
end

return funcs