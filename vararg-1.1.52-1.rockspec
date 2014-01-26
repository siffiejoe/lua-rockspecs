package="vararg"
version="1.1.52-1"
source = {
   url = "http://www.tecgraf.puc-rio.br/~maia/lua/vararg-1.1.tar.gz",
   md5 = "93d556b38e339c7a3c0a71ec925a23ec",
}
description = {
   summary = "Manipulation of variable arguments",
   detailed = [[
      'vararg' is a Lua library for manipulation of variable arguments (vararg) of
      functions. These functions basically allows you to do things with vararg that
      cannot be efficiently done in pure Lua, but can be easily done through the C API.
   ]],
   homepage = "http://www.tecgraf.puc-rio.br/~maia/lua/vararg/",
   license = "MIT/X11"
}
dependencies = {
   "lua >= 5.1, < 5.3"
}

build = {
   type = "builtin",
   modules = {
      vararg = {
         sources = "vararg.c",
      },
   },
   patches = {
      ["lua52.patch"] = [==[
diff -Naurp old/vararg.c new/vararg.c
--- old/vararg.c	2014-01-26 21:52:39.146317389 +0100
+++ new/vararg.c	2014-01-26 21:55:23.498313081 +0100
@@ -28,6 +28,9 @@ concat(f1,f2,...)  --> return all the va
 #include "lua.h"
 #include "lauxlib.h"
 
+#if LUA_VERSION_NUM >= 502
+#  define luaL_register( L, n, r )  luaL_newlib( L, r )
+#endif
 
 static int _optindex(lua_State *L, int arg, int top, int def) {
 	int idx = (def ? luaL_optint(L, arg, def) : luaL_checkint(L, arg));
]==]
   }
}

