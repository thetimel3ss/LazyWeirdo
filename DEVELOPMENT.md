# Personal fork: quality-of-life development branch

This branch keeps the original LazyWeirdo 1.8.0 loot engine, raid rules,
vendor lists, minimap button and main configuration panel. No LazyPig loot
handlers or automatic Need/Greed/Pass rules are imported.

## Configuration

Open `/lw`, then the existing **Options** dropdown. All new automations
start disabled; existing settings are not reset or replaced.

- **Stack Split / Merge:** Shift + right-click an item to start, hold Alt to
  increase or Ctrl to decrease the requested stack size, then Shift + right-click
  the same item (split) or a matching item stack (merge). Operations time out
  automatically.
- **Improved Right Click:** with the appropriate trade/mail/auction window
  open, right-click a bag item to place it or search the auction house.
  Intended for Blizzard default trade/mail/auction UI; third-party mail mods
  need separate compatibility verification.
- **Repeatable Quests (Alt):** hold Alt during the first quest hand-in and
  keep holding it while speaking to the same quest giver to replay that
  quest, including the reward choice. Let go of Alt to clear the recording.
  Reward auto-selection occurs only when the displayed quest title matches.
  Custom auto-gossip and auto-weekly handlers defer to Alt quest repetition.
- **Chat Spam Filter:** repeated author+text lines are hidden for 70 seconds,
  separately for each chat window. Friends and guildmates are exempt.
- **Loot Message Filter:** optionally hide green/blue loot-link chat lines.
- **World Chat** (submenu): choose any combination of **Mute in Dungeons**,
  **Mute in Raids**, **Mute in Battlegrounds**, or **Mute Always**. When one
  of these conditions is active, messages from the `/world` channel are
  temporarily hidden in the chat windows where the channel was enabled.
  The addon does **not** leave the channel, block players, or silence Guild,
  Party, Raid, or other channels. Visibility is restored when the restriction
  ends, only in chat frames that this addon changed. It will not
  automatically rejoin `/world` if the player left the channel manually.
  Disable all four options to always display `/world` normally.
- **Auto Decline Duels:** hold Shift to bypass.
- **Auto Stance:** Warriors/Druids only; react to stance-required spell errors.
- **Salvation Remover** (submenu): **Off**, **Always**, or **Smart**
  (mutually exclusive). Smart checks equipped shields, Bear Form,
  Righteous Fury, or Spirit Armor, depending on class.
- **Mana Buff Remover:** removes selected Wisdom/Intellect/Spirit buffs
  outside BGs. This is intentionally off by default.
- **Battlegrounds** (submenu): Auto Queue, Auto Enter, Auto Leave,
  Auto Release and Block Shared Quests. All three category menus use
  Blizzard's native arrow submenus (`Options > World Chat`,
  `Options > Salvation Remover`, `Options > Battlegrounds`).

### Native key bindings

Use Esc > Key Bindings > **LazyWeirdo** to assign shortcuts to:
Open Configuration, Reload UI, Logout, Unstuck, Follow Target,
Inspect Target, Initiate/Accept Trade, Duel/WSG Enemy Flag Carrier,
Drop WSG Flag/Remove Slow Fall.

No fixed Ctrl+Alt combinations or default key assignments are imposed.

## Tooltip compatibility (Vanilla 1.12.1)

The native Blizzard `UIDropDownMenu_AddButton` API provides
`tooltipTitle` and `tooltipText` for each dropdown entry.
Do not replace a dropdown item's `OnEnter`/`OnLeave` scripts with
a second `GameTooltip` handler: Blizzard reuses those button frames,
and duplicate handlers can show repeated/overlapping tooltip text.
All new and original Options toggles now use the single native tooltip
path, including World Chat, Salvation Remover and Battlegrounds.
After updating the addon, use `/reload` before retesting the menu.

## Test checklist in the Vanilla 1.12.1 client

1. Confirm the addon loads without a Lua error and `/lw` still opens the
   unchanged main panel.
2. Confirm all existing Need/Greed/Pass raid options and white lists persist
   after `/reload`; verify auto-loot and merchant selling/repair as before.
3. Open the World Chat, Salvation Remover and Battlegrounds arrow
   submenus. Select multiple World Chat locations independently; choose
   exactly one Salvation mode (Off, Always, Smart); reload and confirm all
   choices persist per character. Confirm neither submenu throws a Lua error.
4. Test splitting a stack, merging two identical stacks, full bags, locked
   stacks and inventory changes during an operation.
5. Test right-click in default trade, mail (including non-mailable items),
   Auction Browse and Create Auction. Confirm no messages or auctions are
   sent/submitted without the player's deliberate confirmation.
6. Test a repeatable quest with no selectable reward and another with
   multiple reward choices. Release Alt, try a different quest, and confirm
   no incorrect reward is automatically selected.
7. Test World channel masking across world, dungeons, raids and BGs; ensure
   manual World departure is respected. Test spam across two chat windows.
8. Test each BG option separately, including BG invitation expiry, AFK,
   post-match exit and the quest-share popup.
9. Test Warrior/Druid stance switching, Salvation Smart on tank/non-tank,
   and the Mana Buff Remover outside/inside BGs.
10. Check native Key Bindings for every action and confirm no existing
    shortcuts were overwritten.

**Status:** code integrated and structurally reviewed; the World Chat /
Salvation dropdown callbacks were replaced after an in-game Lua error was
reported at LazyWeirdo.lua:1713. The submenu fix itself has not yet been
tested in a running Vanilla/OctoWoW client. Optional integrations and server-specific
APIs require in-game verification.

## Source acknowledgment

- Original addon: [MarcelineVQ/LazyWeirdo](https://github.com/MarcelineVQ/LazyWeirdo) — Weird Vibes.
- Quest workflow inspired by [MarcelineVQ/QuestRepeat](https://github.com/MarcelineVQ/QuestRepeat),
  whose source explicitly declares **LGPL v2.1**. Original author attribution
  and license notices should be retained if reusing or modifying that code.
- Inventory, battleground and other quality-of-life behaviors were studied
  from [Otari98/_LazyPig](https://github.com/Otari98/_LazyPig).
  The implementation here is written in separate modules, not pasted from
  that repository. No additional permission to relicense upstream code is
  implied by the existence of this personal development branch.
