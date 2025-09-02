UI: Trade analytics
https://www.nexusmods.com/x4foundations/mods/764
by kuertee

Updates
=======
v7.6.1, 14 Jun 2025:
- New feature: Ship builds and resupplies at your wharves and shipyards are now listed in the analytics. Previously, only ship repairs were listed. Note that resupplies are listed like repairs.

Mod effects
===========
Trade analytics, Station behaviour profiles, and other quality-of-life changes.

Requirements
============
SirNukes Mod Support APIs mod (https://www.nexusmods.com/x4foundations/mods/503)
Kuertee's UI Extensions mod (https://www.nexusmods.com/x4foundations/mods/552)

Analytics
=========
Adds sortable analytics in the Transaction Log screen.
Analytics on sales, purchases, and mining activities are listed and can be viewed by total trades, by wares, or by trading ship.
Note that the transaction log of the base game only contains data on purchases and sales.
Data on supply lines (i.e. data on stations purchased from and sold to) are not logged by the base game.
This mod does. But the analytics of player-to-player trades will only be from after the mod is installed.

Station behaviour profiles
==========================
Summary:
For factories to sell to other factions, set their profiles to Factory Outlet.
For factories that only sell to your other stations and build projects, set their profiles to Factory.
For a centralised trading station that sell to other factions: Trading Station profile.
For a centralised storage that distributes to your other stations and build projects: Distribution Centre or Supply Warehouse.

Detailed description:
A station's buy and sale behaviours are determined by the best price it finds for the amount they need.
Supply lines are controlled by setting each station's buy and sale percentages (from their min and max prices) and by their faction restrictions.

Set a station's behaviour by selecting one of the profiles listed below from either its Overview Menu or its Interact Menu.

Not all profiles are required.
E.g. Factories will always sell their produced goods to Trading Stations. And all stations are Trading Stations by default.

But the other profiles allow for more control of supply lines.
E.g.s:
1. Restrict other faction's traders from entering your sector by setting your factories to sell to a Factory Outlet in a different sector.
2. Or set a Factory Outlet near the gate of your home sector. All station set as Factories will sell to that Factory Outlet. And all factions will only buy from that Factory Outlet.
2. Have a store of essential wares for your building projects far from your base sector by building a Supply Warehouse 3 sectors away from a Distribution Centre.

Factory profile:
	Buy: disabled
	Sell: 0%, restricted (sell to player-owned stations only)
	Generally sells to Distribution Centres, Supply Warehouses, Factory Outlets, Trading Stations, your station projects, and your build projects.

Distribution Centre profile:
	Buy: 50%, restricted (buy from player-owned stations only)
	Sell: 0%, restricted (sell to player-owned stations only)
	Generally buys from Factories.
	Generally sells to Supply Warehouses, Factory Outlets, Trading Stations, your station projects, and your build projects.

Supply Warehouse profile:
	Buy: 40%, restricted (buy from player-owned stations only)
	Sell: 60%, restricted (sell to player-owned stations only)
	Generally buys from Factories, and Distribution Centres.
	Generally sells to Factory Outlets, Trading Stations, your station projects, and your build projects.

Factory Outlet profile:
	Buy: 40%, restricted (buy from player-owned stations only)
	Sell: auto, unrestricted (sell to any faction)
	Geberally buys from Factories, Distribution Centres, Supply Warehouses, your station projects, and your build projects.
	Generally sells to Trading Stations.

Trading Station profile:
	Buy: auto, unrestricted (buy from any faction)
	Sell: auto, unrestricted (sell to any faction)
	This is the base game's default setting for all stations.
	Generally buys and sells from any station.

Other quality of life changes
=============================
The ship location next to its name will also show its base location. I.e. it's commander's sector or the sector of operation of its default order.
The total number of subordinates away from their commander or their base station is listed.
The total number of subordinates without a current activity (i.e. idling) is listed.
Your factory counts are listed next to wares in various lists.

UniTrader's Advanced Renaming mod (https://github.com/UniTrader/ut_advanced_renaming)
=====================================================================================
Currently, UniTrader has not supported UI Extension's Multi-rename feature.
But you can get my fork (i.e. my version) of his mod that does from here: https://github.com/kuertee/ut_advanced_renaming.
Click on Code > Download ZIP. Then extract the contents into X4's Extensions folder.

With the mod enabled, these special texts in the name will be replaced with the listed value.
	$kTAP = full profile name
	$kTAp = the acronym of the profile name
	$prodtier = the lowest tier of the station's resource, intermediate or produced ware
	$prodTIER = the highest tier of the station's resource, intermediate or produced ware
	$prodwaretier = the station's resource, intermediate or produced ware with the lowest tier
	$prodwareTIER = the station's resource, intermediate or produced ware with the highest tier

Examples:
1. Select multiple stations.
2. Right-click to open the Interact Menu.
3. Click on Rename.
4. Type: $kTAp T$prodTIER: $prodwareTIER.
5. All stations will be renamed with the station's profile acronym, the station's max tier and the ware of that max tier.
6. Example result: F T2: Antimater Cells. i.e. "F" for factory, "T2" for the station's highest resource or produced ware, which is "Antimater Cells".

Install
=======
- Unzip to 'X4 Foundations/extensions/kuertee_trade_analytics/'.

Uninstall
=========
- Delete the mod folder.

Troubleshooting
===============
1. Allow the game to log events to a text file by adding "-debug all -logfile debug.log" to its launch parameters.
2. If an Extension Options entry exists for the mod, enable the mod-specific Debug Log.
3. Play for long enough for the mod to log its events. Or force the error that you are experiencing.
4. Send the log found in My Documents\Egosoft\X4\(your player-specific number)\debug.log to my e-mail (kuertee@gmail.com) with the mod name in the subject line.

Credits
=======
By kuertee.
Chinese localisation by Tiomer.
French localisation by Calvitix.
German localisation by LeLeon.
Russian localisation by Alexander.

History
=======
v7.5.14, 25 May 2025:
- Bug-fix: The Station Overview menu would stop working after several hours of play - especially after losing a station.
- Bug-fix: Station Profiles variables were not getting initiliased preventing the mod's right-click Interact Menu item from getting shown.

v7.5.13, 15 May 2025:
- Bug-fix: A weird bug that fails when getting the name of a ware from the in-game data.

v7.5.12, 5 May 2025:
- Tweak: Reworked the data structure again to minimise it further. Data on station-station trades have been removed. Only station-ship trades are retained, recoded, and used in the analytics. Previously, trade data is stored at both the ship that performed the trade and at its parent station.
- Bug-fix: Some analytics were still not being shown. Bug caused by the previously doubling of the data at both the ship and at the station levels. Bug found when the data structure was reworked.

v7.5.11, 26 Apr 2025:
- Tweak: Reworked the data storage of the mod. In my game from 2021 in which I have 45 stations, the stored data of 1059 trade records was trimmed down to 899 trade records. 53 trade records were removed because one of the trading partners has been removed from the game. 107 records were consolidated into one. Previously, trades were stored at both trading partners data storage.

v7.5.101, 18 Apr 2025:
- Bug-fix: Forces removal of data of destroyed traders and stations. Their data (although intact even if the trader or station has been destroyed) was preventing the analytics to display simply because the trader has been destroyed.

v7.5.10, 12 Apr 2025:
- New feature: Repairs of ships at the player's wharves and shipyards are now included in the analytics. The analytics do not list what wares they used for repairs (because I don't know how to find that yet). Instead it just shows the ship and its faction that was repaired.

