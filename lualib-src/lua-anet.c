
#include "anet.h"
#include "lua.h"
#include "lauxlib.h"
#include <unistd.h>
#include <string.h>
#include <arpa/inet.h>
#include <stdbool.h>

static int
llisten(lua_State *L) {
    const char * host = luaL_checkstring(L, 1);
    int port = luaL_checkinteger(L, 2);
    int backlog = luaL_optinteger(L, 3, 32);
    int fd = anet_tcp_listen(host, port, backlog);
    if (fd < 0)
        return luaL_error(L, strerror(errno));
    lua_pushinteger(L, fd);
    return 1;
}

static int
ltcp_accept(lua_State *L) {
    int fd = luaL_checkinteger(L, 1);
    char ip[INET_ADDRSTRLEN] = {0};
    int port = -1;
    int clientfd = anet_tcp_accept(fd, ip, &port);
    if (clientfd < 0)
        return luaL_error(L, strerror(errno));
    lua_pushinteger(L, clientfd);
    lua_pushstring(L, ip);
    lua_pushinteger(L, port);
    return 3;
}

static int
ltcp_connect(lua_State* L) {
    const char * addr = luaL_checkstring(L, 1);
    int port = luaL_checkinteger(L, 2);
    int fd = anet_tcp_connect(addr, port);
    lua_pushinteger(L, fd);
    return 1;
}

static int
ltcp_close(lua_State *L) {
    int fd = luaL_checkinteger(L, 1);
    int ret = anet_tcp_close(fd);
    lua_pushinteger(L, ret);
    return 1;
}

static int
ltcp_shutdown(lua_State *L) {
    int fd = luaL_checkinteger(L, 1);
    int how = luaL_checkinteger(L, 2);
    int ret = anet_tcp_shutdown(fd, how);
    lua_pushinteger(L, ret);
    return 1;
}

static int
ltcp_getopt(lua_State *L) {
    int fd = luaL_checkinteger(L, 1);
    int option = luaL_checkinteger(L, 2);
    int val = 0;
    int ret = anet_tcp_getoption(fd, option, &val);
    switch (ret) {
    case -1:
        lua_pushnil(L);
        lua_pushstring(L, strerror(errno));
        break;
    case -2:
        lua_pushnil(L);
        lua_pushfstring(L, "unsupported option %d", option);
        break;
    default:
        lua_pushinteger(L, val);
        return 1;
    }
    return 2;
}

static int
ltcp_setopt(lua_State *L) {
    int fd = luaL_checkinteger(L, 1);
    int option = luaL_checkinteger(L, 2);
    int val = luaL_optinteger(L, 3, 1);
    int ret = anet_tcp_setoption(fd, option, val);
    switch (ret) {
    case -1:
        lua_pushboolean(L, false);
        lua_pushstring(L, strerror(errno));
        break;
    case -2:
        lua_pushboolean(L, false);
        lua_pushfstring(L, "unsupported option %d", option);
        break;
    default:
        lua_pushboolean(L, true);
        return 1;
    }
    return 2;
}

static int sync_write(lua_State *L) {
    int fd = luaL_checkinteger(L, 1);
    const void *buf = lua_touserdata(L, 2);
    int data_len = 0;
    if (!lua_isnil(L, 3)) {
        data_len = luaL_checkinteger(L, 3);
    } else {
        lua_pushboolean(L, false);
        return 1;
    }
    
    unsigned char  buffer[2048] = {0};
    uint32_t netLen = htonl(data_len);
    memcpy(buffer, &netLen, sizeof(netLen));
    memcpy(buffer + sizeof(netLen), buf, data_len);
    int n = write(fd, buffer, data_len + sizeof(netLen));
    if (n <= 0) {
        lua_pushboolean(L, false);
        return 1;
    }

    lua_pushboolean(L, true);
    lua_pushinteger(L, n);
    return 2;
}

static int async_write(lua_State *L) {
    int fd = luaL_checkinteger(L, 1);
    size_t len = 0;
    const char *buf = luaL_checklstring(L, 2, &len);
    int n = write(fd, buf, len);
    if (n <= 0) {
        lua_pushboolean(L, false);
        return 1;
    }

    lua_pushboolean(L, true);
    return 1;
}

static const struct luaL_Reg lib[] = {
    {"listen", llisten},

    {"accept", ltcp_accept},
    {"connect", ltcp_connect},
    {"close", ltcp_close},
    {"shutdown", ltcp_shutdown},

    {"getoption", ltcp_getopt},
    {"setoption", ltcp_setopt},
    {"sync_send", sync_write},
    {"async_send", async_write},
    {NULL, NULL}
};

int luaopen_hpms_anet(lua_State *L) {
    luaL_newlib(L, lib);
    return 1;
}
