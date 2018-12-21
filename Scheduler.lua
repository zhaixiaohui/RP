local MAX_UPDATE_COUNT = 100;
local queue = {}; -- array

local has = {};
local circular = {};

local waiting = false;
local flushing = false;
local index = 1; -- flushingSchedulerQueueIndex
local callbacks = {}; -- array
local pending = false;

function resetSchedulerState()
    index = 1;
    queue = {};
    has = {};
    circular = {};
    waiting = false;
    flushing = false;
end

--排序并执行队列中的监视回调
function flushSchedulerQueue()
    flushing = true;

    table.sort(queue,function(a,b)
        return a.id < b.id;
    end)

    index = 1;
    while index <= #queue do
        local watcher = queue[index];
        has[watcher] = nil;

        watcher:run();

        if has[watcher] then
            circular[watcher] = (circular[watcher] or 0) + 1;
            if circular[watcher] > MAX_UPDATE_COUNT then
                error('circulard update!');
                break;
            end
        end

        index = index + 1;
    end

    resetSchedulerState();
end

function nextTickHandler()
    pending = false;
    local copies = callbacks;
    callbacks = {};
    for _,v in ipairs(copies) do
        v();
    end
end

local timerFun = function() end
-- local function timerFun(handle)
--     if(handle) then
--         handle()
--     end
-- end;

function nextTick(cb)
    table.insert(callbacks,function()
        if cb then
            cb();
        end
    end)

    if not pending then
        pending = true;--变量为了在nextTickHandler函数中有可能再次调用nextTick函数而设置，即循环调用
        timerFun(nextTickHandler);
    end
end

function queueWatcher(watcher)
    if not has[watcher] then    --这里对同一个监视事件做出过滤，只保存第一次事件触发，触发调用返回的是最新的数据
        has[watcher] = true;    
        if not flushing then
           table.insert(queue,watcher);
        else
            local i = #queue;
            while i > index and queue[i].id > watcher.id do
                i = i - 1;
            end
            table.insert(queue,i + 1,watcher);
        end
        if not waiting then
            waiting = true;
            nextTick(flushSchedulerQueue);
        end
    end
end


local function setTimerFun(v)
    timerFun = v;
end
local function getTimerFun()
    return timerFun;
end






return {
    queueWatcher = queueWatcher;
    setTimerFun = setTimerFun;
}