local util = {}

local verbose = os.getenv("VERBOSE")
verbose = verbose and verbose ~= ""

local log = io.stderr

local trace = {}

function util.trace_push(m)
	table.insert(trace, m)
end

function util.trace_pop()
	table.remove(trace)
end

function util.traceback()
	util.note("")
	for _, t in ipairs(trace) do util.note("\x1b[36mWhile processing\x1b[0m %q (%s):", t.name, t.url) end
end

function util.shellesc(s)
	s = tostring(s)
	if s:find("^[A-Za-z0-9@%%^%-_=+:,./]*$") then return s end
	return ("'%s'"):format(s:gsub("'", "'\\''"))
end

function util.exec(fmt, ...)
	local args = {...}
	for i = 1, #args do args[i] = util.shellesc(args[i]) end
	util.log("\x1b[36mutil.exec\x1b[0m %s", fmt:format(table.unpack(args)))
	return os.execute(fmt:format(table.unpack(args)))
end

function util.log(fmt, ...)
	if verbose then util.note(fmt, ...) end
end

function util.note(fmt, ...)
	log:write(fmt:format(...), "\n")
	log:flush()
end

function util.action(what, arg)
	util.note("\x1b[36m%s\x1b[0m%s", what, arg and (" " .. arg) or "")
end

function util.begin(s)
	util.note("\n\x1b[35m%s\x1b[0m ...", s)
end

function util.step(s, arg)
	if arg then
		util.note("\x1b[34m%s\x1b[0m %s", s, arg)
	else
		util.note("\x1b[34m%s\x1b[0m", s)
	end
end

function util.done(s)
	util.note("\x1b[32m%s\x1b[0m", "Done")
end

function util.warn(fmt, ...)
	util.traceback()
	log:write("\x1b[33mWarning\x1b[0m: ", fmt:format(...), "\n\n")
	log:flush()
end

function util.errmsg(fmt, ...)
	util.traceback()
	log:write("\x1b[31mError\x1b[0m: ", fmt:format(...), "\n\n")
	log:flush()
end

function util.error(fmt, ...)
	if fmt then util.errmsg(fmt, ...) end
	os.exit(1)
end

function util.toset(t)
	local ret = {}
	for _, v in ipairs(t) do ret[v] = true end
	return ret
end

function util.extsplit(p)
	return p:match("^(.+)%.([^/]+)$")
end

return util
