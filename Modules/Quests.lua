-- QuestRepeat-style hold-Alt workflow, adapted for LazyWeirdo.
-- Inspired by MarcelineVQ/QuestRepeat (LGPL v2.1) and LazyPig.
-- Does not overwrite quest selection APIs or save permanent quest automation.
local M = {}
local recorded
local hooks = {}
local busy = false

local function Active()
  return LWExtra:Enabled("quest_repeat") and IsAltKeyDown() and not QuestHaste
end

local function Reset()
  recorded = nil
end

local function RememberQuest(title)
  if not Active() or not title or title == "" then return end
  if not recorded or recorded.title ~= title then
    recorded = { title = title }
    LWExtra:Print("Quest recording: " .. title)
  end
end

local function Hook(name, callback, before)
  local old = getglobal(name)
  if type(old) ~= "function" then return end
  hooks[name] = old
  setglobal(name, function(a1, a2, a3, a4, a5)
    if before then callback() end
    local result = old(a1, a2, a3, a4, a5)
    if not before then callback() end
    return result
  end)
end

local function ClickMatchingButtons(prefix, limit)
  if not recorded then return false end
  for i = 1, limit do
    local b = getglobal(prefix .. i)
    if b and b:IsVisible() and b:GetText() == recorded.title then
      b:Click()
      return true
    end
  end
  return false
end

local function OnRewardClick()
  if not Active() then return end
  local title = QuestRewardTitleText and QuestRewardTitleText:GetText()
  if not title then return end
  RememberQuest(title)
  if recorded then
    local picked = QuestFrameRewardPanel.itemChoice
    if picked and picked > 0 then
      recorded.choice = picked
    end
  end
end

local function OnRewardShow()
  if not Active() or busy or not recorded then return end
  local title = QuestRewardTitleText and QuestRewardTitleText:GetText()
  if title ~= recorded.title then return end
  local choices = GetNumQuestChoices()
  if choices and choices > 0 then
    if not recorded.choice or recorded.choice > choices then return end
    QuestFrameRewardPanel.itemChoice = recorded.choice
  else
    QuestFrameRewardPanel.itemChoice = 0
  end
  if QuestFrameCompleteQuestButton and QuestFrameCompleteQuestButton:IsEnabled() then
    busy = true
    QuestFrameCompleteQuestButton:Click()
    busy = false
  end
end

local function OnDetailShow()
  if not Active() or busy then return end
  local title = QuestTitleText and QuestTitleText:GetText()
  if title then
    RememberQuest(title)
    if AcceptQuest then AcceptQuest() end
  end
end

local function OnProgressShow()
  if not Active() or busy then return end
  local title = QuestProgressTitleText and QuestProgressTitleText:GetText()
  if not recorded or title ~= recorded.title then return end
  if QuestFrameCompleteButton and QuestFrameCompleteButton:IsEnabled() then
    busy = true
    QuestFrameCompleteButton:Click()
    busy = false
  end
end

local function OnGreetingShow()
  if not Active() or busy then return end
  if not recorded then return end
  local limit = MAX_NUM_QUESTS or 20
  ClickMatchingButtons("QuestTitleButton", limit)
end

local function OnGossip()
  if not Active() or busy then return end
  if recorded then
    if ClickMatchingButtons("GossipTitleButton", NUMGOSSIPBUTTONS or 32) then return end
  end
  -- Start the first recording only if there is exactly one quest available.
  if not recorded and GetGossipAvailableQuests then
    local available = { GetGossipAvailableQuests() }
    local active = { GetGossipActiveQuests() }
    if table.getn(available) == 2 and table.getn(active) == 0 then
      SelectGossipAvailableQuest(1)
    end
  end
end

function M:Init()
  Hook("QuestRewardCompleteButton_OnClick", OnRewardClick, true)
  Hook("QuestFrameRewardPanel_OnShow", OnRewardShow)
  Hook("QuestFrameDetailPanel_OnShow", OnDetailShow)
  Hook("QuestFrameProgressPanel_OnShow", OnProgressShow)
  Hook("QuestFrameGreetingPanel_OnShow", OnGreetingShow)
end

function M:OnEvent(ev)
  if ev == "GOSSIP_SHOW" then
    OnGossip()
  elseif ev == "QUEST_GREETING" then
    OnGreetingShow()
  end
end

function M:OnUpdate()
  if recorded and not Active() then Reset() end
end

LWExtra:Register("Quests", M, { "GOSSIP_SHOW", "QUEST_GREETING" })
