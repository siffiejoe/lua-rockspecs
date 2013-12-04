--[[

 This is the LuaRocks rockspec for the Lua/APR binding.

 Author: Peter Odding <peter@peterodding.com>
 Last Change: October 31, 2011
 Homepage: http://peterodding.com/code/lua/apr/

--]]

package = 'Lua-APR'
version = '0.20.6.52-1'
source = {
  url = 'http://peterodding.com/code/lua/apr/downloads/lua-apr-0.20.6-1.zip',
  md5 = '46de61aafb92217918dccffec7115252',
}
description = {
  summary = 'Apache Portable Runtime binding for Lua',
  detailed = [[
    Lua/APR is a binding to the Apache Portable Runtime (APR) library. APR
    powers software such as the Apache webserver and Subversion and Lua/APR
    makes the APR operating system interfaces available to Lua.
  ]],
  homepage = 'http://peterodding.com/code/lua/apr/',
  license = 'MIT',
}
dependencies = { 'lua >= 5.1, < 5.3' }
build = {
  type = 'make',
  variables = {
    LUA = '$(LUA)',
    LUA_DIR = '$(PREFIX)',
    LUA_LIBDIR = '$(LIBDIR)',
    LUA_SHAREDIR = '$(LUADIR)',
    CFLAGS = '$(CFLAGS) -I$(LUA_INCDIR)',
  },
  patches = {
    ["lua52.patch"] = [===[
diff -Naurp old/etc/make.lua new/etc/make.lua
--- old/etc/make.lua	2011-10-30 16:43:20.000000000 +0100
+++ new/etc/make.lua	2013-12-04 20:39:17.409080258 +0100
@@ -23,6 +23,9 @@
 
 ]]
 
+local LUA_MAJOR, LUA_MINOR = _VERSION:match( "^Lua%s+(%d+)%.(%d+)$" )
+assert( LUA_MAJOR and LUA_MINOR, "could not figure out Lua version" )
+
 -- Miscellaneous functions. {{{1
 
 -- trim() -- Trim leading/trailing whitespace from string. {{{2
@@ -101,7 +104,7 @@ end
 
 local function mergeflags(flags, command)
   local status, stdout, stderr = readcmd(command)
-  if status == 0 then
+  if status == 0 or status == true then
     for flag in words(stdout) do
       if not flags[flag] then
         local position = #flags + 1
@@ -116,12 +119,12 @@ end
 
 local function getcflags()
   local flags, count = {}, 0
-  -- Compiler flags for Lua 5.1.
-  mergeflags(flags, 'pkg-config --cflags lua5.1') -- Debian/Ubuntu
-  mergeflags(flags, 'pkg-config --cflags lua-5.1') -- FreeBSD
+  -- Compiler flags for Lua.
+  mergeflags(flags, 'pkg-config --cflags lua'..LUA_MAJOR..'.'..LUA_MINOR) -- Debian/Ubuntu
+  mergeflags(flags, 'pkg-config --cflags lua-'..LUA_MAJOR..'.'..LUA_MINOR) -- FreeBSD
   mergeflags(flags, 'pkg-config --cflags lua') -- Arch Linux
   if #flags == 0 then
-    message "Warning: Failed to determine Lua 5.1 compiler flags."
+    message("Warning: Failed to determine Lua "..LUA_MAJOR.."."..LUA_MINOR.." compiler flags.")
   end
   count = #flags
   -- Compiler flags for APR 1.
@@ -201,7 +204,8 @@ local function checkpackages()
     command = 'apt-get install'
     installedpackagescmd = [[ dpkg --list | awk '/^i/ {print $2}' ]]
     requiredpackages = [[
-      lua5.1 liblua5.1-0 liblua5.1-0-dev
+    lua]]..LUA_MAJOR..'.'..LUA_MINOR..[[ liblua]]..LUA_MAJOR..'.'..LUA_MINOR..[[-0
+    liblua]]..LUA_MAJOR..'.'..LUA_MINOR..[[-0-dev
       libapr1 libapr1-dev
       libaprutil1 libaprutil1-dev libaprutil1-dbd-sqlite3
       libapreq2 libapreq2-dev
diff -Naurp old/Makefile new/Makefile
--- old/Makefile	2011-10-31 23:40:06.000000000 +0100
+++ new/Makefile	2013-12-04 19:42:47.693169112 +0100
@@ -11,10 +11,13 @@ VERSION = $(shell grep _VERSION src/apr.
 RELEASE = 1
 PACKAGE = lua-apr-$(VERSION)-$(RELEASE)
 
+LUA_VERSION = 5.2
+LUA = lua$(LUA_VERSION)
+
 # Based on http://www.luarocks.org/en/Recommended_practices_for_Makefiles
 LUA_DIR = /usr/local
-LUA_LIBDIR = $(LUA_DIR)/lib/lua/5.1
-LUA_SHAREDIR = $(LUA_DIR)/share/lua/5.1
+LUA_LIBDIR = $(LUA_DIR)/lib/lua/$(LUA_VERSION)
+LUA_SHAREDIR = $(LUA_DIR)/share/lua/$(LUA_VERSION)
 
 # Location for generated HTML documentation.
 LUA_APR_DOCS = $(LUA_DIR)/share/doc/lua-apr
@@ -65,8 +68,8 @@ SOURCES = src/base64.c \
 
 # Determine compiler flags and linker flags for external dependencies using a
 # combination of pkg-config, apr-1-config, apu-1-config and apreq2-config.
-override CFLAGS += $(shell lua etc/make.lua --cflags)
-override LFLAGS += $(shell lua etc/make.lua --lflags)
+override CFLAGS += $(shell $(LUA) etc/make.lua --cflags)
+override LFLAGS += $(shell $(LUA) etc/make.lua --lflags)
 
 # Create debug builds by default but enable release
 # builds using the command line "make DO_RELEASE=1".
@@ -90,19 +93,19 @@ default: $(BINARY_MODULE)
 
 # Build the binary module.
 $(BINARY_MODULE): $(OBJECTS) Makefile
-	$(CC) -shared -o $@ $(OBJECTS) $(LFLAGS) || lua etc/make.lua --check
+	$(CC) -shared -o $@ $(OBJECTS) $(LFLAGS) || $(LUA) etc/make.lua --check
 
 # Build the standalone libapreq2 binding.
 $(APREQ_BINARY): etc/apreq_standalone.c Makefile
-	$(CC) -Wall -shared -o $@ $(CFLAGS) -fPIC etc/apreq_standalone.c $(LFLAGS) || lua etc/make.lua --check
+	$(CC) -Wall -shared -o $@ $(CFLAGS) -fPIC etc/apreq_standalone.c $(LFLAGS) || $(LUA) etc/make.lua --check
 
 # Compile individual source code files to object files.
 $(OBJECTS): %.o: %.c src/lua_apr.h Makefile
-	$(CC) -Wall -c $(CFLAGS) -fPIC $< -o $@ || lua etc/make.lua --check
+	$(CC) -Wall -c $(CFLAGS) -fPIC $< -o $@ || $(LUA) etc/make.lua --check
 
 # Always try to regenerate the error handling module.
 src/errno.c: etc/errors.lua Makefile
-	@lua etc/errors.lua
+	@$(LUA) etc/errors.lua
 
 # Install the Lua/APR binding under $LUA_DIR.
 install: $(BINARY_MODULE) docs
@@ -125,11 +128,11 @@ uninstall:
 
 # Run the test suite.
 test: install
-	export LD_PRELOAD=/lib/libSegFault.so; lua -e "require 'apr.test' ()"
+	export LD_PRELOAD=/lib/libSegFault.so; $(LUA) -e "require 'apr.test' ()"
 
 # Run the test suite under Valgrind to detect and analyze errors.
 valgrind:
-	valgrind -q --track-origins=yes --leak-check=full lua -e "require 'apr.test' ()"
+	valgrind -q --track-origins=yes --leak-check=full $(LUA) -e "require 'apr.test' ()"
 
 # Create or update test coverage report using "lcov".
 coverage:
@@ -140,10 +143,10 @@ coverage:
 
 # Convert the Markdown documents to HTML.
 docs: doc/docs.md $(SOURCE_MODULE) $(SOURCES)
-	@lua etc/wrap.lua doc/docs.md doc/docs.html
-	@lua etc/wrap.lua README.md doc/readme.html
-	@lua etc/wrap.lua NOTES.md doc/notes.html
-	@lua etc/wrap.lua TODO.md doc/todo.html
+	@$(LUA) etc/wrap.lua doc/docs.md doc/docs.html
+	@$(LUA) etc/wrap.lua README.md doc/readme.html
+	@$(LUA) etc/wrap.lua NOTES.md doc/notes.html
+	@$(LUA) etc/wrap.lua TODO.md doc/todo.html
 
 # Extract the documentation from the source code and generate a Markdown file
 # containing all documentation including coverage statistics (if available).
@@ -155,13 +158,13 @@ docs: doc/docs.md $(SOURCE_MODULE) $(SOU
 # documentation and lose the coverage statistics...
 doc/docs.md: etc/docs.lua
 	@[ -d doc ] || mkdir doc
-	@lua etc/docs.lua > doc/docs.md
+	@$(LUA) etc/docs.lua > doc/docs.md
 
 # Create a profiling build, run the test suite, generate documentation
 # including test coverage, then clean the intermediate files.
 package_prerequisites: clean
 	@echo Collecting coverage statistics using profiling build
-	@export PROFILING=1; lua etc/buildbot.lua --local
+	@export PROFILING=1; $(LUA) etc/buildbot.lua --local
 	@echo Generating documentation including coverage statistics
 	@rm -f doc/docs.md; make --no-print-directory docs
 
diff -Naurp old/Makefile.win new/Makefile.win
--- old/Makefile.win	2011-10-31 23:40:06.000000000 +0100
+++ new/Makefile.win	2013-12-04 19:45:16.385165215 +0100
@@ -11,7 +11,10 @@
 
 # The directories where "lua.h" and "lua51.lib" can be found (these defaults
 # are based on the directory structure used by Lua for Windows v5.1.4-40).
-LUA_DIR = C:\Program Files\Lua\5.1
+LUA_VERSION = 5.2
+LUA_LIB = lua52.lib
+LUA = lua
+LUA_DIR = C:\Program Files\Lua\$(LUA_VERSION)
 LUA_INCDIR = $(LUA_DIR)\include
 LUA_LIBDIR = $(LUA_DIR)\clibs
 LUA_LINKDIR = $(LUA_DIR)\lib
@@ -39,7 +42,7 @@ APREQ_BINARY = apreq.dll
 
 # Compiler and linker flags composed from the above settings.
 CFLAGS = "/I$(LUA_INCDIR)" "/I$(APR_INCDIR)" "/I$(APU_INCDIR)" /D"_CRT_SECURE_NO_DEPRECATE"
-LFLAGS = "/LIBPATH:$(LUA_LINKDIR)" lua51.lib "/LIBPATH:$(APR_LIBDIR)" libapr-1.lib "/LIBPATH:$(APU_LIBDIR)" libaprutil-1.lib Wldap32.Lib
+LFLAGS = "/LIBPATH:$(LUA_LINKDIR)" $(LUA_LIB) "/LIBPATH:$(APR_LIBDIR)" libapr-1.lib "/LIBPATH:$(APU_LIBDIR)" libaprutil-1.lib Wldap32.Lib
 
 # Names of compiled object files (the individual lines enable automatic
 # rebasing between git feature branches and the master branch).
@@ -109,7 +112,7 @@ $(OBJECTS): Makefile
 
 # Always try to regenerate the error handling module.
 src\errno.c: etc\errors.lua
-	@LUA etc\errors.lua > src\errno.c.new && MOVE src\errno.c.new src\errno.c || EXIT /B 0
+	@$(LUA) etc\errors.lua > src\errno.c.new && MOVE src\errno.c.new src\errno.c || EXIT /B 0
 
 # Install the Lua/APR binding and external dependencies.
 install: $(BINARY_MODULE)
@@ -139,11 +142,11 @@ uninstall:
 
 # Run the test suite.
 test: install
-	LUA -e "require 'apr.test' ()"
+	$(LUA) -e "require 'apr.test' ()"
 
 # Debug the test suite using NTSD.
 debug:
-	NTSD -g LUA -e "require 'apr.test' ()"
+	NTSD -g $(LUA) -e "require 'apr.test' ()"
 
 # Clean generated files from working directory.
 clean:
diff -Naurp old/src/crypt.c new/src/crypt.c
--- old/src/crypt.c	2011-07-28 10:20:36.000000000 +0200
+++ new/src/crypt.c	2013-12-04 19:46:39.065163047 +0100
@@ -436,14 +436,14 @@ static int sha1_gc(lua_State *L)
 
 /* }}}1 */
 
-static luaL_reg md5_methods[] = {
+static luaL_Reg md5_methods[] = {
   { "reset", md5_reset },
   { "update", md5_update },
   { "digest", md5_digest },
   { NULL, NULL },
 };
 
-static luaL_reg md5_metamethods[] = {
+static luaL_Reg md5_metamethods[] = {
   { "__tostring", md5_tostring },
   { "__eq", objects_equal },
   { "__gc", md5_gc },
@@ -458,14 +458,14 @@ lua_apr_objtype lua_apr_md5_type = {
   md5_metamethods          /* metamethods table */
 };
 
-static luaL_reg sha1_methods[] = {
+static luaL_Reg sha1_methods[] = {
   { "reset", sha1_reset },
   { "update", sha1_update },
   { "digest", sha1_digest },
   { NULL, NULL },
 };
 
-static luaL_reg sha1_metamethods[] = {
+static luaL_Reg sha1_metamethods[] = {
   { "__tostring", sha1_tostring },
   { "__eq", objects_equal },
   { "__gc", sha1_gc },
diff -Naurp old/src/dbd.c new/src/dbd.c
--- old/src/dbd.c	2011-07-28 10:20:36.000000000 +0200
+++ new/src/dbd.c	2013-12-04 19:47:54.797161062 +0100
@@ -1073,14 +1073,14 @@ static int dbd_gc(lua_State *L)
 
 /* Database driver objects. {{{2 */
 
-static luaL_reg dbd_metamethods[] = {
+static luaL_Reg dbd_metamethods[] = {
   { "__tostring", dbd_tostring },
   { "__eq", objects_equal },
   { "__gc", dbd_gc },
   { NULL, NULL }
 };
 
-static luaL_reg dbd_methods[] = {
+static luaL_Reg dbd_methods[] = {
   /* Generic methods. */
   { "open", dbd_open },
   { "dbname", dbd_dbname },
@@ -1108,7 +1108,7 @@ lua_apr_objtype lua_apr_dbd_type = {
 
 /* Result set objects. {{{2 */
 
-static luaL_reg dbr_metamethods[] = {
+static luaL_Reg dbr_metamethods[] = {
   { "__len", dbr_len },
   { "__tostring", dbr_tostring },
   { "__eq", objects_equal },
@@ -1120,7 +1120,7 @@ static luaL_reg dbr_metamethods[] = {
   { NULL, NULL }
 };
 
-static luaL_reg dbr_methods[] = {
+static luaL_Reg dbr_methods[] = {
   { "columns", dbr_columns },
   { "tuple", dbr_tuple },
   { "tuples", dbr_tuples },
@@ -1140,14 +1140,14 @@ lua_apr_objtype lua_apr_dbr_type = {
 
 /* Prepared statement objects. {{{2 */
 
-static luaL_reg dbp_metamethods[] = {
+static luaL_Reg dbp_metamethods[] = {
   { "__tostring", dbp_tostring },
   { "__eq", objects_equal },
   { "__gc", dbp_gc },
   { NULL, NULL }
 };
 
-static luaL_reg dbp_methods[] = {
+static luaL_Reg dbp_methods[] = {
   { "query", dbp_query },
   { "select", dbp_select },
   { NULL, NULL }
diff -Naurp old/src/dbm.c new/src/dbm.c
--- old/src/dbm.c	2011-07-28 10:20:36.000000000 +0200
+++ new/src/dbm.c	2013-12-04 19:48:08.137160713 +0100
@@ -338,7 +338,7 @@ int dbm_gc(lua_State *L)
 
 /* }}} */
 
-luaL_reg dbm_methods[] = {
+luaL_Reg dbm_methods[] = {
   { "close", dbm_close },
   { "delete", dbm_delete },
   { "exists", dbm_exists },
@@ -349,7 +349,7 @@ luaL_reg dbm_methods[] = {
   { NULL, NULL },
 };
 
-luaL_reg dbm_metamethods[] = {
+luaL_Reg dbm_metamethods[] = {
   { "__tostring", dbm_tostring },
   { "__eq", objects_equal },
   { "__gc", dbm_gc },
diff -Naurp old/src/io_net.c new/src/io_net.c
--- old/src/io_net.c	2011-07-28 10:20:36.000000000 +0200
+++ new/src/io_net.c	2013-12-04 19:48:15.677160515 +0100
@@ -670,7 +670,7 @@ static int socket_gc(lua_State *L)
 
 /* }}} */
 
-luaL_reg socket_methods[] = {
+luaL_Reg socket_methods[] = {
   { "bind", socket_bind },
   { "listen", socket_listen },
   { "accept", socket_accept },
@@ -690,7 +690,7 @@ luaL_reg socket_methods[] = {
   { NULL, NULL },
 };
 
-luaL_reg socket_metamethods[] = {
+luaL_Reg socket_metamethods[] = {
   { "__tostring", socket_tostring },
   { "__eq", objects_equal },
   { "__gc", socket_gc },
diff -Naurp old/src/ldap.c new/src/ldap.c
--- old/src/ldap.c	2011-10-29 00:58:28.000000000 +0200
+++ new/src/ldap.c	2013-12-04 20:50:34.577062508 +0100
@@ -711,7 +711,7 @@ static int lua_apr_ldap_option_get(lua_S
   type = ldap_option_type(optidx);
   if (type == LUA_APR_LDAP_TB) {
     /* Boolean. */
-    lua_pushboolean(L, (void*)value.boolean == LDAP_OPT_ON);
+    lua_pushboolean(L, value.boolean);
   } else if (type == LUA_APR_LDAP_TI) {
     /* Integer. */
     lua_pushinteger(L, value.integer);
@@ -1011,13 +1011,13 @@ static int ldap_gc(lua_State *L)
 
 /* }}}1 */
 
-static luaL_reg ldap_metamethods[] = {
+static luaL_Reg ldap_metamethods[] = {
   { "__tostring", ldap_tostring },
   { "__gc", ldap_gc },
   { NULL, NULL }
 };
 
-static luaL_reg ldap_methods[] = {
+static luaL_Reg ldap_methods[] = {
   { "bind", lua_apr_ldap_bind },
   { "unbind", lua_apr_ldap_unbind },
   { "option_get", lua_apr_ldap_option_get },
diff -Naurp old/src/lua_apr.c new/src/lua_apr.c
--- old/src/lua_apr.c	2011-10-29 01:29:56.000000000 +0200
+++ new/src/lua_apr.c	2013-12-04 19:56:10.945148057 +0100
@@ -14,9 +14,6 @@
 #include <apreq_version.h>
 #endif
 
-/* Used to make sure that APR is only initialized once. */
-static int apr_was_initialized = 0;
-
 /* List of all userdata types exposed to Lua by the binding. */
 lua_apr_objtype *lua_apr_types[] = {
   &lua_apr_file_type,
@@ -42,6 +39,15 @@ lua_apr_objtype *lua_apr_types[] = {
   NULL
 };
 
+
+static int apr_handle_gc(lua_State *L) {
+  int *v = lua_touserdata(L, 1);
+  if (*v)
+    apr_terminate();
+  return 0;
+}
+
+
 /* luaopen_apr_core() initializes the binding and library. {{{1 */
 
 LUA_APR_EXPORT int luaopen_apr_core(lua_State *L)
@@ -225,14 +231,25 @@ LUA_APR_EXPORT int luaopen_apr_core(lua_
     { NULL, NULL }
   };
 
-  /* Initialize the library (only once per process). */
-  if (!apr_was_initialized) {
-    if ((status = apr_initialize()) != APR_SUCCESS)
-      raise_error_status(L, status);
-    if (atexit(apr_terminate) != 0)
-      raise_error_message(L, "Lua/APR: Failed to register apr_terminate()");
-    apr_was_initialized = 1;
-  }
+  luaL_Reg apr_handle_metamethods[] = {
+    { "__gc", apr_handle_gc },
+    { NULL, NULL }
+  };
+
+  int *init_flag = lua_newuserdata(L, sizeof(int));
+  *init_flag = 0;
+  lua_newtable(L);
+  luaL_register(L, NULL, apr_handle_metamethods);
+  lua_setmetatable(L, -2); /* pops metatable for init_flag */
+  lua_pushvalue(L, -1);
+  lua_pushvalue(L, -2); /* init_flag on stack 3 times */
+  lua_settable(L, LUA_REGISTRYINDEX); /* R[init_flag]=init_flag */
+
+  /* Initialize the library. */
+  if ((status = apr_initialize()) != APR_SUCCESS)
+    raise_error_status(L, status);
+  *init_flag = 1; /* activate destructor apr_terminate() */
+  lua_pop(L, 1); /* remove remaining init_flag from stack */
 
   /* Create the `scratch' memory pool for global APR functions (as opposed to
    * object methods) and install a __gc metamethod to detect when the Lua state
diff -Naurp old/src/lua_apr.h new/src/lua_apr.h
--- old/src/lua_apr.h	2011-07-28 10:20:36.000000000 +0200
+++ new/src/lua_apr.h	2013-12-04 20:01:36.413139525 +0100
@@ -25,6 +25,20 @@
 #include <apr_queue.h>
 #include <apr_atomic.h>
 
+/* Lua 5.2 compatibility */
+#if LUA_VERSION_NUM >= 502
+#define lua_objlen(L, i) (lua_rawlen(L, i))
+#define lua_strlen(L, i) (lua_rawlen(L, i))
+#define lua_equal(L, a, b) (lua_compare(L, a, b, LUA_OPEQ))
+#define luaL_typerror(L, narg, tname) \
+  (luaL_argerror(L, narg, lua_pushfstring(L, "", tname, lua_typename(L, lua_type(L, narg)))))
+#define luaL_register(L, n, l) \
+  (assert((n) == NULL || !"luaL_register call with non-NULL libname"), luaL_setfuncs(L, l, 0))
+#define lua_getfenv(L, i) (lua_getuservalue(L, i))
+#define lua_setfenv(L, i) (lua_setuservalue(L, i))
+#endif
+
+
 /* Macro definitions. {{{1 */
 
 /* Enable redefining exporting of loader function, with sane defaults. */
diff -Naurp old/src/memcache.c new/src/memcache.c
--- old/src/memcache.c	2011-07-28 10:20:36.000000000 +0200
+++ new/src/memcache.c	2013-12-04 19:48:38.205159924 +0100
@@ -561,7 +561,7 @@ static int mc_gc(lua_State *L)
 
 /* Internal object definitions. {{{1 */
 
-static luaL_reg mc_methods[] = {
+static luaL_Reg mc_methods[] = {
   { "hash", mc_hash },
   { "find_server_hash", mc_find_server_hash },
   { "add_server", mc_add_server },
@@ -580,7 +580,7 @@ static luaL_reg mc_methods[] = {
   { NULL, NULL }
 };
 
-static luaL_reg mc_metamethods[] = {
+static luaL_Reg mc_metamethods[] = {
   { "__tostring", mc_tostring },
   { "__gc", mc_gc },
   { NULL, NULL }
@@ -594,11 +594,11 @@ lua_apr_objtype lua_apr_memcache_type =
   mc_metamethods                   /* metamethods table */
 };
 
-static luaL_reg ms_methods[] = {
+static luaL_Reg ms_methods[] = {
   { NULL, NULL }
 };
 
-static luaL_reg ms_metamethods[] = {
+static luaL_Reg ms_metamethods[] = {
   { "__tostring", ms_tostring },
   { NULL, NULL }
 };
diff -Naurp old/src/shm.c new/src/shm.c
--- old/src/shm.c	2011-07-28 10:20:36.000000000 +0200
+++ new/src/shm.c	2013-12-04 19:48:49.169159637 +0100
@@ -274,14 +274,14 @@ static int shm_gc(lua_State *L)
 
 /* }}}1 */
 
-static luaL_reg shm_metamethods[] = {
+static luaL_Reg shm_metamethods[] = {
   { "__tostring", shm_tostring },
   { "__eq", objects_equal },
   { "__gc", shm_gc },
   { NULL, NULL }
 };
 
-static luaL_reg shm_methods[] = {
+static luaL_Reg shm_methods[] = {
   { "read", shm_read },
   { "write", shm_write },
   { "seek", shm_seek },
diff -Naurp old/src/thread.c new/src/thread.c
--- old/src/thread.c	2011-07-28 10:20:36.000000000 +0200
+++ new/src/thread.c	2013-12-04 20:03:07.345137142 +0100
@@ -71,7 +71,7 @@ static int error_handler(lua_State *L)
 {
   if (!lua_isstring(L, 1)) /* 'message' not a string? */
     return 1; /* keep it intact */
-  lua_getfield(L, LUA_GLOBALSINDEX, "debug");
+  lua_getglobal(L, "debug");
   if (!lua_istable(L, -1)) {
     lua_pop(L, 1);
     return 1;
diff -Naurp old/src/xml.c new/src/xml.c
--- old/src/xml.c	2011-07-28 10:20:36.000000000 +0200
+++ new/src/xml.c	2013-12-04 19:48:55.053159483 +0100
@@ -324,7 +324,7 @@ static int xml_gc(lua_State *L)
 
 /* }}}1 */
 
-static luaL_reg xml_methods[] = {
+static luaL_Reg xml_methods[] = {
   { "feed", xml_feed },
   { "done", xml_done },
   { "getinfo", xml_getinfo },
@@ -333,7 +333,7 @@ static luaL_reg xml_methods[] = {
   { NULL, NULL }
 };
 
-static luaL_reg xml_metamethods[] = {
+static luaL_Reg xml_metamethods[] = {
   { "__tostring", xml_tostring },
   { "__eq", objects_equal },
   { "__gc", xml_gc },
diff -Naurp old/test/helpers.lua new/test/helpers.lua
--- old/test/helpers.lua	2011-07-28 10:20:36.000000000 +0200
+++ new/test/helpers.lua	2013-12-04 20:05:09.345133944 +0100
@@ -24,6 +24,15 @@ function print(...)
   io.stderr:write(table.concat(t, ' ') .. '\n')
 end
 
+function helpers.luaexec() -- {{{1
+  local i, v = 0
+  repeat
+    v = arg[ i ]
+    i = i - 1
+  until arg[ i ] == nil
+  return v
+end
+
 function helpers.message(s, ...) -- {{{1
   io.stderr:write(string.format(s, ...))
   io.stderr:flush()
@@ -91,7 +100,7 @@ function helpers.ld_preload_trick(script
   apr.env_set('LD_PRELOAD', apr.filepath_list_merge(libs))
 
   -- Now run the test in a child process where $LD_PRELOAD applies.
-  local child = assert(apr.proc_create 'lua')
+  local child = assert(apr.proc_create(helpers.luaexec()))
   assert(child:cmdtype_set 'shellcmd/env')
   assert(child:exec { helpers.scriptpath(script) })
   local dead, reason, code = assert(child:wait(true))
diff -Naurp old/test/io_net.lua new/test/io_net.lua
--- old/test/io_net.lua	2011-07-28 10:20:36.000000000 +0200
+++ new/test/io_net.lua	2013-12-04 20:05:51.781132831 +0100
@@ -22,7 +22,7 @@ local address = assert(apr.host_to_addr(
 assert(apr.addr_to_host(address))
 
 -- Test socket:bind(), socket:listen() and socket:accept().
-local server = assert(apr.proc_create 'lua')
+local server = assert(apr.proc_create(helpers.luaexec()))
 local port = 12345
 local signalfile = helpers.tmpname()
 local scriptfile = helpers.scriptpath 'io_net-server.lua'
diff -Naurp old/test/proc.lua new/test/proc.lua
--- old/test/proc.lua	2011-07-28 10:20:34.000000000 +0200
+++ new/test/proc.lua	2013-12-04 20:06:19.365132108 +0100
@@ -17,7 +17,7 @@ end
 local helpers = require 'apr.test.helpers'
 
 local function newchild(cmdtype, script, env)
-  local child = assert(apr.proc_create 'lua')
+  local child = assert(apr.proc_create(helpers.luaexec()))
   assert(child:cmdtype_set(cmdtype))
   if env then child:env_set(env) end
   assert(child:io_set('child-block', 'parent-block', 'parent-block'))
@@ -67,7 +67,7 @@ local namedpipe = helpers.tmpname()
 local namedmsg = "Hello world over a named pipe!"
 local status, errmsg, errcode = apr.namedpipe_create(namedpipe)
 if errcode ~= 'ENOTIMPL' then
-  local child = assert(apr.proc_create 'lua')
+  local child = assert(apr.proc_create(helpers.luaexec()))
   assert(child:cmdtype_set('shellcmd/env'))
   assert(child:exec { helpers.scriptpath 'io_file-named_pipe.lua', namedpipe, namedmsg })
   local handle = assert(apr.file_open(namedpipe, 'r'))
diff -Naurp old/test/shm.lua new/test/shm.lua
--- old/test/shm.lua	2011-07-28 10:20:36.000000000 +0200
+++ new/test/shm.lua	2013-12-04 20:07:05.353130903 +0100
@@ -36,7 +36,7 @@ local shm_file = assert(apr.shm_create(s
 assert(tostring(shm_file):find '^shared memory %([0x%x]+%)$')
 
 -- Launch child process.
-local child = assert(apr.proc_create('lua'))
+local child = assert(apr.proc_create(helpers.luaexec()))
 assert(child:cmdtype_set 'shellcmd/env')
 assert(child:exec { helpers.scriptpath 'shm-child.lua', shm_path, tmp_path })
 assert(child:wait(true))
diff -Naurp old/test/signal.lua new/test/signal.lua
--- old/test/signal.lua	2011-07-28 10:20:36.000000000 +0200
+++ new/test/signal.lua	2013-12-04 20:07:29.949130258 +0100
@@ -57,7 +57,7 @@ if apr.platform_get() ~= 'WIN32' then
 
   -- Spawn a child process that dies.
   local function spawn()
-    local child = assert(apr.proc_create 'lua')
+    local child = assert(apr.proc_create(helpers.luaexec()))
     assert(child:cmdtype_set 'program/env/path')
     assert(child:exec { '-e', 'os.exit(0)' })
     assert(child:wait(true))
diff -Naurp old/test/thread.lua new/test/thread.lua
--- old/test/thread.lua	2011-07-28 10:20:36.000000000 +0200
+++ new/test/thread.lua	2013-12-04 20:08:02.097129416 +0100
@@ -24,7 +24,7 @@ if not apr.thread_create then
   return false
 end
 
-local child = assert(apr.proc_create 'lua')
+local child = assert(apr.proc_create(helpers.luaexec()))
 assert(child:cmdtype_set 'shellcmd/env')
 assert(child:exec { helpers.scriptpath 'thread-child.lua' })
 local dead, reason, code = assert(child:wait(true))
diff -Naurp old/test/thread_queue.lua new/test/thread_queue.lua
--- old/test/thread_queue.lua	2011-07-28 10:20:36.000000000 +0200
+++ new/test/thread_queue.lua	2013-12-04 20:08:21.505128907 +0100
@@ -24,7 +24,7 @@ if not apr.thread_queue then
   return false
 end
 
-local child = assert(apr.proc_create 'lua')
+local child = assert(apr.proc_create(helpers.luaexec()))
 assert(child:cmdtype_set 'shellcmd/env')
 assert(child:exec { helpers.scriptpath 'thread_queue-child.lua' })
 local dead, reason, code = assert(child:wait(true))
]===]
  }
}

-- vim: ft=lua ts=2 sw=2 et
