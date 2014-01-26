local rev = "1f41c74ce686"
package = "LuaExpat"
version = "scm-0"
source = {
   url = "http://code.matthewwild.co.uk/lua-expat/archive/"..rev..".tar.gz",
   dir = "lua-expat-"..rev,
}
description = {
   summary = "XML Expat parsing",
   detailed = [[
      LuaExpat is a SAX (Simple API for XML) XML parser based on the
      Expat library.
   ]],
   license = "MIT/X11",
   homepage = "http://www.keplerproject.org/luaexpat/"
}
dependencies = {
   "lua >= 5.1, < 5.3"
}
external_dependencies = {
   EXPAT = {
      header = "expat.h"
   }
}
build = {
   type = "builtin",
   modules = {
    lxp = { 
      sources = { "src/lxplib.c" },
      libraries = { "expat" },
      incdirs = { "$(EXPAT_INCDIR)", "src/" },
      libdirs = { "$(EXPAT_LIBDIR)" }
    },
    ["lxp.lom"] = "src/lxp/lom.lua"
   },
   copy_directories = { "doc", "tests" }
}

