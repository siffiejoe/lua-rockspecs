package="slnunicode"
version="1.1.52-1"
source = {
   url = "http://luaforge.net/frs/download.php/1693/slnunicode-1.1.tar.bz2",
   md5 = "6cb97097b6a61e4232701dcd7948847c",
}
description = {
   summary = "A Unicode library",
   detailed = [[
      A Unicode support library for Lua, developed for
      the Selene database project.
   ]],
   homepage = "http://luaforge.net/projects/sln/",
   license = "Tcl License + MIT/X11"
}
dependencies = {
   "lua >= 5.1, < 5.3"
}

build = {
   type = "builtin",
   modules = {
      unicode = {
         "slnunico.c",
         "slnudata.c"
      }
   },
   patches = {

["fix.patch"] = [[
diff -Naurp old/slnunico.c new/slnunico.c
--- old/slnunico.c	2013-12-04 19:01:39.217233818 +0100
+++ new/slnunico.c	2013-12-04 19:01:31.273234026 +0100
@@ -1,7 +1,7 @@
 /*
 *	Selene Unicode/UTF-8
 *	This additions
-*	Copyright (c) 2005 Malete Partner, Berlin, partner@malete.org
+*	Copyright (c) 2005-2011 Malete Partner, Berlin, partner@malete.org
 *	Available under "Lua 5.0 license", see http://www.lua.org/license.html#5
 *	$Id: slnunico.c,v 1.5 2006/07/26 17:20:04 paul Exp $
 *
@@ -94,6 +94,9 @@ http://www.unicode.org/Public/UNIDATA/Pr
 # define SLN_UNICODENAME "unicode"
 #endif
 
+#if LUA_VERSION_NUM < 502
+#  define luaL_setfuncs(L,l,nup) luaI_openlib(L,NULL,l,nup)
+#endif 
 
 #include "slnudata.c"
 #define charinfo(c) (~0xFFFF&(c) ? 0 : GetUniCharInfo(c)) /* BMP only */
@@ -429,6 +432,49 @@ static int str_dump (lua_State *L) {
 */
 
 
+/*
+** maximum number of captures that a pattern can do during
+** pattern-matching. This limit is arbitrary.
+*/
+#if !defined(LUA_MAXCAPTURES)
+#define LUA_MAXCAPTURES		32
+#endif
+
+/*
+** LUA_INTFRMLEN is the length modifier for integer conversions in
+** 'string.format'; LUA_INTFRM_T is the integer type corresponding to
+** the previous length
+*/
+#if !defined(LUA_INTFRMLEN)	/* { */
+#if defined(LUA_USE_LONGLONG)
+
+#define LUA_INTFRMLEN           "ll"
+#define LUA_INTFRM_T            long long
+
+#else
+
+#define LUA_INTFRMLEN           "l"
+#define LUA_INTFRM_T            long
+
+#endif
+#endif				/* } */
+
+#define MAX_UINTFRM	((lua_Number)(~(unsigned LUA_INTFRM_T)0))
+#define MAX_INTFRM	((lua_Number)((~(unsigned LUA_INTFRM_T)0)/2))
+#define MIN_INTFRM	(-(lua_Number)((~(unsigned LUA_INTFRM_T)0)/2) - 1)
+
+/*
+** LUA_FLTFRMLEN is the length modifier for float conversions in
+** 'string.format'; LUA_FLTFRM_T is the float type corresponding to
+** the previous length
+*/
+#if !defined(LUA_FLTFRMLEN)
+
+#define LUA_FLTFRMLEN           ""
+#define LUA_FLTFRM_T            double
+
+#endif
+
 #define CAP_UNFINISHED	(-1)
 #define CAP_POSITION	(-2)
 
@@ -1282,7 +1328,7 @@ int ext_uni_match ( void *state, const c
 }
 #endif
 
-static const luaL_reg uniclib[] = {
+static const luaL_Reg uniclib[] = {
 	{"byte", unic_byte}, /* no cluster ! */
 	{"char", unic_char},
 	{"dump", str_dump},
@@ -1318,12 +1364,13 @@ static void createmetatable (lua_State *
 ** Open string library
 */
 LUALIB_API int luaopen_unicode (lua_State *L) {
-	/* register unicode itself so require("unicode") works */
-	luaL_register(L, SLN_UNICODENAME,
-		uniclib + (sizeof uniclib/sizeof uniclib[0] - 1)); /* empty func list */
-	lua_pop(L, 1);
-	lua_pushinteger(L, MODE_ASCII);
-	luaI_openlib(L, SLN_UNICODENAME ".ascii", uniclib, 1);
+  lua_newtable(L);
+#define PUSHLIB(mode, name) \
+  ( lua_newtable(L), \
+    lua_pushinteger(L, MODE_##mode), \
+    luaL_setfuncs(L, uniclib, 1), \
+    lua_setfield(L, -2, #name) )
+  PUSHLIB(ASCII, ascii);
 #ifdef SLNUNICODE_AS_STRING
 #if defined(LUA_COMPAT_GFIND)
 	lua_getfield(L, -1, "gmatch");
@@ -1332,14 +1379,12 @@ LUALIB_API int luaopen_unicode (lua_Stat
 #ifdef STRING_WITH_METAT
 	createmetatable(L);
 #endif
-	lua_setfield(L, LUA_GLOBALSINDEX, "string");
+        lua_setglobal(L, "string");
 #endif
-	lua_pushinteger(L, MODE_LATIN);
-	luaI_openlib(L, SLN_UNICODENAME ".latin1", uniclib, 1);
-	lua_pushinteger(L, MODE_GRAPH);
-	luaI_openlib(L, SLN_UNICODENAME ".grapheme", uniclib, 1);
-	lua_pushinteger(L, MODE_UTF8);
-	luaI_openlib(L, SLN_UNICODENAME ".utf8", uniclib, 1);
+        PUSHLIB(LATIN, latin1);
+        PUSHLIB(GRAPH, grapheme);
+        PUSHLIB(UTF8, utf8);
+#undef PUSHLIB
 #ifdef WANT_EXT_MATCH
 	{
 		unsigned i;
]]
   }

}