v7.5.09, 08 Apr 2025:
- Bug-fix: Some analytics data were not getting shown.
- Note: Analytics on sold ships from shipyards and wharves are not yet listed. Only production wares are.

v7.5.07, 29 Mar 2025:
- Bug-fix: Delay the render of the analytics panel until the data is ready. This was the cause of the menu eventually breaking.
- Tweak: Russian localisation. Thanks, Alexander!
- Bug-fix: The mod-specific debug logging was likely left on after the last update. This will disable it, if it wasn't already disabled manually in the mod's Extension Options.

v7.5.05, 18 Mar 2025:
- Tweak: Update trade.find.commander script to allow traders to sell produced wares when ware shortages can't be fulfilled.

v7.5.04, 14 Mar 2025:
- Bug-fix: "By Trading Ship" filter wasn't working.
- Bug-fix: Better clean-up of invalid data at every game load.
- Bug-fix: Language files had incorrectly numbered text entries.
- Bug-fix: French language files had missing text entries.

v7.5.03, 03 Mar 2025:
- Bug-fix: (HOPEFULLY) Ultra wide monitor support. The graph above the analytics section was previouly taking up too much of the vertical space.

v7.5.01, 21 Feb 2025:
- Bug-fixes: 7.5 compatibility updates.

*v7.1.16, 03 Dec 2024:
- Bug-fix: The Transaction Log menu was prevented from opening on saved games with a previous version of the mod.
- New feature (for players with the Finance Hub: Transfers mod): Added the new Extension Options setting, List all transfers in one Logbook entry. When enabled, all that mod's transfers are listed in one logbook entry. Helpful for players with many stations.

