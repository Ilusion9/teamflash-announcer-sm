# Description
Players and admins can be informed about flashes made by teammates.

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
