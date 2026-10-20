-- Native WoW 1.12.1 keybinding actions. No default keys are assigned.
BINDING_HEADER_LW_BINDINGS = "LazyWeirdo"
BINDING_NAME_LW_OPEN_CONFIG = "Open LazyWeirdo Configuration"
BINDING_NAME_LW_RELOAD = "Reload UI"
BINDING_NAME_LW_LOGOUT = "Logout"
BINDING_NAME_LW_UNSTUCK = "Unstuck"
BINDING_NAME_LW_FOLLOW = "Follow Target"
BINDING_NAME_LW_INSPECT = "Inspect Target"
BINDING_NAME_LW_TRADE = "Initiate / Accept Trade"
BINDING_NAME_LW_DUEL_EFC = "Duel / Target WSG Enemy Flag Carrier"
BINDING_NAME_LW_DROP_FLAG = "Drop WSG Flag / Remove Slow Fall"

LazyWeirdoBindings = {}
local B = LazyWeirdoBindings
local enemyCarrier
local lastTrade = 0

function B.ToggleConfig()
  local f = getglobal("LazyWeirdoConfigFrame")
  if not f then return end
  if f:IsShown() then f:Hide() else f:Show() end
end

function B.Reload()
  ReloadUI()
end

function B.Logout()
  Logout()
end

function B.Unstuck()
  if type(Stuck) == "function" then Stuck() end
end

function B.Follow()
  if UnitExists("target") and UnitIsPlayer("target") and UnitIsFriend("player", "target") then
    FollowUnit("target")
  end
end

function B.Inspect()
  if UnitExists("target") and UnitIsPlayer("target") then
    InspectUnit("target")
  end
end

function B.Trade()
  local now = GetTime()
  if now - lastTrade < 1 then return end
  local trade = getglobal("TradeFrame")
  if trade and trade:IsVisible() then
    AcceptTrade()
    lastTrade = now
  elseif UnitExists("target") and UnitIsPlayer("target")
      and UnitIsFriend("player", "target")
      and not UnitIsUnit("player", "target")
      and CheckInteractDistance("target", 2) then
    InitiateTrade("target")
    lastTrade = now
  end
end

function B.DuelEFC()
  if GetRealZoneText() == "Warsong Gulch" then
    if enemyCarrier then TargetByName(enemyCarrier, true)
    else LWExtra:Print("Enemy flag carrier not identified yet.") end
  else
    local duelRequest = false
    for i = 1, (STATICPOPUP_NUMDIALOGS or 4) do
      local popup = getglobal("StaticPopup" .. i)
      if popup and popup:IsShown() and popup.which == "DUEL_REQUESTED" then
        duelRequest = true
        break
      end
    end
    if duelRequest then
      CancelDuel()
    elseif UnitExists("target") and UnitIsPlayer("target")
        and UnitIsFriend("player", "target") then
      StartDuel(UnitName("target"))
    end
  end
end

local tooltip
function B.DropFlag()
  if not tooltip then
    tooltip = CreateFrame("GameTooltip", "LWBindingBuffTooltip", UIParent, "GameTooltipTemplate")
  end
  for i = 0, 31 do
    local buff = GetPlayerBuff(i)
    if not buff or buff < 0 then break end
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:SetPlayerBuff(buff)
    local titleText = getglobal("LWBindingBuffTooltipTextLeft1")
    local descText = getglobal("LWBindingBuffTooltipTextLeft2")
    local name = titleText and titleText:GetText() or ""
    local desc = descText and descText:GetText() or ""
    if string.find(name, "Warsong Flag", 1, true)
        or string.find(name, "Slow Fall", 1, true)
        or string.find(desc, "You feel light", 1, true) then
      CancelPlayerBuff(buff)
      tooltip:Hide()
      return
    end
  end
  tooltip:Hide()
end

local M = {}
function M:OnEvent(ev, message)
  if ev == "CHAT_MSG_BG_SYSTEM_ALLIANCE" or ev == "CHAT_MSG_BG_SYSTEM_HORDE" then
    if not message then return end
    local myFaction = UnitFactionGroup("player")
    local phrase = "The " .. tostring(myFaction) .. " Flag was picked up by "
    local _, _, person = string.find(message, phrase .. "(.+)%!")
    if person then enemyCarrier = person end
    if string.find(message, "was dropped", 1, true)
        or string.find(message, "was returned", 1, true)
        or string.find(message, "captured", 1, true) then
      enemyCarrier = nil
    end
  elseif ev == "ZONE_CHANGED_NEW_AREA" then
    enemyCarrier = nil
  end
end

LWExtra:Register("Keybindings", M, {
  "CHAT_MSG_BG_SYSTEM_ALLIANCE", "CHAT_MSG_BG_SYSTEM_HORDE", "ZONE_CHANGED_NEW_AREA"
})
