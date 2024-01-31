X2ModBuildCommon v1.2.1 successfully installed. 
Edit .scripts\build.ps1 if you want to enable cooking. 
 
Enjoy making your mod, and may the odds be ever in your favor. 
 
 
Created with Enhanced Mod Project Template v1.0 
 
Get news and updates here: 
https://github.com/Iridar/EnhancedModProjectTemplate 

[WOTC] Iridar's Soldier Class Overhaul

This mod overhauls the four base game classes, three WOTC classes, and SPARKs by fixing bugs, doing small balancing tweaks and in some cases reordering abilities in the ability tree.

This mod is intended as the go-to mod to fix all the various issues with vanilla classes, without the need to collect dozens of mods that individually fix small issues. It integrates fixes from a lot of existing mods, making them incompatible or redundant.


TODO

- Ensure Covering Fire is cross class
- Translate ClassRework/XComGame.int to Russian
- Check that all weapon abilities work with weapon upgrades/ammo/shredder
- Recheck that return fire ignores cover
- Faction heroes
- SPARK
- Check which abilities don't build interrupt game state but should
- Forbid using Rupture while disoriented

; [XComGame.X2SoldierClassTemplateManager]
; +ExtraCrossClassAbilities = (AbilityName="EverVigilant")
; +ExtraCrossClassAbilities = (AbilityName="IRI_AWC_MedicinePouch")

Integrate relevant stuff from Weapon Fixes https://steamcommunity.com/sharedfiles/filedetails/?id=1737532501 
and Ability Interaction Fixes https://steamcommunity.com/sharedfiles/filedetails/?id=1129878719


