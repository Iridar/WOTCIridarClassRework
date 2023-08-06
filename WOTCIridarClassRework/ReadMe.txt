X2ModBuildCommon v1.2.1 successfully installed. 
Edit .scripts\build.ps1 if you want to enable cooking. 
 
Enjoy making your mod, and may the odds be ever in your favor. 
 
 
Created with Enhanced Mod Project Template v1.0 
 
Get news and updates here: 
https://github.com/Iridar/EnhancedModProjectTemplate 


TODO

- Purge the version check file
- Ensure Random Deck always has 2 empty spots
- Translate ClassRework/XComGame.int and Perk Pack to Russian
- Make some abilities from the perk pack cross class
- Check that all weapon abilities work with weapon upgrades
- Recheck that return fire ignores cover
Integrate relevant stuff from Weapon Fixes https://steamcommunity.com/sharedfiles/filedetails/?id=1737532501 and Ability Interaction Fixes https://steamcommunity.com/sharedfiles/filedetails/?id=1129878719
Patch Saturation Fire and other abilities to build interrupt game state

Blast Padding - integrate More Effective Blast Padding https://steamcommunity.com/sharedfiles/filedetails/?id=1379047477

Rupture - correct description to make it clear bonus damage is applied to Rupture itself too. And forbid using it while disoriented.

Fix Collateral Damage, update localization for changed abilities.


[h1]REQUIREMENTS[/h1]

Template Master - required

[WotC] Weapon Fixes
https://steamcommunity.com/sharedfiles/filedetails/?id=1737532501
Required to make Skirmisher Return fire properly interact with Stock upgrade, Holo Targeting and Shredder.

[h1]SKIRMISHER[/h1]

Skirmishers are universally considered to be the weakest faction hero class. Many of their abilities are either useless or broken, and many can be used only once per mission.
Their Bullpups also have poor scaling. So the result is that they have essentially only one viable build, and even that falls off towards the late game significantly.

Summary of the changes: higher tier Bullpups buffed, charge-based abilities switched to cooldowns, broken abilities fixed, inferior abilities buffed, boring and bad abilities reworked. New abilities added.
Ability tree is rearranged into three coherent specializations with different playstyles and sensible progression.
Three new Major-rank abilities added to further improve their late game.
New XCOM abilities added to the random deck.

[b]Hussar[/b] - classic melee Skirmisher gameplay you know and love. High mobility, offensive use of the Grapple and Ripjack.
[b]Judge[/b] - thrives under pressure, can hold a position while showering enemies with reaction attacks.
[b]Tactician[/b] - master of breaking the flow of enemy actions and the ultimate team player.

[h1]CHANGELOG[/h1]
[list]
[*] Bullpups: mag tier crit damage increased to 2, beam tier base damage increased from 6-7 to 7-8.
[*] Ripjack attacks now have 10% base crit chance, same as swords.
[*] Reflex: can trigger once per turn instead of once per mission.
[*] Zero In: reworked, now stacks are granted by all bullpup attacks, including reaction shots, and melee attacks, and stacks gained on the enemy turn (e.g. from Overwatch) last until the end of your following turn. Additionally, your reaction attacks can deal critical damage.
[*] Full Throttle: kills now also reduce cooldown of Grapple by 1.
[*] Combat Presence: can be used during Interrupt, immediately granting an Interrupt action to another soldier. Can be used during Battlelord, immediately granting a standard action to another soldier.
[*] Whiplash: now has 5 turn cooldown instead of 1 use per mission. Damage scales from 4 to 8 damage, and can crit for additional 1 to 3 damage depending on Ripjack tier. Robotic units now take ~50% increased base damage compared to organics.
[*] Interrupt: now has 5 turn cooldown instead of 1 use per mission and does not cost any action points to activate. Multiple units can now interrupt at the same time. Cannot use Interrupt and Battlelord together.
[*] Waylay: reworked. Now it simply gives Overwatch an extra shot and allows to remain on Overwatch upon taking damage.
[*] Return Fire: now included into main ability tree and ignores enemy cover defense.
[*] Total Combat: now also grants a grenade-only slot.
[*] Retribution: now can trigger only once per turn.
[*] Reckoning: cooldown removed, but now action cost scales with distance to the target. Essentially works same as Ranger's Slash, except it doesn't end turn if you still have actions remaining.
[*] Battlelord: now has 5 turn cooldown instead of 1 use per mission. Fixed bug that allowed it to trigger only once. Multiple units can now use Battlelord at the same time. Cannot use Interrupt and Battlelord together.
[*] Manual Override: now is a free action with a 5 turn cooldown, when used it temporarily resets cooldowns on all abilities that cost action points for one turn. Cooldowns are restored on the next turn.
[*] Parkour: now grants a Move action after using Grapple.
[*] New ability: Predator Strike -> executes an adjacent humanoid enemy. If that enemy is ADVENT, you also reveal the closest ADVENT unit in the fog of war until the end of turn.
[*] New ability: Thunder Lance -> use your grapple to launch grenades. Launched grenades have extra range and deal double damage to targets they impact directly.
[*] New ability: Kinetic Armor -> Absorb missed enemy attacks to generate Shield HP equal to the damage avoided. The shield lasts until the end of your turn. This effect can trigger once per turn."
[/list]



