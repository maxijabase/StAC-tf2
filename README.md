<h1>  Steph's AntiCheat </h1>




[![Version](https://img.shields.io/github/v/release/sapphonie/StAC-TF2?color=98FB98&style=for-the-badge)](https://github.com/sapphonie/StAC-tf2/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/sapphonie/Stac-TF2/total?color=%239370D8&label=Downloads%20since%20v5&style=for-the-badge)](https://github.com/sapphonie/StAC-tf2/releases/latest)
[![Dev discord](https://img.shields.io/badge/Dev%20discord-%23StAC-7289DA?style=for-the-badge&logo=discord)](https://discord.gg/tUGgCByZVJ)
[![Donations](https://img.shields.io/badge/Support%20me-here!%20:\)-1F1F2A?style=for-the-badge)](https://sappho.io/donate)

<div align="center">
<img src="https://i.imgur.com/RKRaLPl.png" alt="StAC" width="256" style="float: center;"/>
</div>

### This plugin - "StAC" - and the ones bundled with it, can detect, log, patch, and punish for a majority of the cheats, macros, and unfair scripts available for Team Fortress 2, including:
- pSilentAim / NoRecoil / Angle Repeat cheats
- Plain aimsnap / Aimbot cheats
- Auto bhop cheats
- Fake eye angle cheats
- NoLerp cheats
- Some FoV cheats
- Spinbot cheats
### It also prevents and/or detects:
- Newlines/invalid characters in chat messages
- Cmdnum manipulation (clientside nospread)
- Tickcount manipulation (backtracking) - [Thank you to JTanzinite, author of LilAC](https://github.com/J-Tanzanite/Backtrack-Patch)!
- Interp/lerp abuse
- Clients using +right/+left inputs
- "Ping reducing" cheats (and patches "pingmasking" by legit clients as well)
- Clients purposefully not authorizing with Steam

##
I hate cheaters. Everyone does. But you know what I hate more? Taking the sweet time out of my day to catch them. A lot of TF2 cheats do a lot of the same things, and if you know what to look for, you can detect their patterns and ban them ***automatically***!

But wait. Don't server-side anticheats suck?

***They don't have to.***

Of course, there's limitations to what this plugin can do. It can't scan the memory or programs on your computer, it can't see exactly what keys you're pressing on your keyboard, and players don't live inside the server room, so there's always the factor of lag and loss. 

But StAC is written so that it has as few false detections as possible, because **no one wants to get banned when they weren't cheating**. I've reverse engineered cheats, installed them myself (on an alt, don't worry!) and I've tested and refined this plugin over the course of years and thousands of hours of work so that it ignores legit clients, and only goes after naughty cheaters. StAC [runs on](https://sappho.io) [more community servers](https://creators.tf) [than you might think](https://gflclan.com/), too, and has banned thousands of cheaters. 

Even better, this plugin is set up to be as easy to use and install as possible, so you don't have to be a sourcemod guru to get rid of cheaters on your nfoserver. 

### Installation & Configuration

0) Install the recommended extensions and plugins:
- [Discord API](https://forums.alliedmods.net/showthread.php?t=292663) for Discord Webhook logging
- [My fork of SourceTVManager](https://github.com/sapphonie/sourcetvmanager/releases/tag/v1.2s) for stv demo tick logging

1) download the latest release (called `stac.zip`) from [here](https://github.com/sapphonie/StAC-tf2/releases/latest)
2) extract the downloaded zip, and copy all the folders inside of it into `/tf/addons/sourcemod/` on your tf2 server. Overwrite any files if prompted.
3) restart your server

The current list of cvars is listed [here](cvars.md). The defaults should be good for most people, if you want to the plugin to autoban. If not, you can set any "detection" cvar to 0 to never ban, and to -1 to never even log or check in the first place. If you want to edit cvars,

4) wait 30 seconds after doing the above
5) edit `/tf/cfg/sourcemod/stac.cfg` to your liking
6) restart your server again

You should be good to go!

### Sourcebans
This plugin is compatible with [SourceBans](https://sbpp.dev/), [gbans](https://github.com/leighmacdonald/gbans), and the default TF2 ban handler, and auto detects which it should use. The plugin, by default, logs the currently recording demo (if one is recording) to the sourcebans ban message. To disable this, set `stac_include_demoname_in_sb` to `0`.

### Chat logging, file logging and Discord logging
This plugin prints detections to any clients on the server with the `sm_ban` permission, and the running SourceTV bot, if one exists. It saves more verbose logs to `/tf/addons/sourcemod/logs/stac/stac_month_day_year.log` by default, as well. To disable this verbose logging to file, set `stac_log_to_file` to `0`. This plugin can also log to a Discord channel via a webhook, in combination with zipcore's [Discord API](https://forums.alliedmods.net/showthread.php?t=292663) plugin. Edit `/tf/addons/sourcemod/configs/discord.cfg`, to look like the following code snippet, and StAC will print all detections to that channel as well.

```
"Discord"
{
    "stac"
    {
        "url"   "discord webhook url"
    }
}
```

### Disclaimers
Though I wrote StAC to throw as few false positives as possible, I can't guarantee perfection. I also can't guarantee that everything will always work how it's supposed to. Please submit a bug report if you can reproduce a way to trigger false positives, or for any bug or feature request. If you're more comfortable talking to me personally about it, join the development discord for StAC here: https://discord.gg/tUGgCByZVJ


### Special Thanks etc.

LilAC: https://forums.alliedmods.net/showthread.php?t=321480 - JTanz rocks!

SMAC: https://github.com/Silenci0/SMAC

SSaC: Private - [AS] Nacho Replay, dog, and Miggy - RIP

Backwards - coding

Asherkin - coding

Addie - coding

JoinedSenses - coding

Everyone else in the sourcemod discord who had to put up with my asinine questions

Aad

dog - beta testing

elektro - beta testing

Creators.TF Community - beta testing

Nanochip - rare code audits

Miggy - this one's for you, bud.
