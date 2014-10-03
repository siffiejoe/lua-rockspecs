local rev = "2322f7932064"
package = "squish"
version = "scm-0"
source = {
  url = "http://code.matthewwild.co.uk/squish/archive/"..rev..".tar.gz",
  dir = "squish-"..rev,
}
description = {
  summary = "Squish Lua libraries and apps into a single compact file",
  detailed = [[
Squish is a tool to pack many individual Lua scripts and their modules into a single Lua script. In addition it supports a range of filters to help make the produced file as small as possible.
]],
  license = "MIT",
  homepage = "http://matthewwild.co.uk/projects/squish/home",
}
dependencies = {
  "lua ~> 5.1"
}
local options = "-q --with-minify --with-uglify --with-compile --with-virtual-io"
build = {
  type = "command",
  build_command = "$(LUA) squish.lua "..options.." && "
               .. "$(LUA) squish -q gzip && "
               .. "$(LUA) squish -q debug && "
               .. "$(LUA) squish "..options.." --with-gzip --with-debug",
  install_command = "$(CP) squish make_squishy $(BINDIR)",
}

