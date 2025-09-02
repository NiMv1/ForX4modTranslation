    The ship bail event has been reorganized.
    To explain for new players, the Bail event is an event that allows the crew and pilot of a ship under attack to abandon the ship, allowing the player to take over the ship.

[h1]# Attention![/h1]
[list]

  [*] [h3]You may need to disable UI Protection mode ("Settings" -> "Extensions" -> "Protected UI Mode") before you can see the manager screen.[/h3]
  [*] [h3]To access the manager or settings screen, the 'upb_lua_loader' mod (ver. 2.00) must be installed.[/h3]

  If the mod works when you start a new game but doesn't work when you load an old save game, try the following steps;
    1- Disable 'upb Bail' mod.
    2- Restart the game and load your save file, then save your save file.
    3- Re-enable 'upb Bail' mod and start the game again.
    4- Load your last saved save file.
  If you're still having problems, contact me on Discord (#fikrethos).

[*] [b]It does not work with other bail modes.[/b]

[*][b]Compatible for x4 6xx and 7.xx.[/b] 
[/list][b]
[/b][b]        Note:[/b] There is a preview versions on the [url=https://www.nexusmods.com/x4foundations/mods/1463?tab=files]nexus mode page[/url] that fixes compatibility
[b]        Note:[/b] for options screens can be accessed from the '[b]upb_MODs[/b]' menu by talking to the NPC or player owned ships pilot.

[h2]# Settings Section.[/h2]
[list]
[*]Changes can be made for each control status value in the Settings section 
[*] Bail trigger time can be adjusted between 3 seconds and 30 seconds.
[*] Bail permission can be arranged separately for Player, Player owned and NPC ships. 
[*] Bail permission of lasertowers can be adjusted. 
[*] Any bail situation can be reported via showhelp or voice. 
[*] If player bail permission is enabled, a report for bail status can be received in the notification window. 
[*] The minimum shield percentage at which the bail event can start can be set. 
[*] The bail chance can be changed for 3 different adjustable armor level situations. 
[*] Separate checks may be made for S, M ships and L, XL ships. 
[*] When the ship is bailed out, its equipment will be protected. Cargo status can be adjusted. 
[*] Bail can be set to be hulled or repair all equipments when a ship is claimed. 
[*] The time for clearing bailed ships from the map can be adjusted, they can be tracked, or unwanted ones can be destroyed manually and remotely. 
  [b]Note:[/b] Those whose destruction time falls below 30 minutes are shown in bright yellow, and those whose destruction time falls below 10 minutes are shown in red. Those shown in gray are the ownerless ships that were in the game before the bail installation. [/list]

[h2]# SCA destroyers will consist of ships belonging to the races listed below:[/h2]
    Argon class has been adjusted to have a higher chance of being determined than others. [list]
[*] ARG : Behemot (Vanguard, Sentinel also E Type with x4 7.00) 
[*] TEL : Phoneix (Vanguard, Sentinel also E Type with x4 7.00) 
[*] PAR : Odyseus (Vanguard, Sentinel and E Type) 
[*] TER : Sin, Osaka (If there is relevant DLC) 
[*] VIG : Barbarossa (If there is relevant DLC) 
[*] BOR : Ray (If there is relevant DLC)
[/list]
[list]
[b]Note:[/b] Before entering the game, the usage chance of ships belonging to the race can be changed by changing the weight values ​​in the '[b]extensions/upb_bail/library/shipgroups.xml[/b]' file or if you do not want SCA destroyer changes you can delete this file.[/list]

[h2]# Eject Chance (1 to xx) = Base Chance - + Remaining Crew Chance + Relative Damage Chance + Size Type - Target Pilot Morale[/h2]
[list]
[*]Remaining Crew Chance will be between -5 and +5. 
[/list]          * Full capacity personnel will bring a -5 value and this value will reduce the eject chance.
          * When the number of personnel reaches half, the impact value will reach 0,
          * As the number of people on the ship decreases, a + value will occur and the chance of bail will increase. 
[list]
[*]Relative Damage Chance will be between 0 to 10
[/list]          * If the attacker is in a class smaller than the target ship, the effect value is 0
          * If the attacker is of the same class as the target ship, the effect value is +1
          * If the attacker is 1 class larger than the target ship, the effect value is +3
          * If the attacker is 2 class larger than the target ship, the effect value is +6   
          * If the attacker is 3 class larger than the target ship, the effect value is +10
[list]
[*]Size Type Chance
[/list]          * ( attacker.shieldpercentage +  attacker.hullpercentage) / (  target.shieldpercentage +  target.hullpercentage)
[list]
[*]Target Pilot Morale
[/list]          * target.pilot.skill.morale (max 12 or 15) * 2 


[h2]## UPB MODs. Access Options:[/h2]
    There are 5 different methods to access UPB MODs.
    [b]Note:[/b] If the option is not opened with the first 4 steps, you are probably using another mod that adds menu options. 
[list][*]1- Talk to NPC ship captains.
        it will appear in the bottom left (#3) position.    [*] 2- Talk to any player ship captain or player station managers. 
        Under the more option, if no other mod has added it to the menu options, it will appear in the left (#2) position.    [*] 3- Talk to Player fleet commander or ship captain if not in the fleet
        a- if there is a "..more. (Mods)" option, that is, if ECM (Extended Conversations Mod v0.20 on Nexus) is installed, it is in this menu.    [*] 4- Talk to any subordinate ship in the player's fleet
        a- if there is a "..more. (Mods)" option, that is, if ECM (Extended Conversations Mod v0.20 on Nexus) is installed, it is in this menu.        b- Otherwise it will appear in an empty slot (#3) in the menu. ( ! unless another mod(s) has added this menu option. )    [*] 5- In this case, use the 'Upb Equipment Modification And Reqruit Service' Mod. 
       This new mode assigns a Spec officer you can talk to when you land at the shipyard or wharf (player or npc) stations.To access UPB MODs, talk to Spec. Officer Nurcan ARIKAN HOS.  [/list]