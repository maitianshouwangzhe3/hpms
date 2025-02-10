package.cpath = "./luaclib/?.so;"
package.path = "./lualib/?.lua;"

local socket = require "socket"
local evloop = require "evloop"
local hpms = require "hpms"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local table = table
local string = string

if ENABLE_TLS then
    local c = require "ltls.init.c"
    c.constructor()

    CERT_FILE = "./public.crt"
    KEY_FILE = "./private.key"
end

local SSLCTX_SERVER = nil
local function gen_interface(protocol, fd)
	if protocol == "http" then
		return {
			init = nil,
			close = nil,
			read = sockethelper.readfunc(fd),
			write = sockethelper.writefunc(fd),
		}
	elseif protocol == "https" then
		local tls = require "http.tlshelper"
		if not SSLCTX_SERVER then
			SSLCTX_SERVER = tls.newctx()
			-- gen cert and key
			-- openssl req -x509 -newkey rsa:2048 -days 3650 -nodes -keyout server-key.pem -out server-cert.pem
			-- print(certfile, keyfile)
			SSLCTX_SERVER:set_cert(CERT_FILE, KEY_FILE)
		end
		local tls_ctx = tls.newtls("server", SSLCTX_SERVER)
		return {
			init = tls.init_responsefunc(fd, tls_ctx),
			close = tls.closefunc(tls_ctx),
			read = tls.readfunc(fd, tls_ctx),
			write = tls.writefunc(fd, tls_ctx),
		}
	else
		error(string.format("Invalid protocol: %s", protocol))
	end
end

local function response(id, write, ...)
	local ok, err = httpd.write_response(write, ...)
	if not ok then
		-- if err == sockethelper.socket_error , that means socket closed.
		print(string.format("fd = %d, %s", id, err))
	end
end

local function client_loop(fd)
    local interface = gen_interface("http", fd)
    if interface.init then
        interface.init()
    end
    local code, url, method, header, body = httpd.read_request(interface.read, nil)
    --print("url:", url, "method:", method, "header:", header, "body:", body, "code:", code)
    if code then
        if code ~= 200 then
            response(fd, interface.write, code)
        else
            if url == "/" then
                local file, err = io.open("./source/index.html")
                if not file then
                    print(err)
                return
                end
                local body = file:read("*all")
                file:close()
                response(fd, interface.write, 200, body)
            elseif url == "/source/hpms.png" then
                file, err = io.open("./source/hpms.png")
                if not file then
                    print(err)
                return
                end
                local body = file:read("*all")
                file:close()
                response(fd, interface.write, 200, body)
            else
                response(fd, interface.write, 200, "Not Found")
            end
        end
    else
        if url == sockethelper.socket_error then
            print("socket closed")
        else
            print(url)
        end
    end
    if interface.close then
        interface.close()
    end
    socket.close(fd)
end

evloop.start("0.0.0.0:8989", function (fd, ip, port)
    --print("accept a connection:", fd, ip, port)
    socket.bind(fd, client_loop)
end)

evloop.run()