v7.1.14, 04 Nov 2024:
- Bug-fix: Missing required data wasn't initialised in the last version causing the menus to break.

v7.1.13, 02 Nov 2024:
- New feature: Support for UI Extension's Multi-rename feature.
- Tweaks: Shortcuts for UniTrader's Advanced Renaming: $kTAP = profile's full name, $kTAp = profile's acronym. Read the UniTrader's Advanced Renaming mod section.
- Tweak: Moved the mod's custom Interation Menu from the Orders section to the Actions section.

v7.1.09, 10 Oct 2024:
- New feature: Group analytics by hour.

v7.1.07, 17 Sep 2024:
- New feature: The ware's mouseover tooltip lists the profile the ware's buy/sell settings are nearest, if it is different to the station's profile. E.g. when you set a profile, then change one of its ware's buy/sell settings.
- Bug-fix: The Transaction Log menu sometimes breaks after opening a ship's Transaction Log.
- Bug-fix: The Factory profile listed a 0% buy offer when it should be a 100% buy offer.

v7.1.01, 7 Jul 2024:
- Bug-fix: Stations with the Factory profile weren't buying from stations with the Factory profile. They should have.

v7.0.02, 29 Jun 2024:
- Tweak: 7.00 hf 1 compatibility.
- Maintenance update: use UI Extensions' new method to load mod-specific UIX lua(s)
- Tweak: "presets" are not called "profiles"
- New feature: Add your own or edit existing profiles in "kuertee_trade_analytics_profiles.lua". Some Lua knowledge is required, of course.
- New feature: A station's profile is listed next to its name in the Station Overview menu
- New feature: When manually changing a station's buy and sell behaviour, the profile the setting is most similar to will be listed with an asterisk (*)
- New feature: "Station behaviour profiles" section of this read-me has been updated.

v6.1.001, 28 Jun 2023:
- Tweak: The Station Presets in the Interact Menu are now in Mycu's Custom Actions sub-menu, cleaning up the main Interact Menu.
- Bug-fix: German localisation. Thanks Jagdsystem!

v6.0.0021, 18 Apr 2023:
- Bug-fix: Typo in the Supply Warehouse preset.

v6.0.002, 13 Apr 2023:
- Tweak: Compatibility with version 6.0 final of the base game.

v6.0.0004, 18 Feb 2023:
- Bug-fix: Setting the presents in the Overview screen wasn't working.

v6.0.0001, 07 Feb 2023:
- New feature: Station behaviour presets: Set the station's behaviour to produced wares as Factory, Distribution Centre, Supply Warehouse, Factory Outlet, Trading Station. Read more below.
- New feature: Your owned factory counters next to wares in various lists.

v5.1.0308, 29 Sep 2022:
- Bug-fix: The location and base sector display next to the ship's name wasn't working.

v5.1.0306, 18 Sep 2022:
- New feature: The sector of the ship's default order is listed along with their current location - if they are not in their default sector.
- New feature: The total number of idling traders, miners and builders is listed next to the fleet composition.
- New feature: The total number ships away from their commander's or base's sector is listed next to the fleet composition.
- New feature: German localisation.

