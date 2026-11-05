# Personal fork: quality-of-life development branch

This branch keeps the original LazyWeirdo 1.8.0 loot engine, raid rules,
vendor lists, minimap button and main configuration panel. No LazyPig loot
handlers or automatic Need/Greed/Pass rules are imported.

## Configuration

Open `/lw`, then the existing **Options** dropdown. All new automations
start disabled; existing settings are not reset or replaced.

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

## Dropdown tooltip compatibility (Vanilla 1.12.1)

All LazyWeirdo Options entries (including World Chat, Salvation Remover and
Battlegrounds) and list entries now display the same tooltip style as the
original **Add New Item**: title in the addon tooltip color, white description,
optional grey instruction, and `ANCHOR_BOTTOMRIGHT` positioning.

The 1.12.1 dropdown controls recycle the physical `DropDownListNButtonM`
frames across menu owners and depths. The addon installs the hover/click
wrappers **once per button** and updates their owner-scoped data whenever that
button is used for a different menu entry. Vanilla hover/arrow navigation and
left-click behavior are preserved. The built-in `tooltipTitle`/
`tooltipText` fields are cleared before adding the button, preventing a
second NewbieTip from appearing. Item-list right-click deletion is handled
by the same owner-checked wrapper, avoiding stale removal callbacks.

After updating the addon, **reload the UI** and test the following:
- Hover the original Options toggles and the Off/Always/Smart Salvation modes.
- Hover the World Chat and Battleground parent entries and their submenus.
- Hover Add New Item and individual entries in Buy/Sell/Need/Greed/Pass lists.
- Switch repeatedly between menus and confirm each tooltip matches its row.
- Confirm list right-click still asks for removal, while right-clicking an
  Options toggle never opens a stale item-removal prompt.
- Confirm left-click toggles, mode selection and submenu arrows still work.

## Test checklist in the Vanilla 1.12.1 client

1. Confirm the addon loads without a Lua error and `/lw` still opens the
   unchanged main panel.
2. Confirm all existing Need/Greed/Pass raid options and white lists persist
   after `/reload`; verify auto-loot and merchant selling/repair as before.
3. Open the World Chat, Salvation Remover and Battlegrounds arrow
   submenus. Select multiple World Chat locations independently; choose
   exactly one Salvation mode (Off, Always, Smart); reload and confirm all
   choices persist per character. Confirm neither submenu throws a Lua error.
4. Test a repeatable quest with no selectable reward and another with
   multiple reward choices. Release Alt, try a different quest, and confirm
   no incorrect reward is automatically selected.
5. Test World channel masking across world, dungeons, raids and BGs; ensure
   manual World departure is respected. Test spam across two chat windows.
6. Test each BG option separately, including BG invitation expiry, AFK,
   post-match exit and the quest-share popup.
7. Test Warrior/Druid stance switching, Salvation Smart on tank/non-tank,
   and the Mana Buff Remover outside/inside BGs.
8. Check native Key Bindings for every action and confirm no existing
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
- Battleground and other quality-of-life behaviors were studied
  from [Otari98/_LazyPig](https://github.com/Otari98/_LazyPig).
  The implementation here is written in separate modules, not pasted from
  that repository. No additional permission to relicense upstream code is
  implied by the existence of this personal development branch.

## World and dungeon BoE default

The initial World and Dungeon BoE rule (`Other`) is now **Off**, leaving rolls
manual unless a matching enabled whitelist applies. Existing saved settings
are preserved.

Validated in game by the maintainer on 2026-10-31: a character without prior
configuration starts with **Off** for World and Dungeon BoEs.

## Inventory conveniences removed

Stack splitting/merging and contextual right-click handling have been removed,
along with their Options entries and inventory module. Use the client stack
splitting interface and native or dedicated addon trade/mail/auction workflows.
LazyWeirdo no longer wraps `UseContainerItem`; existing saved values for the
removed options are ignored. Loot rules and vendor automation are unchanged.

After reloading, verify that Options opens without the removed entries, native
Shift-left-click stack splitting works, and trade/mail/auction behavior works
with the installed addons (including TurtleMail). Also check automatic vendor
selling. The maintainer confirmed in-game validation of these changes on
2026-10-31.

## Quest-item loot confirmation

Automatic bind confirmation now requires authorization for the same loot slot
and item link from the current loot window. This covers quest BoP items that
are eligible for automatic pickup even when their general roll rule is Off.
Manual pickup keeps its manual confirmation. Pass-list restrictions remain
in place. Master-looter restrictions remain in place for other items; the
three Argent Dawn Scourgestones have a specific pickup exception by item ID
(12840, 12841, 12843). Pending slots are cleared when looting opens,
closes, or the slot is emptied. Delayed bind events are processed on OnUpdate.
Tooltips are cleared and scanned again per slot using client localization
constants with English fallbacks, without a persistent item-name cache.

The user confirmed Scourgestone automatic pickup works in the client after
the item-ID exception was added. The full scenario matrix below remains to
be validated:
- Loot a quest BoP item solo and in a group with its roll rule set to Off.
  Verify pickup and automatic confirmation, including delayed confirmations.
- Put the item on the enabled Pass List; verify no automatic pickup or bind
  confirmation. Hold Shift to bypass autoloot and verify confirmation is manual.
- Test all three Scourgestones solo, in a group with Off/Pass as the general
  rule, and as Master Looter. Verify automatic pickup even when the tooltip
  has no Quest Item line. Verify the enabled Pass List still prevents pickup.
- As raid master looter, verify other quest BoP items remain untouched.
- Close a pending loot window, open another corpse, and verify its slots are
  never confirmed using the previous window's authorization.
- Test full bags, an emptied slot, and two successive corpses carrying the same
  item. Verify no repeated bind attempts or stale tooltip classification.
