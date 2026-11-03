-- Split View ratio toggle (⌘⇧,).
-- Each press moves the native full-screen Split View divider to the next
-- left:right ratio listed in ~/.config/splitview/ratios.txt (one per line,
-- e.g. "80:20"; "#" starts a comment). The file is re-read on every press.
-- Uses bin/svctl (private SkyLight calls); source lives in
-- ~/github/splitview (src/svctl.m)
local M = {}

local svctl = hs.configdir .. "/bin/svctl"
local ratiosFile = os.getenv("HOME") .. "/.config/splitview/ratios.txt"

local function run(...)
  local cmd = svctl
  for _, a in ipairs({ ... }) do cmd = cmd .. " " .. a end
  local out, ok = hs.execute(cmd)
  return ok, out
end

-- Returns the ratios from the config file, e.g.
-- {{frac = 0.8, label = "80:20"}, {frac = 0.6, label = "60:40"}}.
local function readRatios()
  local f = io.open(ratiosFile, "r")
  if not f then return nil end
  local ratios = {}
  for line in f:lines() do
    local l, r = line:gsub("#.*", ""):match("^%s*(%d+%.?%d*)%s*[:/]%s*(%d+%.?%d*)%s*$")
    local ln, rn = tonumber(l), tonumber(r)
    if ln and rn and ln + rn > 0 then
      table.insert(ratios, { frac = ln / (ln + rn), label = l .. ":" .. r })
    end
  end
  f:close()
  return ratios
end

function M.toggle()
  local win = hs.window.focusedWindow()
  if not win then return end
  local wid = tostring(win:id())

  local ratios = readRatios()
  if not ratios or #ratios == 0 then
    hs.alert.show("no ratios in " .. ratiosFile)
    return
  end

  local ok, out = run("info", wid)
  if not ok then
    hs.alert.show("not in Split View")
    return
  end
  local dividerX, width, spacing, leftApp, rightApp =
    out:match("(%d+) (%d+) (%d+)\n([^\n]*)\n([^\n]*)")
  local usable = tonumber(width) - tonumber(spacing)
  local current = tonumber(dividerX) / usable

  -- Go to the ratio after the one closest to the current layout. Closest
  -- rather than exact, because apps' minimum widths can clamp a ratio.
  local nearest, best = 1, math.huge
  for i, ratio in ipairs(ratios) do
    if math.abs(ratio.frac - current) < best then nearest, best = i, math.abs(ratio.frac - current) end
  end
  local target = ratios[nearest % #ratios + 1]
  run("divider", wid, string.format("%.0f", target.frac * usable))

  -- Debug popup.
  hs.alert.closeAll()
  hs.alert.show(string.format("%s  →  %s | %s\nfocused: %s (%s)",
    target.label, leftApp, rightApp, win:application():name(), wid), 1.5)
end

hs.hotkey.bind({ "cmd", "shift" }, ",", M.toggle)

return M
