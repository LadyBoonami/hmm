local util = {}

local log = io.stderr
-- local log = io.open("/tmp/hmm.log", "w")

function util.shellesc(s)
	s = tostring(s)
	if s:find("^[A-Za-z0-9@%%^%-_=+:,./]*$") then return s end
	return ("'%s'"):format(s:gsub("'", "'\\''"))
end

function util.exec(fmt, ...)
	local args = {...}
	for i = 1, #args do args[i] = util.shellesc(args[i]) end
	return os.execute(fmt:format(table.unpack(args)))
end

function util.log(fmt, ...)
	log:write(fmt:format(...), "\n")
	log:flush()
end

function util.warn(fmt, ...)
	log:write("\x1b[33mwarning\x1b[0m: ", fmt:format(...), "\n")
	log:flush()
end

function util.errmsg(fmt, ...)
	log:write("\n\x1b[31merror\x1b[0m: ", fmt:format(...), "\n")
	log:flush()
end

function util.error(fmt, ...)
	if fmt then util.errmsg(fmt, ...) end
	os.exit(1)
end

return util