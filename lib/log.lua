local debug = require("deps.debugger")

_G.dbg = debug
_G.assert = debug.assert

function _G.Log(...)
    if #{ ... } == 1 and type((...)) ~= "table" then
        print(...)
        return
    end
    if #{ ... } == 1 and type((...)) == "table" then
        print(debug.pretty(...))
        return
    end
    for i = 1, #{ ... } do
        local v = select(i, ...)
        if type(v) == "table" then
            print(debug.pretty(v))
        else
            io.write(tostring(v))
            if i < #{ ... } then
                io.write("\t")
            end
        end
    end
    io.write("\n")
end
