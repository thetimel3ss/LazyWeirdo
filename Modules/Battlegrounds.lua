-- Battleground automation; separate from the loot roll system.
local M = {}
local lastStatus = 0
local lastLeave = 0
local lastQueue = 0
local pendingJoin = {}

local function InBG()
  local inside, kind = IsInInstance()
  return inside and kind == "pvp"
end

local function CheckQueues()
  local active = InBG()
  if active then return end
  if not LWExtra:Enabled("bg_auto_enter") or (UnitIsAFK and UnitIsAFK("player")) then
    return
  end
  for i = 1, (MAX_BATTLEFIELD_QUEUES or 3) do
    local status, mapName = GetBattlefieldStatus(i)
    if status == "confirm" then
      local remaining = GetBattlefieldPortExpiration(i)
      if remaining and remaining > 0 then
        if not pendingJoin[i] then
          LWExtra:Print("Battleground ready: " .. (mapName or "unknown") ..
            ". Auto-enter when approximately 3 seconds remain.")
          pendingJoin[i] = true
        end
        if remaining <= 3000 then
          AcceptBattlefieldPort(i, true)
          if StaticPopup_Hide then StaticPopup_Hide("CONFIRM_BATTLEFIELD_ENTRY") end
          pendingJoin[i] = nil
        end
      end
    else
      pendingJoin[i] = nil
    end
  end
end

local function CheckLeave()
  if not LWExtra:Enabled("bg_auto_leave") or not InBG() then return end
  if GetBattlefieldWinner() ~= nil then
    if GetTime() - lastLeave >= 3 then
      lastLeave = GetTime()
      LeaveBattlefield()
    end
  end
end

function M:Init()
  -- QUEST_ACCEPT confirmations are StaticPopup dialogs in Vanilla, not a
  -- dependable independent game event. Wrap the original show handler.
  if type(StaticPopup_OnShow) ~= "function" then return end
  local original = StaticPopup_OnShow
  StaticPopup_OnShow = function()
    if LWExtra:Enabled("bg_block_quest_share") and InBG()
        and this and this.which == "QUEST_ACCEPT" then
      this:Hide()
      return
    end
    return original()
  end
end

function M:OnEvent(ev)
  if ev == "BATTLEFIELDS_SHOW" and LWExtra:Enabled("bg_auto_queue") then
    if GetTime() - lastQueue < 1 then return end
    lastQueue = GetTime()
    if (GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0)
        and (IsPartyLeader() or (IsRaidLeader and IsRaidLeader())) then
      JoinBattlefield(0, 1)
    else
      JoinBattlefield(0)
    end
    -- Do not clear the player's target.
  elseif ev == "UPDATE_BATTLEFIELD_STATUS" or ev == "PLAYER_ENTERING_WORLD" then
    CheckQueues()
    CheckLeave()
  elseif ev == "PLAYER_DEAD" and LWExtra:Enabled("bg_auto_release") and InBG() then
    RepopMe()
  elseif ev == "DUEL_REQUESTED" and LWExtra:Enabled("auto_decline_duels") then
    if not IsShiftKeyDown() then CancelDuel() end
  elseif ev == "QUEST_ACCEPT_CONFIRM" and LWExtra:Enabled("bg_block_quest_share") and InBG() then
    if StaticPopup_Hide then StaticPopup_Hide("QUEST_ACCEPT") end
  end
end

function M:OnUpdate()
  local now = GetTime()
  if now - lastStatus < 0.5 then return end
  lastStatus = now
  CheckQueues()
  if now - lastLeave > 1 then CheckLeave() end
end

LWExtra:Register("Battlegrounds", M, {
  "BATTLEFIELDS_SHOW", "UPDATE_BATTLEFIELD_STATUS", "PLAYER_ENTERING_WORLD",
  "PLAYER_DEAD", "DUEL_REQUESTED", "QUEST_ACCEPT_CONFIRM"
})