[h1]INCOMPATIBLE AND REDUNDANT MODS[/h1]

Some changes are inspired by following mods. Not a single line of code or asset was borrowed or copied.

I did copy a few icons from Shiremct's Proficiency mods, with permission.

THE FOLLOWING MODS SHOULD NOT BE USED ALONGSIDE THIS MOD. AT BEST THEY WOULD BE REDUNDANT, AT WORST - INCOMPATIBLE.

[*] [b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=1393922219][WOTC] Critical Skirmishing[/url][/b]
[*] [b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=1557499446]Hero Rebalance - Skirmisher[/url][/b]
[*] [b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=1465736030][WOTC] Skillful Skirmishing[/url][/b]
[*] [b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=1125671906]Skirmisher Rebalance[/url][/b]
[*] [b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=1843332083]Whiplash Overhaul[/url][/b]
[*] [b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=1379047477]More Effective Blast Padding[/url][/b]
[*] [b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=1862336674](WOTC) Revival Protocol Charges Fix[/url][/b]
[*] [b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=1123037187][WotC] Revival Protocol Fixes[/url][/b]




# General

* Bullpups - mag tier crit damage increased to 2, beam tier base damage increased from 6-7 to 7-8.
* Ripjack attacks now have 10% base crit chance, same as swords.
* Parkour - now grants a Move action after using Grapple.

# Hussar

Classic melee Skirmisher gameplay you know and love. High mobility, offensive use of the Grapple and Ripjack.

* Reckoning - now works same as Ranger's Slash, but doesn't end turn.
* Wrath
* Full Throttle - kills grant +2 Mobility until the end of turn and reduce Grapple's cooldown by 1.
* Retribution - same as vanilla Bladestorm, but can trigger only once per turn.
* (NEW) Predator Strike - a melee attack that executes an adjacent humanoid enemy. If that enemy is ADVENT, you also reveal the closest ADVENT unit in the fog of war until the end of turn.
* Manual Override - a free action with a 5 turn cooldown, when used it temporarily removes active cooldowns from all abilities that cost action points. Cooldowns are restored at the start of the next turn.

# Judge

Thrives under pressure, can hold a position while showering enemies with reaction attacks.

* Reflex - when attacked, gain an extra action point next turn. Can trigger once per turn instead of once per mission.
* Waylay - gives Overwatch an extra shot and allows to remain on Overwatch upon taking damage.
* Return Fire - when attacked, once per turn return fire with your bullpup, ignoring enemy cover defense.
* Zero In - bullpup and melee attacks grant a stacking buff until the end of your turn of +10 Aim and +10 Crit. Stacks can be built with reaction attacks during enemy turn. Also allows reaction attacks to crit.
* (NEW) Kinetic Armor - absorb missed enemy attacks to generate Shield HP equal to the damage avoided. The shield lasts until the end of your turn. This effect can trigger once per turn."
* Judgement

# Tactician[/b]

Master of breaking the flow of enemy actions and the ultimate team player.

* Interrupt - now has a 3 turn cooldown instead of 1 use per mission and grants two interrupt action points. Essentially Run and Gun with a twist.
* Combat Presence - same, but can be used during Interrupt and Battlelord.
* Total Combat - using items and grenades doesn't end turn and you also gain grenade-only slot.
* Whiplash - now has 5 turn cooldown instead of 1 use per mission. Damage scales from 4 to 8 damage, and can crit for additional 1 to 3 damage depending on Ripjack tier. Robotic units now take ~50% increased base damage compared to organics, down from +100%.
* (NEW) Thunder Lance - use your grapple to launch grenades. Launched grenades have extra range and deal double damage to targets they impact directly.
* Battlelord - now has 5 turn cooldown instead of 1 use per mission. Fixed bug that allowed it to trigger only once. Multiple units can now use Battlelord at the same time. Cannot use Interrupt and Battlelord together.

