
package.cpath = "./luaclib/?.so;"
package.path = "./lualib/?.lua;"

local evloop = require "evloop"
local redis = require "db.redis_proxy"
local hpms = require "hpms"
require "util"

evloop.start()

local function test_loop()
    local rds, err = redis.instance("127.0.0.1", 6379)
    if not rds then
        print("failed to connect redis:", err)
        return
    end
    local ok
    ok, err = rds:set("name", "zero voice")
    if not ok then
        print("failed to set name: ", err)
        return
    end
    local res
    res, err = rds:get("name")
    if not res then
        print("failed to get name: ", err)
        return
    end
    if res == null then
        print("name not found.")
        return
    end
    print("name:", res, #res)


    local script = [[
local args = KEYS[1]
local name = redis.call("get", "name")

if name == "zero voice" then
    redis.call("set", "name", args)
    return "success"
end
return "failed"
    ]]
    res, err = rds:script("load", script)
    print("script", table.dump(res), table.dump(err))

    res, err = rds:evalsha(res, 1, "mark")
    print("evalsha", table.dump(res), table.dump(err))

    rds:init_pipeline()
    rds:multi()     -- "OK"
    rds:get("name") -- "QUEUED"
    rds:exec()      -- { [1] = "mark",} ,}
    res = rds:commit_pipeline()
    print("pipeline", table.dump(res[3][1]), table.dump(err))
    -- shell: restart redis
    -- hpms.sleep(1000) -- sleep 10 seconds
    res, err = rds:get("name")
    print("name:", res, err)
end

hpms.fork(test_loop)

evloop.run()