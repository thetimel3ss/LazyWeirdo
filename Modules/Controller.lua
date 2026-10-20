-- LazyWeirdo personal fork: optional quality-of-life modules.
-- All shared Lua remains compatible with the Vanilla 1.12.1 (Lua 5.0) client.
LWExtra = { modules = {}, order = {}, ready = false }
local api = LWExtra

function api:Enabled(setting)
  return self.ready and LazyWeirdoDB and LazyWeirdoDB.settings
      and LazyWeirdoDB.settings[setting] == true
end

function api:Value(setting)
  if not LazyWeirdoDB or not LazyWeirdoDB.settings then return nil end
  return LazyWeirdoDB.settings[setting]
end

function api:Print(message)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffffff00LazyWeirdo:|r " .. tostring(message))
  end
end

function api:Register(name, module, events)
  self.modules[name] = module
  table.insert(self.order, name)
  module.events = {}
  for _, ev in ipairs(events or {}) do
    module.events[ev] = true
    self.frame:RegisterEvent(ev)
  end
end

local frame = CreateFrame("Frame", "LazyWeirdoExtraFrame", UIParent)
api.frame = frame
frame:RegisterEvent("VARIABLES_LOADED")
frame:SetScript("OnEvent", function()
  local ev, a1, a2, a3 = event, arg1, arg2, arg3
  if ev == "VARIABLES_LOADED" then
    if api.ready then return end
    api.ready = true
    for _, name in ipairs(api.order) do
      local module = api.modules[name]
      if module.Init then module:Init() end
    end
    return
  end
  if not api.ready then return end
  for _, name in ipairs(api.order) do
    local module = api.modules[name]
    if module.events[ev] and module.OnEvent then
      module:OnEvent(ev, a1, a2, a3)
    end
  end
end)

local tick = 0
frame:SetScript("OnUpdate", function()
  if not api.ready then return end
  tick = tick + arg1
  if tick < 0.1 then return end
  local elapsed = tick
  tick = 0
  for _, name in ipairs(api.order) do
    local module = api.modules[name]
    if module.OnUpdate then module:OnUpdate(elapsed) end
  end
end)
