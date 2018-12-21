local Watcher = import(".Watcher", ...)
local observe = import(".Observer", ...).observe


local targets = {steps = 10, {id = 1, num = 10}}
local data ={A = {a = 2}, b = 3}
local modelData = observe(data)

local watcher =
    Watcher.new(
    modelData,
    "A.a",
    function(vm, newValue, oldValue)
        print("新值 = ", newValue)
    end
)

modelData.A = 3
modelData.A = {}
modelData.A.a = 3

