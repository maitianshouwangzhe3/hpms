local socket = require "socket"
local hpms = require "hpms"

local readbytes = socket.read
local writebytes = socket.write

local sockethelper = {}
local socket_error = setmetatable({} , { __tostring = function() return "[Socket Error]" end })

sockethelper.socket_error = socket_error

local function preread(fd, str)
    return function (sz)
        if str then
            if sz == #str or sz == nil then
                local ret = str
                str = nil
                return ret
            else
                if sz < #str then
                    local ret = str:sub(1,sz)
                    str = str:sub(sz + 1)
                    return ret
                else
                    sz = sz - #str
                    local ret, err = readbytes(fd, sz)
                    if err then
                        error(err)
                    else
                        return str .. ret
                    end
                end
            end
        else
            local ret, err = readbytes(fd, sz)
            if err then
                error(err)
            else
                return ret
            end
        end
    end
end

function sockethelper.readfunc(fd, pre)
    if pre then
        return preread(fd, pre)
    end
    return function (sz)
        local ret, err = readbytes(fd, sz)
        if err then
            error(err)
        else
            return ret
        end
    end
end

sockethelper.readall = socket.readall

function sockethelper.writefunc(fd)
    return function(content)
        local ok = writebytes(fd, content)
        if not ok then
            error(socket_error)
        end
    end
end

function sockethelper.connect(host, port, timeout)
    local fd
    -- TODO:
    -- if timeout then
    --     local drop_fd
    --     local co = coroutine.running()
    --     -- asynchronous connect
    --     hpms.fork(function()
    --         fd = socket.connect(host, port)
    --         if drop_fd then
    --             -- sockethelper.connect already return, and raise socket_error
    --             socket.close(fd)
    --         else
    --             -- socket.open before sleep, wakeup.
    --             hpms.wakeup(co)
    --         end
    --     end)
    --     hpms.sleep(timeout)
    --     if not fd then
    --         -- not connect yet
    --         drop_fd = true
    --     end
    -- else
        -- block connect
        fd = socket.block_connect(host, port)
    -- end
    if fd then
        return fd
    end
    error(socket_error)
end

function sockethelper.close(fd)
    socket.close(fd)
end

function sockethelper.shutdown(fd)
    socket.shutdown(fd)
end

return sockethelper
