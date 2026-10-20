-- Inventory improvements: contextual right-click and two-step split/merge.
-- No global loot hooks are installed by this module.
local M = {}
local originalUse
local selection, job
local lastAdjustment = 0

local function ItemKey(bag, slot)
  local link = GetContainerItemLink(bag, slot)
  if not link then return nil end
  local _, _, key = string.find(link, "|H(item:[^|]+)|h")
  return key or link
end

local function Count(bag, slot)
  local _, n, locked = GetContainerItemInfo(bag, slot)
  return n or 0, locked
end

local function EmptySlot()
  for b = 0, NUM_BAG_FRAMES do
    for s = 1, GetContainerNumSlots(b) do
      if not GetContainerItemLink(b, s) then return b, s end
    end
  end
end

local function MatchingSource(key, bag, slot)
  for b = 0, NUM_BAG_FRAMES do
    for s = 1, GetContainerNumSlots(b) do
      if not (b == bag and s == slot) and ItemKey(b, s) == key then
        local n, locked = Count(b, s)
        if n > 0 and not locked then return b, s, n end
      end
    end
  end
end

local function Reset()
  selection = nil
  job = nil
end

local function BeginJob(bag, slot)
  local key = ItemKey(bag, slot)
  if not selection or selection.key ~= key then Reset(); return end
  local count = Count(bag, slot)
  local goal = math.min(selection.amount, selection.max)
  if goal == count and bag == selection.bag and slot == selection.slot then
    Reset()
    return
  end
  if bag == selection.bag and slot == selection.slot and count > goal then
    -- Create a new stack with exactly the selected quantity.
    local emptyBag, emptySlot = EmptySlot()
    if not emptyBag then LWExtra:Print("Split: no free bag slot."); Reset(); return end
    job = { kind = "split", sourceBag = bag, sourceSlot = slot,
            bag = emptyBag, slot = emptySlot, amount = goal, key = key,
            expires = GetTime() + 4, nextAction = 0 }
  else
    -- Build the selected quantity in the clicked destination stack.
    job = { kind = "adjust", bag = bag, slot = slot, amount = goal,
            key = key, expires = GetTime() + 8, nextAction = 0 }
  end
  selection = nil
end

local function Advance()
  if not job then return end
  if GetTime() > job.expires then
    LWExtra:Print("Stack operation timed out.")
    Reset()
    return
  end
  if CursorHasItem() or GetTime() < job.nextAction then return end
  if job.kind == "split" then
    local n, locked = Count(job.sourceBag, job.sourceSlot)
    if locked then return end
    if n < job.amount or GetContainerItemLink(job.bag, job.slot) then
      LWExtra:Print("Split cancelled: inventory changed.")
    else
      SplitContainerItem(job.sourceBag, job.sourceSlot, job.amount)
      if CursorHasItem() then PickupContainerItem(job.bag, job.slot) end
    end
    Reset()
    return
  end
  if ItemKey(job.bag, job.slot) ~= job.key then
    LWExtra:Print("Stack operation cancelled: destination changed.")
    Reset()
    return
  end
  local have, locked = Count(job.bag, job.slot)
  if locked then return end
  if have == job.amount then Reset(); return end
  if have > job.amount then
    local db, ds = EmptySlot()
    if not db then LWExtra:Print("Split: no free bag slot."); Reset(); return end
    SplitContainerItem(job.bag, job.slot, have - job.amount)
    if CursorHasItem() then PickupContainerItem(db, ds) end
    Reset()
    return
  end
  local sb, ss, available = MatchingSource(job.key, job.bag, job.slot)
  if not sb then
    LWExtra:Print("Not enough matching items to complete merge.")
    Reset()
    return
  end
  local move = math.min(available, job.amount - have)
  if move == available then
    PickupContainerItem(sb, ss)
  else
    SplitContainerItem(sb, ss, move)
  end
  if CursorHasItem() then PickupContainerItem(job.bag, job.slot) end
  job.nextAction = GetTime() + 0.25
end

local function OnUse(bag, slot)
  local settings = LazyWeirdoDB and LazyWeirdoDB.settings
  if not settings then return originalUse(bag, slot) end
  if settings.stack_split and IsShiftKeyDown() and not IsAltKeyDown()
      and not CursorHasItem() and not (MerchantFrame and MerchantFrame:IsVisible()) then
    local key = ItemKey(bag, slot)
    if not key then return originalUse(bag, slot) end
    if not selection or selection.key ~= key or GetTime() > selection.expires then
      local link = GetContainerItemLink(bag, slot)
      local _, _, _, _, _, _, _, maxStack = GetItemInfo(link)
      selection = { bag = bag, slot = slot, key = key, amount = 1,
                    max = maxStack or 20, expires = GetTime() + 9 }
      LWExtra:Print("Stack: hold Alt (+) / Ctrl (-), then Shift + right-click again.")
    else
      BeginJob(bag, slot)
    end
    return
  end
  if not settings.improved_right_click or IsShiftKeyDown() or IsAltKeyDown()
      or CursorHasItem() then return originalUse(bag, slot) end
  if TradeFrame and TradeFrame:IsVisible() then
    local free = TradeFrame_GetAvailableSlot()
    if free then
      PickupContainerItem(bag, slot)
      if CursorHasItem() then ClickTradeButton(free) end
      return
    end
  elseif MailFrame and MailFrame:IsVisible() and SendMailFrame and SendMailFrame:IsVisible() then
    if GetSendMailItem and GetSendMailItem() then return originalUse(bag, slot) end
    PickupContainerItem(bag, slot)
    if CursorHasItem() then ClickSendMailItemButton() end
    return
  elseif AuctionFrame and AuctionFrame:IsVisible() then
    if AuctionFrame.selectedTab == 1 and BrowseName then
      local link = GetContainerItemLink(bag, slot)
      local _, _, name = string.find(link or "", "%[(.-)%]")
      if name then BrowseName:SetText(name) end
      return
    elseif AuctionFrame.selectedTab == 3 then
      PickupContainerItem(bag, slot)
      if CursorHasItem() then ClickAuctionSellItemButton() end
      return
    end
  end
  return originalUse(bag, slot)
end

function M:Init()
  if originalUse then return end
  originalUse = UseContainerItem
  UseContainerItem = OnUse
end

function M:OnUpdate()
  if not LWExtra:Enabled("stack_split") then Reset(); return end
  if selection then
    local now = GetTime()
    if now > selection.expires then
      selection = nil
    elseif now - lastAdjustment >= 0.16 then
      local nextAmount = selection.amount
      if IsAltKeyDown() and not IsControlKeyDown() then
        nextAmount = math.min(selection.max, nextAmount + 1)
      elseif IsControlKeyDown() and not IsAltKeyDown() then
        nextAmount = math.max(1, nextAmount - 1)
      end
      if nextAmount ~= selection.amount then
        selection.amount = nextAmount
        selection.expires = now + 9
        if UIErrorsFrame then UIErrorsFrame:AddMessage("Stack quantity: " .. nextAmount) end
        lastAdjustment = now
      end
    end
  end
  Advance()
end

LWExtra:Register("Inventory", M, {})
