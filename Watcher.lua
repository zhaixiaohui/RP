--*****************功能********************--
--              监听触发回调
--*****************************************--
local Deps = import(".Dep", ...)
local pushTarget = Deps.pushTarget
local popTarget = Deps.popTarget
local queueWatcher = import(".Scheduler").queueWatcher

local function segmentsPath(path)
    local segments = string.split(path, ".")
    return segments
end

local function getObjBySegments(obj, segments)
    for _, v in ipairs(segments) do
        if obj == nil then
            return nil
        end
        if (type(obj) == "table") then
            obj = obj[v]
        else
            return obj
        end
    end
    return obj
end

local function parsePath(path)
    local segments = segmentsPath(path)
    return function(obj)
        return getObjBySegments(obj, segments)
    end
end

local uid = 0
local Watcher = class("Watcher")

--single：为true表示连续多次触发同一消息只响应依次，为false表示触发几次响应几次(这也是默认值)
function Watcher:ctor(vm, expOrFn, cb, single)
    if not rawget(vm, "__is_proxy__") then
        error("vm not a proxy!")
    end

    self.single = single or false

    uid = uid + 1
    self.id = uid
    self.active = true
    self.vm = vm
    self.cb = cb
    self.deps = {} --保存添加过监听器的Dep对象(与Observe中key值对应的表)
    self.newDeps = {}

    if type(expOrFn) == "function" then
        self.getter = expOrFn
    else
        self.getter = parsePath(expOrFn)
        if self.getter == nil then
            self.getter = function()
            end
        end
    end

    self.value = self:get()
end

function Watcher:get()
    pushTarget(self)
    local value = self.getter(self.vm) --通过self.vm表获取要监听的字段值
    popTarget()
    self:cleanupDeps()
    return value
end

function Watcher:addDep(dep) -- call by Dep
    if not self.newDeps[dep] then
        self.newDeps[dep] = true
        if not self.deps[dep] then
            self.deps[dep] = true
            dep:addSub(self)
        end
    end
end

function Watcher:cleanupDeps() -- private
    for dep, _ in pairs(self.deps) do
        if not self.newDeps[dep] then
            dep:removeSub(self)
        end
    end
    self.deps = self.newDeps
    self.newDeps = {}
end

function Watcher:update() -- call by Dep
    if self.single then
        queueWatcher(self)
    else
        self:run()
    end
end

function Watcher:run()
    if self.active then
        local newValue = self:get() --这里再次获取该字段新值
        local oldValue = self.value
        --如果新旧值都是table，由于self.value获取的是引用，因此两表是相等的，需要做下类型判断
        if newValue ~= oldValue or type(newValue) == "table" then --新旧值不同或者新值为table则触发回调
            print("触发回调")
            self.value = newValue
            self.cb(self.vm, newValue, oldValue)
        end
    end
end

function Watcher:teardown()
    if self.active then
        for dep, _ in pairs(self.deps) do
            dep:removeSub(self)
        end
        self.deps = {}
        self.active = false
    end
end

return Watcher
