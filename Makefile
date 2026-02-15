
PLAT ?= linux
CC ?= gcc

.PHONY : clean hpms linux macosx all
.PHONY : default

default :
	$(MAKE) $(PLAT)

LUA_CLIB_PATH ?= luaclib
LUA_CLIB_SRC ?= lualib-src
LUA_CLIB ?= hpms ltls
HPMS_LIBS ?= -ldl -lm
CORE_PATH ?= ./core
EXTRA_LIBS ?= 

linux : PLAT := linux
macosx : PLAT := macosx

SHARED = -fPIC --shared
EXPORT = -Wl,-E

# TLS_MODULE=ltls
TLS_LIB=
TLS_INC=

macosx : SHARED := -fPIC -dynamiclib -Wl,-undefined,dynamic_lookup
macosx : EXPORT :=

LUA_INC_PATH ?= deps/lua
LUA_STATICLIB := deps/lua/liblua.a

# append pthread when use jemalloc
linux : HPMS_LIBS += -lpthread

MACOSX_DEPLOYMENT_TARGET := '12.0'
linux : MACOSX_DEPLOYMENT_TARGET :=

XCFLAGS := '-fno-stack-check'

LUA_CLIB_HPMS = \
	lua-ae.c \
	lua-anet.c \
	lua-core.c lsha1.c\
	lua-buffer.c

LUA_CLIB_HPMS_NET = ae.c anet.c buffer.c systime.c

CFLAGS = -g -O2 -Wall -I$(LUA_INC_PATH)

NET_SRC = ae.c anet.c systime.c buffer.c hpms.c

linux macosx:
	$(MAKE) all EXPORT="$(EXPORT)" SHARED="$(SHARED)" HPMS_LIBS="$(HPMS_LIBS)" MACOSX_DEPLOYMENT_TARGET=$(MACOSX_DEPLOYMENT_TARGET)

all : \
	hpms \
	$(foreach v, $(LUA_CLIB), $(LUA_CLIB_PATH)/$(v).so)

hpms : $(foreach v, $(NET_SRC), $(CORE_PATH)/$(v)) $(LUA_STATICLIB)
	$(CC) $(CFLAGS) $^ -o $@ -I$(LUA_INC_PATH) $(EXPORT) $(HPMS_LIBS) $(HPMS_DEFINE)

$(LUA_CLIB_PATH) :
	mkdir -p $(LUA_CLIB_PATH)

SOURCE_LIB = $(addprefix lualib-src/,$(LUA_CLIB_HPMS)) $(addprefix core/,$(LUA_CLIB_HPMS_NET))
$(LUA_CLIB_PATH)/hpms.so : $(SOURCE_LIB) | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ -I$(LUA_INC_PATH) -I$(CORE_PATH) -I$(LUA_CLIB_SRC)

$(LUA_CLIB_PATH)/ltls.so : lualib-src/ltls.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -I$(LUA_INC_PATH) -L$(TLS_LIB) -I$(TLS_INC) $^ -o $@ -lssl

clean:
	rm -f hpms && \
    rm -rf $(LUA_CLIB_PATH)
