-- Workspace > Scripts > Link Fast Media
-- swaps every media pool clip whose audio Resolve can't read onto its fixed copy and
-- links DNxHR proxies, both made by ~/.local/bin/davinci-decode-fix in its cache. clips
-- with nothing ready yet get queued, and a notification says when to run this again

local home = os.getenv("HOME")
local helper = home .. "/.local/bin/davinci-decode-fix"

local function sh(s) return "'" .. (s:gsub("'", "'\\''")) .. "'" end

local function notify(title, body)
    os.execute("notify-send --app-name='DaVinci Resolve' --icon=davinci-resolve " .. sh(title) .. " " .. sh(body) .. " >/dev/null 2>&1 &")
    print(title .. ": " .. body)
end

local project = resolve:GetProjectManager():GetCurrentProject()
if not project then
    notify("Link Fast Media", "Open a project first")
    return
end
local pool = project:GetMediaPool()

-- ReplaceClip leaves every other clip handle dead, so walk the pool afresh each time
local function each_clip(fn)
    local function walk(folder)
        for _, clip in ipairs(folder:GetClipList() or {}) do
            local path = clip:GetClipProperty("File Path")
            if path and path ~= "" and fn(clip, path) then return true end
        end
        for _, sub in ipairs(folder:GetSubFolderList() or {}) do
            if walk(sub) then return true end
        end
    end
    walk(pool:GetRootFolder())
end

local paths, seen = {}, {}
each_clip(function(_, path)
    if not seen[path] then
        seen[path] = true
        paths[#paths + 1] = path
    end
end)
if #paths == 0 then
    notify("Link Fast Media", "No media in this project yet")
    return
end

local list = os.tmpname()
local f = assert(io.open(list, "w"))
for _, path in ipairs(paths) do f:write(path, "\n") end
f:close()

local rows = {}
local queued, failed = 0, 0
local lookup = io.popen(sh(helper) .. " --lookup " .. sh(list))
for line in lookup:lines() do
    local state, path, fixed, proxy = line:match("^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)$")
    if state then
        local row = { fixed = fixed, proxy = proxy }
        rows[path] = row
        -- once swapped, the clip answers to the fixed copy's path
        if fixed ~= "" then rows[fixed] = row end
        if state == "queued" then queued = queued + 1 elseif state == "failed" then failed = failed + 1 end
    end
end
lookup:close()
os.remove(list)

local swapped, linked = 0, 0
local tried = {}
local function swap_one()
    local done = false
    each_clip(function(clip, path)
        local row = rows[path]
        local id = clip:GetUniqueId()
        if not row or row.fixed == "" or row.fixed == path or tried[id] then return false end
        tried[id] = true
        -- ReplaceClip renames the clip after the cache file, keep the name people know
        local name = clip:GetClipProperty("Clip Name")
        if clip:ReplaceClip(row.fixed) then
            clip:SetClipProperty("Clip Name", name)
            swapped = swapped + 1
        else
            failed = failed + 1
        end
        done = true
        return true
    end)
    return done
end
while swap_one() do end

each_clip(function(clip, path)
    local row = rows[path]
    if row and row.proxy ~= "" and clip:GetClipProperty("Proxy Media Path") ~= row.proxy then
        if clip:LinkProxyMedia(row.proxy) then linked = linked + 1 else failed = failed + 1 end
    end
    return false
end)

local parts = {}
if swapped > 0 then parts[#parts + 1] = swapped .. " audio fixed" end
if linked > 0 then parts[#parts + 1] = linked .. " proxies linked" end
if queued > 0 then parts[#parts + 1] = queued .. " converting, you'll get a notification" end
if failed > 0 then parts[#parts + 1] = failed .. " failed, see ~/.local/share/davinci-decode-fix/convert.log" end
if #parts == 0 then parts[1] = "everything is already linked" end
notify("Link Fast Media", table.concat(parts, ", "))
