-- Class helpers and opt-in buff management for Vanilla 1.12.1.
local M = {}
local class
local lastAura = 0

local salvationTextures = {
  "Spell_Holy_SealOfSalvation",
  "Spell_Holy_GreaterBlessingofSalvation",
}
local manaTextures = {
  "Spell_Holy_SealOfWisdom",
  "Spell_Holy_GreaterBlessingofWisdom",
  "Spell_Holy_ArcaneIntellect",
  "Spell_Holy_MagicalSentry",
  "Spell_Holy_PrayerofSpirit",
  "Spell_Holy_DivineSpirit",
}

local function IsBattleground()
  local inside, kind = IsInInstance()
  return inside and kind == "pvp"
end

local function HasShield()
  local link = GetInventoryItemLink("player", 17)
  if not link then return false end
  local _, _, _, _, _, _, _, equip = GetItemInfo(link)
  return equip == "INVTYPE_SHIELD"
end

local function IsBear()
  if class ~= "DRUID" then return false end
  for i = 1, GetNumShapeshiftForms() do
    local _, name, active = GetShapeshiftFormInfo(i)
    if active and (name == "Bear Form" or name == "Dire Bear Form") then
      return true
    end
  end
  return false
end

local function HasRighteousFury()
  if class ~= "PALADIN" then return false end
  for i = 0, 31 do
    local buff = GetPlayerBuff(i)
    if not buff or buff < 0 then break end
    local texture = GetPlayerBuffTexture(buff)
    if texture and string.find(texture, "Spell_Holy_SealOfFury", 1, true) then
      return true
    end
  end
  return false
end

local function SmartTank()
  if class == "WARRIOR" then return HasShield() end
  if class == "DRUID" then return IsBear() end
  if class == "PALADIN" then return HasRighteousFury() end
  if class == "SHAMAN" then
    local _, _, _, _, rank = GetTalentInfo(2, 11)
    return HasShield() and (rank or 0) >= 2
  end
  return false
end

local function RemoveFirstMatching(textures, message)
  for i = 0, 31 do
    local buff, untilCancelled = GetPlayerBuff(i)
    if not buff or buff < 0 then return end
    if untilCancelled ~= 1 then
      local texture = GetPlayerBuffTexture(buff)
      if texture then
        for _, needle in ipairs(textures) do
          if string.find(texture, needle, 1, true) then
            CancelPlayerBuff(buff)
            LWExtra:Print(message)
            return
          end
        end
      end
    end
  end
end

local function CheckBuffs()
  local salvation = LWExtra:Value("salvation_mode")
  if salvation == "always" or (salvation == "smart" and SmartTank()) then
    RemoveFirstMatching(salvationTextures, "Blessing of Salvation removed.")
  end
  if LWExtra:Enabled("mana_buff_remover") and not IsBattleground() then
    RemoveFirstMatching(manaTextures, "Mana-related buff removed.")
  end
end

local function AutoStance(message)
  if not LWExtra:Enabled("auto_stance") then return end
  if class ~= "WARRIOR" and class ~= "DRUID" then return end
  if not message or not SPELL_FAILED_ONLY_SHAPESHIFT then return end
  local pattern = string.gsub(SPELL_FAILED_ONLY_SHAPESHIFT, "%%s", "(.+)")
  local _, _, available = string.find(message, pattern)
  if not available then return end
  -- First matching form only. Never repeatedly cast every listed form.
  for stance in string.gfind(available, "[^,]+") do
    local name = string.gsub(stance, "^%s*(.-)%s*$", "%1")
    if name ~= "" then
      CastSpellByName(name)
      return
    end
  end
end

function M:Init()
  local _, token = UnitClass("player")
  class = token
  CheckBuffs()
end

function M:OnEvent(ev, arg)
  if ev == "UI_ERROR_MESSAGE" then
    AutoStance(arg)
  elseif ev == "PLAYER_AURAS_CHANGED" or ev == "UPDATE_BONUS_ACTIONBAR"
      or ev == "UNIT_INVENTORY_CHANGED" and arg == "player" then
    if GetTime() - lastAura > 0.35 then
      lastAura = GetTime()
      CheckBuffs()
    end
  elseif ev == "PLAYER_ENTERING_WORLD" then
    CheckBuffs()
  end
end

function LWExtra:RefreshBuffAutomation()
  if self.ready then CheckBuffs() end
end

LWExtra:Register("Automation", M, {
  "UI_ERROR_MESSAGE", "PLAYER_AURAS_CHANGED", "UPDATE_BONUS_ACTIONBAR",
  "UNIT_INVENTORY_CHANGED", "PLAYER_ENTERING_WORLD"
})
