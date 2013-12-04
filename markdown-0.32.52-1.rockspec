package = "Markdown"
version = "0.32.52-1"
source = {
   url = "http://www.frykholm.se/files/markdown-0.32.tar.gz",
   dir = "."
}
description = {
   summary = "Markdown text-to-html markup system.",
   detailed = [[
      A pure-lua implementation of the Markdown text-to-html markup system.
   ]],
   license = "MIT",
   homepage = "http://www.frykholm.se/files/markdown.lua"
}
dependencies = {
   "lua >= 5.1, < 5.3",
}
build = {
   type = "builtin",
   modules = {
      markdown = "markdown.lua",
   },
   install = {
      bin = {
         [ "markdown.lua" ] = "markdown.lua"
      },
   },
   patches = {
["01-markdown_lua52.patch"] = [=[
diff -Naurd old/markdown.lua new/markdown.lua
--- old/markdown.lua	2013-04-18 16:18:35.302951485 +0200
+++ new/markdown.lua	2013-04-18 22:23:27.675584199 +0200
@@ -1,7 +1,7 @@
 #!/usr/bin/env lua
 
 --[[
-# markdown.lua -- version 0.32
+# markdown.lua -- version 0.32-nosetfenv
 
 <http://www.frykholm.se/files/markdown.lua>
 
@@ -21,7 +21,7 @@
 
 ## Usage
 
-    require "markdown"
+    local markdown = require "markdown"
     markdown(source)
 
 ``markdown.lua`` exposes a single global function named ``markdown(s)`` which applies the
@@ -62,6 +62,8 @@
 
 ## Version history
 
+-	**0.32-nosetfenv** -- 29 Nov 2011
+	- Removed use of setfenv, fixed global param, Lua 5.2 compatibility
 -	**0.32** -- 31 May 2008
 	- Fix for links containing brackets
 -	**0.31** -- 1 Mar 2008
@@ -116,12 +118,12 @@
 // Niklas
 ]]
 
+-- Lua 5.2 compatibility
+local unpack = unpack or table.unpack
 
--- Set up a table for holding local functions to avoid polluting the global namespace
-local M = {}
-local MT = {__index = _G}
-setmetatable(M, MT)
-setfenv(1, M)
+-- predeclare functions
+local blocks_to_html, span_transform, encode_backslash_escapes, block_transform
+local encode_code, link_database
 
 ----------------------------------------------------------------------
 -- Utility functions
@@ -130,8 +132,8 @@
 -- Locks table t from changes, writes an error if someone attempts to change the table.
 -- This is useful for detecting variables that have "accidently" been made global. Something
 -- I tend to do all too much.
-function lock(t)
-	function lock_new_index(t, k, v)
+local function lock(t)
+	local function lock_new_index(t, k, v)
 		error("module has been locked -- " .. k .. " must be declared local", 2)
 	end
 
@@ -141,20 +143,20 @@
 end
 
 -- Returns the result of mapping the values in table t through the function f
-function map(t, f)
+local function map(t, f)
 	local out = {}
 	for k,v in pairs(t) do out[k] = f(v,k) end
 	return out
 end
 
 -- The identity function, useful as a placeholder.
-function identity(text) return text end
+local function identity(text) return text end
 
 -- Functional style if statement. (NOTE: no short circuit evaluation)
-function iff(t, a, b) if t then return a else return b end end
+local function iff(t, a, b) if t then return a else return b end end
 
 -- Splits the text into an array of separate lines.
-function split(text, sep)
+local function split(text, sep)
 	sep = sep or "\n"
 	local lines = {}
 	local pos = 1
@@ -168,7 +170,7 @@
 end
 
 -- Converts tabs to spaces
-function detab(text)
+local function detab(text)
 	local tab_width = 4
 	local function rep(match)
 		local spaces = -match:len()
@@ -180,7 +182,7 @@
 end
 
 -- Applies string.find for every pattern in the list and returns the first match
-function find_first(s, patterns, index)
+local function find_first(s, patterns, index)
 	local res = {}
 	for _,p in ipairs(patterns) do
 		local match = {s:find(p, index)}
@@ -192,7 +194,7 @@
 -- If a replacement array is specified, the range [start, stop] in the array is replaced
 -- with the replacement array and the resulting array is returned. Without a replacement
 -- array the section of the array between start and stop is returned.
-function splice(array, start, stop, replacement)
+local function splice(array, start, stop, replacement)
 	if replacement then
 		local n = stop - start + 1
 		while n > 0 do
@@ -213,7 +215,7 @@
 end
 
 -- Outdents the text one step.
-function outdent(text)
+local function outdent(text)
 	text = "\n" .. text
 	text = text:gsub("\n  ? ? ?", "\n")
 	text = text:sub(2)
@@ -221,7 +223,7 @@
 end
 
 -- Indents the text one step.
-function indent(text)
+local function indent(text)
 	text = text:gsub("\n", "\n    ")
 	return text
 end
@@ -229,7 +231,7 @@
 -- Does a simple tokenization of html data. Returns the data as a list of tokens. 
 -- Each token is a table with a type field (which is either "tag" or "text") and
 -- a text field (which contains the original token data).
-function tokenize_html(html)
+local function tokenize_html(html)
 	local tokens = {}
 	local pos = 1
 	while true do
@@ -287,7 +289,7 @@
 
 -- Inits hashing. Creates a hash_identifier that doesn't occur anywhere
 -- in the text.
-function init_hash(text)
+local function init_hash(text)
 	HASH.inited = true
 	HASH.identifier = ""
 	HASH.counter = 0
@@ -305,7 +307,7 @@
 end
 
 -- Returns the hashed value for s.
-function hash(s)
+local function hash(s)
 	assert(HASH.inited)
 	if not HASH.table[s] then
 		HASH.counter = HASH.counter + 1
@@ -342,18 +344,18 @@
 --        Nested data.
 --     </div>
 -- </div>
-function block_pattern(tag)
+local function block_pattern(tag)
 	return "\n<" .. tag .. ".-\n</" .. tag .. ">[ \t]*\n"
 end
 
 -- Pattern for matching a block tag that begins and ends with a newline
-function line_pattern(tag)
+local function line_pattern(tag)
 	return "\n<" .. tag .. ".-</" .. tag .. ">[ \t]*\n"
 end
 
 -- Protects the range of characters from start to stop in the text and
 -- returns the protected string.
-function protect_range(text, start, stop)
+local function protect_range(text, start, stop)
 	local s = text:sub(start, stop)
 	local h = hash(s)
 	PD.blocks[h] = s
@@ -363,7 +365,7 @@
 
 -- Protect every part of the text that matches any of the patterns. The first
 -- matching pattern is protected first, etc.
-function protect_matches(text, patterns)
+local function protect_matches(text, patterns)
 	while true do
 		local start, stop = find_first(text, patterns)
 		if not start then break end
@@ -373,7 +375,7 @@
 end
 
 -- Protects blocklevel tags in the specified text
-function protect(text)
+local function protect(text)
 	-- First protect potentially nested block tags
 	text = protect_matches(text, map(PD.tags, block_pattern))
 	-- Then protect block tags at the line level.
@@ -385,12 +387,12 @@
 end
 
 -- Returns true if the string s is a hash resulting from protection
-function is_protected(s)
+local function is_protected(s)
 	return PD.blocks[s]
 end
 
 -- Unprotects the specified text by expanding all the nonces
-function unprotect(text)
+local function unprotect(text)
 	for k,v in pairs(PD.blocks) do
 		v = v:gsub("%%", "%%%%")
 		text = text:gsub(k, v)
@@ -410,14 +412,14 @@
 -- Returns true if the line is a ruler of (char) characters.
 -- The line must contain at least three char characters and contain only spaces and
 -- char characters.
-function is_ruler_of(line, char)
+local function is_ruler_of(line, char)
 	if not line:match("^[ %" .. char .. "]*$") then return false end
 	if not line:match("%" .. char .. ".*%" .. char .. ".*%" .. char) then return false end
 	return true
 end
 
 -- Identifies the block level formatting present in the line
-function classify(line)
+local function classify(line)
 	local info = {line = line, text = line}
 	
 	if line:match("^    ") then
@@ -483,7 +485,7 @@
 
 -- Find headers constisting of a normal line followed by a ruler and converts them to
 -- header entries.
-function headers(array)
+local function headers(array)
 	local i = 1
 	while i <= #array - 1 do
 		if array[i].type  == "normal" and array[i+1].type == "ruler" and 
@@ -501,7 +503,7 @@
 end
 
 -- Find list blocks and convert them to protected data blocks
-function lists(array, sublist)
+local function lists(array, sublist)
 	local function process_list(arr)
 		local function any_blanks(arr)
 			for i = 1, #arr do
@@ -624,7 +626,7 @@
 end
 
 -- Find and convert blockquote markers.
-function blockquotes(lines)
+local function blockquotes(lines)
 	local function find_blockquote(lines)
 		local start
 		for i,line in ipairs(lines) do
@@ -674,7 +676,7 @@
 end
 
 -- Find and convert codeblocks.
-function codeblocks(lines)
+local function codeblocks(lines)
 	local function find_codeblock(lines)
 		local start
 		for i,line in ipairs(lines) do
@@ -715,7 +717,7 @@
 	return lines
 end
 
--- Convert lines to html code
+-- Convert lines to html code (predeclared!!!)
 function blocks_to_html(lines, no_paragraphs)
 	local out = {}
 	local i = 1
@@ -749,7 +751,7 @@
 	return out
 end
 
--- Perform all the block level transforms
+-- Perform all the block level transforms (predeclared!!!)
 function block_transform(text, sublist)
 	local lines = split(text)
 	lines = map(lines, classify)
@@ -764,7 +766,7 @@
 
 -- Debug function for printing a line array to see the result
 -- of partial transforms.
-function print_lines(lines)
+local function print_lines(lines)
 	for i, line in ipairs(lines) do
 		print(i, line.type, line.text or line.line)
 	end
@@ -778,10 +780,10 @@
 
 -- These characters may need to be escaped because they have a special
 -- meaning in markdown.
-escape_chars = "'\\`*_{}[]()>#+-.!'"
-escape_table = {}
+local escape_chars = "'\\`*_{}[]()>#+-.!'"
+local escape_table = {}
 
-function init_escape_table()
+local function init_escape_table()
 	escape_table = {}
 	for i = 1,#escape_chars do
 		local c = escape_chars:sub(i,i)
@@ -790,7 +792,7 @@
 end
 
 -- Adds a new escape to the escape table.
-function add_escape(text)
+local function add_escape(text)
 	if not escape_table[text] then
 		escape_table[text] = hash(text)
 	end
@@ -798,7 +800,7 @@
 end	
 
 -- Escape characters that should not be disturbed by markdown.
-function escape_special_chars(text)
+local function escape_special_chars(text)
 	local tokens = tokenize_html(text)
 	
 	local out = ""
@@ -816,7 +818,7 @@
 	return out
 end
 
--- Encode backspace-escaped characters in the markdown source.
+-- Encode backspace-escaped characters in the markdown source. (predeclared!!!)
 function encode_backslash_escapes(t)
 	for i=1,escape_chars:len() do
 		local c = escape_chars:sub(i,i)
@@ -826,7 +828,7 @@
 end
 
 -- Unescape characters that have been encoded.
-function unescape_special_chars(t)
+local function unescape_special_chars(t)
 	local tin = t
 	for k,v in pairs(escape_table) do
 		k = k:gsub("%%", "%%%%")
@@ -838,7 +840,7 @@
 
 -- Encode/escape certain characters inside Markdown code runs.
 -- The point is that in code, these characters are literals,
--- and lose their special Markdown meanings.
+-- and lose their special Markdown meanings. (predeclared!!!)
 function encode_code(s)
 	s = s:gsub("%&", "&amp;")
 	s = s:gsub("<", "&lt;")
@@ -850,7 +852,7 @@
 end
 
 -- Handle backtick blocks.
-function code_spans(s)
+local function code_spans(s)
 	s = s:gsub("\\\\", escape_table["\\"])
 	s = s:gsub("\\`", escape_table["`"])
 
@@ -880,7 +882,7 @@
 end
 
 -- Encode alt text... enodes &, and ".
-function encode_alt(s)
+local function encode_alt(s)
 	if not s then return s end
 	s = s:gsub('&', '&amp;')
 	s = s:gsub('"', '&quot;')
@@ -889,7 +891,7 @@
 end
 
 -- Handle image references
-function images(text)
+local function images(text)
 	local function reference_link(alt, id)
 		alt = encode_alt(alt:match("%b[]"):sub(2,-2))
 		id = id:match("%[(.*)%]"):lower()
@@ -922,7 +924,7 @@
 end
 
 -- Handle anchor references
-function anchors(text)
+local function anchors(text)
 	local function reference_link(text, id)
 		text = text:match("%b[]"):sub(2,-2)
 		id = id:match("%b[]"):sub(2,-2):lower()
@@ -955,7 +957,7 @@
 end
 
 -- Handle auto links, i.e. <http://www.google.com/>.
-function auto_links(text)
+local function auto_links(text)
 	local function link(s)
 		return add_escape("<a href=\"" .. s .. "\">") .. s .. "</a>"
 	end
@@ -1004,7 +1006,7 @@
 
 -- Encode free standing amps (&) and angles (<)... note that this does not
 -- encode free >.
-function amps_and_angles(s)
+local function amps_and_angles(s)
 	-- encode amps not part of &..; expression
 	local pos = 1
 	while true do
@@ -1029,7 +1031,7 @@
 end
 
 -- Handles emphasis markers (* and _) in the text.
-function emphasis(text)
+local function emphasis(text)
 	for _, s in ipairs {"%*%*", "%_%_"} do
 		text = text:gsub(s .. "([^%s][%*%_]?)" .. s, "<strong>%1</strong>")
 		text = text:gsub(s .. "([^%s][^<>]-[^%s][%*%_]?)" .. s, "<strong>%1</strong>")
@@ -1044,11 +1046,11 @@
 end
 
 -- Handles line break markers in the text.
-function line_breaks(text)
+local function line_breaks(text)
 	return text:gsub("  +\n", " <br/>\n")
 end
 
--- Perform all span level transforms.
+-- Perform all span level transforms. (predeclared!!!)
 function span_transform(text)
 	text = code_spans(text)
 	text = escape_special_chars(text)
@@ -1067,7 +1069,7 @@
 
 -- Cleanup the text by normalizing some possible variations to make further
 -- processing easier.
-function cleanup(text)
+local function cleanup(text)
 	-- Standardize line endings
 	text = text:gsub("\r\n", "\n")  -- DOS to UNIX
 	text = text:gsub("\r", "\n")    -- Mac to UNIX
@@ -1086,7 +1088,7 @@
 end
 
 -- Strips link definitions from the text and stores the data in a lookup table.
-function strip_link_definitions(text)
+local function strip_link_definitions(text)
 	local linkdb = {}
 	
 	local function link_def(id, url, title)
@@ -1109,10 +1111,11 @@
 	return text, linkdb
 end
 
+-- predeclared!!!
 link_database = {}
 
 -- Main markdown processing function
-function markdown(text)
+local function markdown(text)
 	init_hash(text)
 	init_escape_table()
 	
@@ -1128,12 +1131,6 @@
 -- End of module
 ----------------------------------------------------------------------
 
-setfenv(1, _G)
-M.lock(M)
-
--- Expose markdown function to the world
-markdown = M.markdown
-
 -- Class for parsing command-line options
 local OptionParser = {}
 OptionParser.__index = OptionParser
@@ -1183,7 +1180,7 @@
 				info.f()
 				pos = pos + 1
 			else
-				param = args[pos+1]
+				local param = args[pos+1]
 				if not param then print("No parameter for flag: " .. arg) return false end
 				info.f(param)
 				pos = pos+2
@@ -1197,12 +1194,12 @@
 					info.f()
 				else
 					if i == arg:len() then
-						param = args[pos+1]
+						local param = args[pos+1]
 						if not param then print("No parameter for flag: -" .. c) return false end
 						info.f(param)
 						pos = pos + 1
 					else
-						param = arg:sub(i+1)
+						local param = arg:sub(i+1)
 						info.f(param)
 					end
 					break
@@ -1352,8 +1349,9 @@
 end
 	
 -- If we are being run from the command-line, act accordingly
-if arg and arg[0]:find("markdown%.lua$") then
+if arg and arg[0] and arg[0]:find("markdown%.lua$") then
 	run_command_line(arg)
 else
 	return markdown
-end
\ Kein Zeilenumbruch am Dateiende.
+end
+
]=],
   }
}

