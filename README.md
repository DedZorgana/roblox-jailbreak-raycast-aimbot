```
# Description:
This script implements an aimbot for a Roblox game by hooking into the game's raycast system.
 It intercepts bullet and taser raycasts and redirects them to the nearest valid target (NPC or enemy player) within a 600-stud range.
 The aimbot prioritizes headshots for NPCs and automatically adjusts aim to visible body parts when the head is obstructed.
 It activates while holding the X key and deactivates upon release, with automatic cleanup on character death or window focus loss.
 The system caches NPC data every 0.3 seconds for performance optimization and includes visibility checks to prevent shooting through walls.
```
