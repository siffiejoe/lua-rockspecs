package = "LuaSQL-Postgres"
version = "2.3.0.1-1"
source = {
  url = "git://github.com/keplerproject/luasql.git",
  branch = "v2.3.0",
}
description = {
   summary = "Database connectivity for Lua (Postgres driver)",
   detailed = [[
      LuaSQL is a simple interface from Lua to a DBMS. It enables a
      Lua program to connect to databases, execute arbitrary SQL statements
      and retrieve results in a row-by-row cursor fashion.
   ]],
   license = "MIT/X11",
   homepage = "http://www.keplerproject.org/luasql/"
}
dependencies = {
   "lua >= 5.1"
}
external_dependencies = {
   PGSQL = {
      header = "pg_config.h"
   }
}
build = {
   type = "builtin",
   modules = {
     ["luasql.postgres"] = {
       sources = { "src/luasql.c", "src/ls_postgres.c" },
       libraries = { "pq" },
       incdirs = { "$(PGSQL_INCDIR)" },
       libdirs = { "$(PGSQL_LIBDIR)" }
     }
   },
   patches = {
     ["c90.pathc"] = [===[
diff -Naur old/src/ls_postgres.c new/src/ls_postgres.c
--- old/src/ls_postgres.c	2014-10-15 09:01:24.456543629 +0200
+++ new/src/ls_postgres.c	2014-10-15 09:03:07.264546601 +0200
@@ -371,7 +371,7 @@
 	conn_data *conn = getconnection (L);
 	size_t len;
 	const char *from = luaL_checklstring (L, 2, &len);
-	char to[len*sizeof(char)*2+1];
+	char *to = lua_newuserdata(L, len*2+1);
 	int error;
 	len = PQescapeStringConn (conn->pg_conn, to, from, len, &error);
 	if (error == 0) { /* success ! */
]===]
   }
}
