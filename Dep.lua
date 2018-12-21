--*****************功能********************--
--      保存并触发每一个字段的监听对象
--*****************************************--
local Dep = class('Dep');

--设置该值确保在Watcher对象存在时才能从Observe中访问监听数据
Dep.target = nil;--Watcher

function Dep:ctor()
    self.subs = {}; --保存监听器Watcher
end

function Dep:addSub(sub) -- call by Watcher
    table.insert(self.subs,sub)
end

function Dep:removeSub(sub) -- call by Watcher
    table.removebyvalue(self.subs,sub)
end

function Dep:depend() -- call by observe
    if Dep.target then
        Dep.target:addDep(self);
    end
end

function Dep:notify() -- call by observe
    local subs = self.subs;
    for _,watcher in ipairs(subs) do
        watcher:update();
    end
end


local targetStack = {};
local function pushTarget(_target) -- call by Watcher
    if Dep.target then
        table.insert(targetStack,_target);
    end
    Dep.target = _target;
end
local function popTarget() -- call by Watcher
    Dep.target = table.remove(targetStack);
end

return {
    Dep = Dep;
    pushTarget = pushTarget;
    popTarget = popTarget;
}