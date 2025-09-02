UI: Accept mission for later
https://www.nexusmods.com/x4foundations/mods/590
by kuertee

Updates
=======
v7.5.01, 21 Feb 2025:
-Bug-fixes: 7.5 compatibility updates.

Mod effects
===========
Missions accepted from the Map and Briefing menus activate only if the player doesn't have an active mission.
Multiple faction missions are allowed.
Changing the active mission doesn't interrupt the autopilot.
The Guidance Marker is not removed at arrival to it.

Requirements
============
SirNukes Mod Support APIs mod (https://www.nexusmods.com/x4foundations/mods/503) - for Lua Loader.

Install
=======
-Unzip to 'X4 Foundations/extensions/kuertee_ui_accept_mission_for_later_button/'.
-Make sure the sub-folders and files are in 'X4 Foundations/extensions/kuertee_ui_accept_mission_for_later_button/' and not in 'X4 Foundations/extensions/kuertee_ui_accept_mission_for_later_button/'.

Uninstall
=========
-Delete the mod folder.

Troubleshooting
===============
(1) Do not change the file structure of the mod. If you do, you'll need to troubleshoot problems you encounter yourself.
(2) Allow the game to log events to a text file by adding "-debug all -logfile debug.log" to its launch parameters.
(3) Enable the mod-specific Debug Log in the mod's Extension Options.
(4) Play for long enough for the mod to log its events.
(5) Send me (at kuertee@gmail.com) the log found in My Documents\Egosoft\X4\(your player-specific number)\debug.log.

Credit
======
By kuertee.
German localisation by MeTalaman.

History
=======
v7.0.02, 29 Jun 2024:
-Tweak: 7.00 hf 1 compatibility.
-Maintenance update: use UI Extensions' new method to load mod-specific UIX lua(s)

v6.2.001, 10 Sep 2023:
-Bug-fix: Sometimes, the mod would prevent the acceptance of new missions.

v6.0.002, 13 Apr 2023:
-Tweak: Version number update for consistency with my other mods. No internal changes since the last version.

v4.2.0804, 2 Feb 2022:
-Tweak: After accepting a mission, the mission description will now show in the correct mission category. Previously, it was shown as if it was a "Plot" mission every time, e.g. even if it was an "Upkeep" mission.
-Bug-fix: The accept signal to the client was occuring twice resulting in a non-game-breaking error.

v4.1.02, 06 Nov 2021:
-Bug-fix: I broke the previous version. This version fixes this mod.

v4.1.01, 18 Sep 2021:
-Bug-fix: The previous version prevented the mod to work unless my other mod, Accessibility Features is also installed. This version fixes this.

v4.1.0, 18 Sep 2021:
-Tweak: Accessibility Features compatibility: Activate missions immediately on accepting a mission - disabling one of Accept Mission For Later mod's features. But its other features are still recommended: e.g. Do not interrupt autopilot when the guidance marker is changed.

v2.0.3, 31 Aug 2021:
-Tweak: The Activate For Later function is disabled when the Accessibility Features mod is installed. Its better accessibility-wise that missions are activated immediately after accepting them. But the other features (e.g. changing the active mission doesn't interrupt the autopilot) are left enabled.

v2.0.2, 11 Aug 2021:
-Bug-fix: The Guidance Marker is not removed on arrival to it. The previous version only prevented the auto-pilot from getting interrupted when it was removed or changed. In this version, it is also not removed unless the user aborts the Guidance Mission, the destination becomes invalid (e.g. the station is destroyed), or the Guidance Marker is moved by the user or by a mission.

v2.0.1, 19 Apr 2021:
-New feature: Guidance to Position/Object now does not get removed UNLESS you abort or set it somewhere/something else. This allows you to switch missions without the auto-pilot getting interrupted.

v2.0.0, 11 Mar 2021:
-New feature: updated for v4.0.0 beta 11 of the base game.
-Tweaks: Cleaned-up unnecessary localisation files. Rewrote content.xml manifest file.
-New feature: multiple faction missions are allowed.

v1.0.2, 28 Dec 2020:
-Tweak: Added dependencies checks in the content.xml file as recommended by MeTalamon.

v1.0.1, 8 Dec 2020:
-Bug fix: Allow this mod to work in Mission Briefing screens that are spawned from outside the Map menu.

v1.0.0, 2 Dec 2020: Initial release.
