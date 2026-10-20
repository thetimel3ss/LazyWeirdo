-- Chat quality-of-life, with reversible World channel visibility.
local M = {}
local originalChatEvent
local seen = {}
local lastCleanup = 0
local lastWorldCheck = 0
local removedFrom = {}

local function CurrentArea()
  local inInstance, kind = IsInInstance()
  if inInstance then return kind end
  return "world"
end

local function HideWorldHere()
  -- Independent selections, equivalent to LazyPig's per-instance World options.
  -- This changes chat-frame channel visibility; it never calls LeaveChannelByName.
  local area = CurrentArea()
  return LWExtra:Enabled("world_mute_always")
    or (area == "party" and LWExtra:Enabled("world_mute_dungeons"))
    or (area == "raid" and LWExtra:Enabled("world_mute_raids"))
    or (area == "pvp" and LWExtra:Enabled("world_mute_bgs"))
end

local function ContainsChannel(frame, name)
  if not frame or not frame.channelList or not name then return false end
  for _, entry in pairs(frame.channelList) do
    if string.lower(entry) == string.lower(name) then return true end
  end
  return false
end

local function RefreshWorld()
  if not LazyWeirdoDB then return end
  local channelId, name = GetChannelName("world")
  if not channelId or channelId == 0 or not name then
    -- Never automatically rejoin a channel the player has left.
    removedFrom = {}
    return
  end
  local hide = HideWorldHere()
  for i = 1, (NUM_CHAT_WINDOWS or 7) do
    local frame = getglobal("ChatFrame" .. i)
    if frame then
      local present = ContainsChannel(frame, name)
      if hide and present then
        removedFrom[i] = name
        ChatFrame_RemoveChannel(frame, name)
      elseif not hide and removedFrom[i] then
        if not present then ChatFrame_AddChannel(frame, removedFrom[i]) end
        removedFrom[i] = nil
      end
    end
  end
end

local function IsTrusted(author)
  if not author then return false end
  if author == UnitName("player") then return true end
  if type(IsFriend) == "function" and IsFriend(author) then return true end
  if type(IsGuildMate) == "function" and IsGuildMate(author) then return true end
  return false
end

local function FilterChat(ev, msg, author)
  if not LWExtra.ready or not msg then return false end
  if LWExtra:Enabled("chat_spam_filter") then
    if ev == "CHAT_MSG_SAY" or ev == "CHAT_MSG_YELL" or ev == "CHAT_MSG_CHANNEL" then
      if not IsTrusted(author) then
        local now = GetTime()
        local frameName = this and this.GetName and this:GetName() or ""
        local key = frameName .. "|" .. tostring(author or "") .. "|" .. msg
        if seen[key] and now - seen[key] < 70 then return true end
        seen[key] = now
      end
    end
    if string.find(msg, "^#showtooltip") then return true end
  end
  if LWExtra:Enabled("chat_loot_filter") and ev == "CHAT_MSG_LOOT" then
    -- Suppress only item-quality-related roll output, not unclassified loot.
    if string.find(msg, "|cff1eff00") or string.find(msg, "|cff0070dd") then
      return true
    end
  end
  return false
end

function M:Init()
  if type(ChatFrame_OnEvent) ~= "function" then return end
  originalChatEvent = ChatFrame_OnEvent
  ChatFrame_OnEvent = function(ev)
    if FilterChat(ev, arg1, arg2) then return end
    return originalChatEvent(ev)
  end
  RefreshWorld()
end

function M:OnEvent(ev)
  if ev == "ZONE_CHANGED_NEW_AREA" or ev == "PLAYER_ENTERING_WORLD"
      or ev == "CHAT_MSG_CHANNEL_NOTICE" then
    RefreshWorld()
  end
end

function M:OnUpdate()
  local now = GetTime()
  if now - lastCleanup > 30 then
    lastCleanup = now
    for key, timestamp in pairs(seen) do
      if now - timestamp > 70 then seen[key] = nil end
    end
  end
  if now - lastWorldCheck > 3 then
    lastWorldCheck = now
    RefreshWorld()
  end
end

function LWExtra:RefreshWorldChat()
  RefreshWorld()
end

LWExtra:Register("Chat", M, {
  "ZONE_CHANGED_NEW_AREA", "PLAYER_ENTERING_WORLD", "CHAT_MSG_CHANNEL_NOTICE"
})