v5.1.0009, 23 May 2022:
- New feature: Totals.
- New feature: New filters: (1) combined Sales, Purchases, Mining, (2) to/from faction X, (3) By ware X.
- Tweak: By default, the analytics are listed By All Wares. Previously, they were listed By Totals which combined entries of the same ware. In this new version, wares are listed - and so trading partners that both sold or bought different wares from the subject factory or subject ship will be listed several times, one for each ware.

v4.2.04, 22 Dec 2021:
- New feature: Distance tool: The Interact Menu (i.e. right-click) shows the distance from the selected object or from the last left-click on the holo-map. This requires v4.2.03 of UI Extensions.

v4.2.02, 16 Dec 2021:
- Tweak: UI tweaks for players with scaled resolutions.

v4.1.0, 06 Nov 2021:
- New feature: Better sorting of Trade Analytics data. I.e. 3 levels of column sorts is possible. E.g. sort amount in decreasing order, sort distance by increasing order, sort price by increasing order.
- New feature: Better category selections with pull-down menus. E.g. Sales to other factions, sales to player faction, sales to any faction.
- Tweak: More accurate data generated from Egosoft's transaction logs. You should be able to link data in the Trade Analytics panel with totals in the Transaction Logs. For examples, look at the screenshots (on the NexusMods page).
- Bug-fixes: Many. I.e. The Trade Analytics panel would break if you open a ship's Transaction Log directly from the ship's Information panel (instead of clicking on the ship from the Trade Analytics panel of a station).
- Note: Because Egosoft's transaction logs don't record which station a trading ship is attached WHEN it traded, all the transactions of a trading ship will be attributed to its CURRENT station manager regardless of whether the trading ship was attached to another in the past. I.e. if you attach a trading ship to a station, all its transaction records from before it was attached will be listed under its new station manager.
- Note: Because Egosoft's transaction logs don't record trades between player-owned properties (because no monies are transfered), transactions between player-owned properties are listed from when the mod is installed.

v1.0.3, 13 Sep 2021:
- Bug-fix: The internal data wasn't getting reset properly when you interact with the graph or the history causing the data in the analytics to incrementally increase.
- Bug-fix: Correct the positions of the sorting arrows when the UI is scaled up or down.

v1.0.2, 12 Sep 2021:
- Bug-fix: The Transaction Log screen becomes unresponsive when it encounters an invalid ship or station in the mod's data. This happens when the ship or station is destroyed or when the game removes them when it determines that they are no longer needed. This bug will not occur until after several hours with the mod. I think this is because these invalid entries exists temporarily until they are properly cleaned up after some time. You would have seen these entries in the Trade Analytics screeen as "no longer exists". In this new version, to prevent this bug from happening, these invalid entries are removed. You will no longer see items with the "no longer exists" label.
- Tweak: Bug-fix: When using the By Trading Ship mod, the station was getting listed.
=Tweak: Re-worked the assignmwent of data between the trader ship, the buyer and the seller.
- Tweak: Clicking on a station from a miner's Sales list will automatically set use the Mining category (instead of the Purchases category) when the station's analytics is rendered.

v1.0.1, 11 Sep 2021:
- New feature: Show analytics on all player-owned traders. In the previous version, only stations and ships with no commander have analytics.
- New feature: Analytics of sales to and purchases from other factions are now taken from Egosoft's internal transaction histories. Unfortunately, these transaction histories do not include transactions between player-owned stations. Read more in the "Date range of records" below. I detail this "quirk" in Egosoft's official forums: https://forum.egosoft.com/viewtopic.php?f=146&t=441926
- Tweak: Raw distance instead of gate distance. There's no method to convert the raw distance from Egosoft's internal transaction histories into gate distance.
- Tweak: "By ware" or "By trading ship" lists now count the delivery amounts and are sorted based on those amounts instead of ordering the list based on the name of the ware.
- New feature: Sort order ascending and descending.

v1.0.0, 9 Sept 2021:
- Initial release.