[h1]REQUIREMENTS[/h1]
[list]
[*] [url=https://steamcommunity.com/workshop/filedetails/?id=1134256495][b]X2WOTCCommunityHighlander[/b][/url]
[*] [url=https://steamcommunity.com/sharedfiles/filedetails/?id=2363075446][b][WOTC] Iridar's Template Master - Core[/b][/url]
[*] [url=https://steamcommunity.com/sharedfiles/filedetails/?id=2166295671][b][WOTC] Core Collection Meta Mod[/b][/url] - fixes SPARK Bulwark and other bugs.
[*] [url=https://steamcommunity.com/sharedfiles/filedetails/?id=1737532501][b][WotC] Weapon Fixes[/b][/url] - required to make Skirmisher Return fire properly interact with Stock upgrade, Holo Targeting and Shredder.

[/list]




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

I did copy a few icons from Shiremct's Proficiency mods, with permission.

Some changes are inspired by following mods, but unless specified, not a single line of code or asset was copied.

[b]THE FOLLOWING MODS SHOULD NOT BE USED ALONGSIDE THIS MOD. AT BEST THEY WOULD BE REDUNDANT, AT WORST - INCOMPATIBLE.[/b]

[*] [b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=700550966]Quickdraw Fix[/url][/b]
[*] [b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=1267996790]Quickdraw Sensitivity[/url][/b]
[*] [b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=1379047477]More Effective Blast Padding[/url][/b]
[*] [b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=1525019760][WotC]Better Demolishing![/url][/b]
[*] [b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=1862336674](WOTC) Revival Protocol Charges Fix[/url][/b]
[*] [b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=1123037187][WotC] Revival Protocol Fixes[/url][/b]
[*] [b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=2648230104]Sacrifice Targeting Fix[/url][/b] - integrated with permission.
[*] [b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=1440747908][WOTC] SPARK Repair Fix/url][/b] - integrated with permission.
[*] [b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=1396894338][WOTC] Electrical Damage Consistency[/url][/b]

[*] [b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=1393922219][WOTC] Critical Skirmishing[/url][/b]
[*] [b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=1557499446]Hero Rebalance - Skirmisher[/url][/b]
[*] [b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=1465736030][WOTC] Skillful Skirmishing[/url][/b]
[*] [b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=1125671906]Skirmisher Rebalance[/url][/b]
[*] [b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=1843332083]Whiplash Overhaul[/url][/b]




[WOTC] A Better Ghost
https://steamcommunity.com/sharedfiles/filedetails/?id=1442995752
Not incompatible, but pointless


[h1]RANGER[/h1]
[list]
[*] Ability tree rearranged.
[*] Phantom now additionally reduces concealment detection range by 50%.
[*] Shadowstrike now actually applies its bonus while concealed instead of against enemies that can't see the Ranger. The bonus is now also provided for the entire turn the concealment was broken, which allows it to apply to melee attacks.
[*] Conceal - updated description to mention it can't be used while flanked.
[*] Implacable - updated description to no longer say you can't attack after gaining the bonus Move.
[*] Untouchable - updated description to no longer say you have to get a kill on your turn. Added a flyover and a buff chevron when the Untouchable bonus is gained. 
[*] Rapid Fire - now has a 4 turn cooldown (down from 5). Cooldown is now mentioned in the extended description.
[*] Deep Cover - now makes Hunker Down grant +2 Armor, if Hunker Down is used manually.
[/list]

[h1]SHARPSHOOTER[/h1]
[list]
[*] Ability tree rearranged.
[*] Squadsight - removed hidden crit chance penalty.
[*] Fire Pistol - removed extended description, as it was pointless and confusing.
[*] Return Fire - now preemptive and ignores cover defense bonus.
[*] Deadeye - aim penalty is now flat -20 Aim and damage boost now applies to the total attack's damage.
[*] Death From Above - now triggers once per turn and works with pistols.
[*] Aim - aim bonus now applies to all attacks made this turn.
[*] Serial - added -20 Crit penalty after each kill (vanilla description mentions a crit chance penalty, but it's not implemented in vanilla)
[*] Fan Fire - now ends turn.
[/list]

[h1]GRENADIER[/h1]
[list]
[*] Blast Padding - now applies to environmental damage.
[*] Demolition - now a guaranteed hit and applies Holo Targeting.
[*] Suppression - now preemptively triggers on attacks, ignores cover defense bonus.
[*] Heavy Ordnance - corrected description to no longer mention Battle Scanners.
[*] Chain Shot - aim penalty moved from the first shot to the second one.
[*] Saturation Fire - now applies ammo effects and is more reliable at destroying cover.
[/list]

[h1]SPECIALIST[/h1]
[list]
[*] Combat Protocol - no longer ends turn.
[*] Revival Protocol - bugfixes, charges changed to 1/2/3.
[*] Haywire Protocol - no longer ends turn.
[*] Scanning Protocol - unlocked camera while targeting. Charges changed to 1/2/3.
[*] Covering Fire - now ignores cover defense bonus.
[*] Threat Assessment - now properly works for Templars. Now also ignores cover defense bonus, but the Covering Fire effect is removed after taking one Overwatch shot.
[*] Ever Vigilant - using Reliable Ever Vigilant is recommended.
[*] Restoration - bugfixes.
[*] Capacitor Discharge - damage now ignores armor.
[/list]

[h1]REAPER[/h1]
[list]
[*] Ability tree reordered.
[*] Shadow, Remote Start, Silent Killer, Needle, Banish - corrected descriptions for clarity.
[*] Soul Harvest - increased Crit Chance boost per kill from 5 to 10 and max Crit Chance boost from 20 to 40. This lets you reach 100% crit at full stacks against flanked enemies if you use either upgraded Superior Laser Sight or Talon Ammo.
[*] Sting - now a guaranteed crit and resets its charge when entering Shadow. Cooldown removed (yes, it had a cooldown despite having only one charge).
[*] New ability: Improvised Silencer - Remove the chance of being revealed on the first shot after entering Shadow.
[*] New ability: Shadow Rising - Shadow gains an additional charge.
[*] New Ability: Death Dealer - Critical shots against a flanked target while in Shadow will deal double critical damage.
[/list]

[h1]SKIRMISHER[/h1]
[list]
[*] Ability tree reordered.
[*] Reckoning - no longer has a cooldown, but dash attacks (outside blue move range) consume more action points.
[*] Reflex - now triggers once per turn instead of once per mission.
[*] Total Combat - now also grants a Grenade-only slot. Now a cross-class perk, but not available to Grenadiers.
[*] Interrupt - now grants two actions and has a 3 turn cooldown instead of one use per mission. Multiple units can Interrupt together now.
[*] Zero In - now works with melee attacks and grants +20 Crit per attack (up from +10).
[*] Combat Presence - can now be used during Interrupt and Battlelord.
[*] Full Throttle - now also lowers Grapple's cooldown when procs.
[*] Return Fire - now a part of the main ability tree and ignores enemy's Cover defense.
[*] Waylay - corrected description for clarity. Now allows reaction attacks to crit.
[*] Whiplash - now has a 4 turn cooldown instead of one use per mission. Damage values rebalanced. Now pierces armor and can crit.
[*] Manual Override - corrected description to make it clear it's an active ability.
[*] Battlelord - fixed bug that prevented it from triggering more than once. Multiple units can use Battlelord together now. Battlelord and Interrupt cannot be used at the same time.
[*] Parkour - using Grapple now grants a move-only action. Replaces the old effect.
[*] Ripjacks - now have 10% innate chance to crit, same as swords.
[*] Bullpups - mag tier crit damage increased to 2, beam tier base damage increased from 6-7 to 7-8.
[*] New ability: Forward Operator -> immediately gain an extra action when a new group of enemies is revealed. Triggers once per turn.
[*] New ability: Thunder Lance -> Launch grenades with your grappling hook, extending their range by 6 tiles and dealing double damage and bypassing armor on direct impact.
[*] New ability: Tactical Readiness -> using Hunker down grants you an extra action point on your next turn.
[/list]

[h1]SPARK[/h1]
[list]
[*] Bulwark - updated description to mention enemies receive cover too.
[*] Repair - amount repaired now scales with BIT tier. Cures acid and other stuff normally healed by Medikit, though SPARK is immune to it anyway.
[*] Bombard - now shreds 1/2/3 armor.
[*] Sacrifice - integrated Sacrifice Targeting Fix.
[/list]

RandomAbilityDecks=(DeckName="ReaperXComAbilities",          
Abilities=(
(AbilityName="Shredder",  ApplyToWeaponSlot=eInvSlot_PrimaryWeapon),               
(AbilityName="Squadsight"),               
(AbilityName="KillZone", ApplyToWeaponSlot=eInvSlot_PrimaryWeapon),               
(AbilityName="TacticalRigging"),               
(AbilityName="HoloTargeting",  ApplyToWeaponSlot=eInvSlot_PrimaryWeapon),               
(AbilityName="Deadeye", ApplyToWeaponSlot=eInvSlot_PrimaryWeapon),               
(),               (),               ()))
