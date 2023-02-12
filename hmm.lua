#!/usr/bin/env lua5.4

if #arg ~= 1 then
	print("Usage: " .. arg[0] .. " <script file>")
	os.exit(1)
end

local util = require "hmm.util"

local mods = {}



cachedir = os.getenv("HOME") .. "/.local/share/hmm"
gamedir  = false

local function monkeypatch(module)
	local ret = {}
	ret.mod = function(...)
		local ret = module.mod(...)
		table.insert(mods, ret)
		return ret
	end
	setmetatable(ret, {__index = module, __newindex = module})
	return ret
end

nexus = monkeypatch(require "hmm.modules.nexusmods")



util.begin "Resolving mods"

dofile(arg[1])

if not gamedir then util.err("gamedir not provided") end

local loadorder = {}
local function addmod(m)
	for _, v in ipairs(loadorder) do
		if v.id == m.id then return end
	end

	m:resolve()
	util.log("%s ==> %s", m.url, m.name)
	for _, dep in ipairs(m:getdeps()) do addmod(dep) end
	table.insert(loadorder, m)
end
for _, m in ipairs(mods) do addmod(m) end

util.done()


util.log "\nDependencies:"
for _, m in ipairs(loadorder) do
	local deps = m:getdeps()
	if deps[1] then
		util.log(" - %s", m.name)
		for _, d in ipairs(deps) do util.log("     ==> %s", d.name) end
	end
end

util.log "\nLoad order:"
for i, m in ipairs(loadorder) do util.log(" %4d  %s", i, m.name) end



util.begin "Processing mods"
for _, m in ipairs(loadorder) do
	util.log(m.name)
	m:download()
	m:unpack()
	m:prepare()
	m:install()
end
util.done()



if util.exec("find %s/hmm -type f >/dev/null 2>&1", gamedir) then
	util.begin "Cleaning up previous deployment"
	for l in io.lines(gamedir .. "/hmm") do
		util.exec("cd %s && rm %s", gamedir, l)
	end
	util.exec("rm %s/hmm", gamedir)
	util.done()
end



util.begin "Deploying mods"
util.log("Target directory: %s", gamedir)
local ho = io.open(gamedir .. "/hmm", "a")
for _, m in ipairs(loadorder) do
	util.log(m.name)
	local d = m:installpath()

	local hi = io.popen(("find %s -type f -printf '%%P\\n' >> %s/hmm"):format(util.shellesc(d), util.shellesc(gamedir)))
	local files = {}
	for l in hi:lines() do
		if util.exec("find %s/%s -type f >/dev/null 2>&1", gamedir, l) and not (m.collisions or {})[l] then
			m:error("file %q collides, please allow explicitly to continue")
		end
		ho:write(l, "\n")
	end
	hi:close()

	assert(util.exec("rsync --quiet --archive %s/ %s", d, gamedir))
end
ho:close()
util.done()
