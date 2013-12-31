package = "LuaCURL"
version = "1.2.1.52-1"
source = {
   url = "http://luaforge.net/frs/download.php/3342/luacurl-1.2.1.zip",
   md5 = "4c83710a0fc5ca52818e5ec0101c4395"
}
description = {
   summary = "Lua module binding CURL",
   detailed = [[
      LuaCURL is Lua 5.x compatible module providing Internet browsing
      capabilities based on the CURL library. The module interface
      follows strictly the CURl architecture and is very easy to use
      if the programmer has already experience with CURL.
   ]],
   homepage = "http://luaforge.net/projects/luacurl/",
   license = "MIT/X11"
}
dependencies = {
   "lua >= 5.1, < 5.3"
}
external_dependencies = {
   CURL = {
      header = "curl/curl.h"
   }
}
build = {
   type = "builtin",
   modules = {
     luacurl = {
       sources = { "luacurl.c" },
       libraries = { "curl" },
       incdirs = { "$(CURL_INCDIR)" },
       libdirs = { "$(CURL_LIBDIR)" },
     }
   },
   patches = {
     ["fix.patch"] = [==[
diff -Naurp old/luacurl.c new/luacurl.c
--- old/luacurl.c	2013-12-31 12:07:27.029274729 +0100
+++ new/luacurl.c	2013-12-31 12:06:42.013272977 +0100
@@ -24,8 +24,17 @@
 
 #if !defined(LUA_VERSION_NUM) || (LUA_VERSION_NUM <= 500)
 #define luaL_checkstring luaL_check_string 
+#elif LUA_VERSION_NUM >= 502
+#define luaL_reg luaL_Reg
+#define lua_strlen lua_rawlen
+static void luaL_openlib( lua_State* L, char const* ln, luaL_Reg const* l, int nup ) {
+  if( ln )
+    lua_newtable( L );
+  luaL_setfuncs( L, l, nup );
+}
 #endif
 
+
 #ifdef __cplusplus
 extern "C" {
 #endif
@@ -626,7 +635,7 @@ static int lcurl_easy_setopt(lua_State*
 #endif
 					else
 					{
-						/* When the option code is any of CURLOPT_xxxDATA and the argument is table, 
+						/* When the option code is any of CURLOPT_xxxDATA and the argument is table, */
 						/* userdata or function set the curl option value to the lua object reference */
 						v.nval=ref;
 					}
]==]
   }
}
