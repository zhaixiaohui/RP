--*****************功能********************--
--          构建数据创建被监听对象
--*****************************************--
local Dep = import('.Dep',...).Dep;

local function observe(original)

    if type(original) ~= 'table' then
        return original;
    end

    if rawget(original,'__is_proxy__') then
        return original;
    end

    if rawget(original,'__proxy__') then
        return rawget(original,'__proxy__');
    end

    local deps = {};
    local function getDep(k)
        if deps[k] == nil then
            deps[k] = Dep.new();
        end
        return deps[k];
    end
    --给每一个字段映射一张Dep表并转化为{key：value}
    for k,v in pairs(original) do
        getDep(k);
        original[k] = observe(v);
    end

    local proxy = {};
    local tableDep = Dep.new();
    rawset(proxy, '__is_proxy__', true);
    rawset(proxy, '__dep__', tableDep);
    rawset(original, '__proxy__', proxy);

    function proxy:getn()
        return #original;
    end

    function proxy:pairs(fun)
        for k,v in pairs(original) do
            if v ~= proxy then
                if fun(k,v) then
                    break;
                end
            end
        end
    end

    function proxy:ipairs(fun)
        for k,v in ipairs(original) do
            if fun(k,v) then
                break;
            end
        end
    end

    function proxy:copy()
        local ret = {};
        self:pairs(function(k,v)
            if type(v) == 'table' then
                ret[k] = v:copy();
            else
                ret[k] = v;
            end
        end);
        return ret;
    end

    function proxy:insert(...) -- 数组添加
        local args = {...};
        if #args==1 then
            table.insert(original,observe(args[1])); -- value
        else
            table.insert(original,args[1],observe(args[2]));-- pos,value
        end
        tableDep:notify();
    end
    function proxy:remove(...) -- 数组移除
        local ret = table.remove(original,...);
        tableDep:notify();
        return ret;
    end
    function proxy:sort(type) -- 数组排序
        local func = nil
        if(type == 'desc') then
            func = function(a, b) return a > b  end
        else
            func = function(a, b) return a < b  end
        end
        table.sort(original, func);
        tableDep:notify();
    end

    -- core
    local index = function(t,k) -- getter
        if Dep.target then
            --如果k字段对应的是一个table，则为key值和该table中__dep__字段同时注册监听
            getDep(k):depend();
            if type(original[k]) == 'table' then
                local childTableDep = rawget(original[k], '__dep__');
                childTableDep:depend();
            end
        end
        return original[k];
    end
    local newindex = function(t,k,v) -- setter
        local oldValue = original[k];
        local newValue = observe(v);
        if newValue ~= oldValue then
            original[k] = newValue;
            getDep(k):notify();
            tableDep:notify();
        end
    end
    local metatable = { __index = index; __newindex = newindex; }
    setmetatable(proxy,metatable);

    return proxy;
end


return {
    observe = observe;
};