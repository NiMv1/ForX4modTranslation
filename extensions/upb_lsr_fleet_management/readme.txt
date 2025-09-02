Allows for automatic construction of exploding ships in a registered fleet and preserving the fleet structure. (for commanders or all their subordinates).
  Note: For fleets whose Commander is a station, only the station itself cannot be produced.

[h1]# Attention![/h1]
[list]

  [*] [h3]You may need to disable UI Protection mode ("Settings" -> "Extensions" -> "Protected UI Mode") before you can see the manager screen.[/h3]
  [*] [h3]To access the manager or settings screen, the 'upb_lua_loader' mod (ver. 2.00) must be installed.[/h3]
  
  [*] COMPATIBLE WITH x4 6.xx, 7.10 and 7.50
    [b]Note 1:[/b] There is a preview versions on the [url=https://www.nexusmods.com/x4foundations/mods/1479?tab=files]nexus mode page[/url] that fixes compatibility.
    [b]Note 2:[/b] You can continue to use rfm records in old save files with the this new mod.
  [*] Do not enable VIA Egosoft 'lost ship replacement' for a Fleet with RFM enabled.
[/list]

[h2]# RFM Global:[/h2]
[list]
  [*] RFM To Enable / Disable, talk to the fleet commander's pilot or station manager.
  [*] Assignment changes resulting from explosions after activation are not taken into account (since fleet information is recorded).
    However, manual changes to the fleet structure, such as manually removing a ship from the fleet or adding an external ship to the fleet, automatically updates the fleet record.
    If a registered fleet is connected to a new ship, the connected ship inherits the existing fleet registration.
  [*] If the actual command ship dies, the Promoted Commander temporarily executes the default order and with individual instructions.
  [*] You can create a clone rfm for the ship and its subordinates you select from within the rfm.
  [*] The real command ship takes over again when its construction is completed.
[/list]
  [b]Note 1:[/b] The hammer cursor that you can see in the rfm lines on the manager screen is because egosoft's 'lost ship replacement' is also opened for that fleet. Please use only one method for the replacement process.
  [b]Note 2:[/b] For options screens can be accessed from the upb_Mods menu by talking to the NPC or player owned ships pilot or talk with Spec Officer Nurcan.

[h2]# Ship information to be recorded for RFM:[/h2]
[list]
  [*] the loadout of the ships 
   ( including 
     shields, 
     weapons, 
     turrets,
     engines,
     and the slots they are installed in,
     ammo, 
     deployables,
     flares
   ) will be preserved
  [*] paint modification
  [*] the number of pilots/personnel and their gender, faction and ranks
  [*] assignment
  [*] group status
  [*] ship name
  [*] default order
  [*] individual instruction informations.
[/list]

[h2]# Default orders that RFM can record:[/h2]
[list]
  [*] All default orders of Egosoft. (including loop orders)
  [*] Reaction Force (Shibdib)
  [*] TaterTrade (Ludsoe and DeadAir)
  [*] Sector Explorer (Assailer)
  [*] Inventory Collector (Assailer)
  [*] Sector Patrol (Assailer)
  [*] Protect Sector (Chem O`Dun) [b]new[/b]
[/list]
  [b]Note:[/b] If a default order other than the above is given, the order that will be valid for RFM will be the MoveWait order for that sector.

[h2]# Shipyard selection criteria for the ships to be produced:[/h2]
  You can create a blacklist for the wharf or shipyard you want in the settings menu for the production stations to be selected.
[list]
    [*] Can the relevant station produce the class to which the ship belongs?
    [*] Is the relevant station capable of producing ship chassis?
    [*] Are there enough relations to dock to the relevant faction station?
    [*] Does the relevant station have a shiptrader?
    [*] Are the military or capital ship licenses of the relevant station that will produce the ship open?
    [*] Can the blueprints of the equipment installed on the ship (shields, weapons, turrets, etc.) be provided by the relevant station?
    [*] Have the relevant station and the sector where the station is located been discovered by the player before?
[/list]
  After these criteria;
[list]
    [*] If the player has enough money (the ship cost is calculated based on the sellprice of the selected station).
    [*] Among the determined stations, the one closest to the RFM sector of the ship to be produced and Priority is given to the station with an empty production slot on the production line.
  [b]Note:[/b] Since the chassis and equipment blueprints of each faction can be learned in player shipyards, production controls will be easily passed. Thus, you can produce more easily.
[/list]

[h2]# Missing points:[/h2]
[list]
  [*] In RFMs whose commander is a station, if the station is destroyed, the station is not rebuilt.
      If this situation occurs, the relevant RFM will be disabled.
  [*] When an rfm with an exploded ship connects to another rfm, existing ships will be connected. The exploded ship record will not be transferred.
[/list]

[h2]# RFM. Access Options:[/h2]
[list]
  [*] Talk to Player fleet commander or ship captain if not in the fleet or player station manager.
    a- In the '..more. (Mods)' option if ECM (Extended Conversations Mod) is installed.
    b- else dialog #3 ( ! unless another mod has added this menu option. )
[/list]

[h2]# UPB MODs. Access Options:[/h2]
  There are 5 different methods to access UPB MODs.
  !!! If the option is not opened with the first 4 steps, you are probably using another mod that adds menu options.
[list]
  [*]1. Talk to NPC ship captains.
      it will appear in the bottom left (#3) position.
  [*]2. Talk to any player ship captain or player station managers.
      Under the more option, if no other mod has added it to the menu options, it will appear in the left (#2) position.
  [*]3. Talk to Player fleet commander or ship captain if not in the fleet.
      a- if there is a &quot;..more. (Mods)&quot; option, that is, if ECM (Extended Conversations Mod v0.20 on Nexus) is installed, it is in this menu.
  [*]4. Talk to any subordinate ship in the player's fleet.
      a- if there is a &quot;..more. (Mods)&quot; option, that is, if ECM (Extended Conversations Mod v0.20 on Nexus) is installed, it is in this menu.
      b- Otherwise it will appear in an empty slot (#3) in the menu. ( ! unless another mod(s) has added this menu option.)
  [*]5. In this case, use the 'Upb Equipment Modification And Reqruit Service' Mod.
      This new mode assigns a Spec officer you can talk to when you land at the shipyard or wharf (player or npc) stations.
    To access UPB MODs, talk to Spec. Officer Nurcan ARIKAN HOS.
[/list]