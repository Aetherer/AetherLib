# ✨ AetherLib v1.0

&gt; A premium Roblox UI library with an **ethereal glassmorphism** aesthetic. Built for script executors who demand both beauty and performance.

<p align="center">
  <img src="https://img.shields.io/badge/Roblox-Lua-blue?style=for-the-badge&logo=roblox&logoColor=white"/>
  <img src="https://img.shields.io/badge/Version-1.0-purple?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge"/>
</p>

---

## 🌌 Overview

**AetherLib** is a next-generation Roblox UI library designed to stand out from the crowd. Unlike traditional dark-themed libraries, AetherLib features a **cosmic glassmorphism design** with floating particles, soft glows, and fluid spring animations — creating an interface that feels alive.

### What Makes AetherLib Different?

| Feature | AetherLib | Others |
|---------|-----------|--------|
| 🎨 Design | Cosmic Glassmorphism + Particles | Flat Dark Mode |
| ✨ Effects | Glow, Particles, Gradient | None |
| 🔊 Audio | Click/Hover/Toggle Sounds | Silent |
| 🌊 Animations | Spring Physics + Back Easing | Basic Fade |
| 📬 Notifications | Queued with Progress Bar | Overlapping |

---

## 🚀 Quick Start

```lua
local AetherLib = loadstring(game:HttpGet("YOUR_RAW_URL_HERE"))()

-- Create Window
local Window = AetherLib:CreateWindow({
    Name = "Aether Hub",
    Icon = "rbxassetid://7733965386",
    Size = UDim2.new(0, 600, 0, 400)
})

-- Create Tab
local MainTab = Window:CreateTab({
    Name = "Main",
    Icon = "rbxassetid://7733965386"
})

-- Add Components
MainTab:CreateSection({Text = "General"})

MainTab:CreateButton({
    Name = "Execute",
    Description = "Click to run script",
    Callback = function()
        print("Button clicked!")
    end
})

MainTab:CreateToggle({
    Name = "Auto Farm",
    Default = false,
    Callback = function(state)
        print("Auto Farm:", state)
    end
})

MainTab:CreateSlider({
    Name = "Walk Speed",
    Min = 16,
    Max = 200,
    Default = 16,
    Suffix = " Studs/s",
    Callback = function(val)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = val
    end
})

-- Show notification
AetherLib:Notify({
    Title = "Welcome!",
    Message = "AetherLib loaded successfully",
    Type = "Success",
    Duration = 5
})
