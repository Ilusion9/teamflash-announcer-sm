# Description
Players and admins can be informed when players are flashed by their teammates.

# Dependencies
- Sourcecolors (include file) - https://github.com/Ilusion9/sourcecolors-inc-sm
- Intmap (include-file) - https://github.com/Ilusion9/intmap-inc-sm

# Alliedmods
https://forums.alliedmods.net/showthread.php?p=2683230

# Overrides
Add "TeamFlashAnnouncer" override in admin_overrides.cfg, so only players with specific flag can be announced about who flashed them.

Add "TeamFlashAnnouncerAdmin" override in admin_overrides.cfg to change the permissions for admins which can see who flashed whom.

# ConVars
```
sm_teamflash_inform_players 1 - Inform players when teammates flashes them?
sm_teamflash_inform_admins 1 - Inform admins when players are flashed by teammates?
sm_teamflash_inform_mintime 1.5 - Minimum flash duration for announcements.
```

# To do
If there are too many reports about team flashes made by disconnected players, then I can show their name/steamid.
