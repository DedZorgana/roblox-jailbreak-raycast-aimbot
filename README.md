# Roblox Aimbot

A Roblox aimbot that hooks into the game's raycast system to provide silent aim assistance.

## Description
This script intercepts bullet and taser raycasts and redirects them to the nearest valid target (NPC or enemy player) within a 600-stud range.

### Features
- **Silent Aim**: Redirects projectiles without changing camera view
- **Headshot Priority**: Aims for the head on NPCs by default
- **Smart Targeting**: Automatically switches to visible body parts when head is blocked
- **Key Activation**: Hold **X** to enable, release to disable
- **Auto Cleanup**: Disables on character death or window focus loss
- **Performance Optimized**: Caches NPC data every 0.3 seconds
- **Wall Check**: Only targets visible enemies (no shooting through walls)

---

**Note**: This is a Roblox exploit script. Use at your own risk.
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/DedZorgana/roblox-jailbreak-raycast-aimbot/refs/heads/main/roblox-jailbreak-raycast-aimbot.lua"))()
```
