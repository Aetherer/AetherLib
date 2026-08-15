# ✨ AetherLib v1.0

> A premium Roblox UI library with an **ethereal glassmorphism** aesthetic. Built for script executors who demand both beauty and performance.

![Roblox](https://img.shields.io/badge/Roblox-Lua-blue?style=for-the-badge&logo=roblox&logoColor=white)
![Version](https://img.shields.io/badge/Version-1.0-purple?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

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
```

---

## 📦 Components

| Component | Method | Description |
|-----------|--------|-------------|
| 🔘 **Button** | `CreateButton({Name, Description, Callback})` | Clickable button with optional description |
| 🔄 **Toggle** | `CreateToggle({Name, Default, Callback})` | ON/OFF switch with spring animation |
| 📊 **Slider** | `CreateSlider({Name, Min, Max, Default, Increment, Suffix, Callback})` | Smooth value slider with glow knob |
| 📋 **Dropdown** | `CreateDropdown({Name, Options, Default, Callback})` | Expandable selection menu |
| ⌨️ **Input** | `CreateInput({Name, Default, Placeholder, Callback})` | Text input field |
| 🏷️ **Label** | `CreateLabel({Text, Color})` | Display text |
| 🔑 **Keybind** | `CreateKeybind({Name, Default, Callback})` | Keyboard shortcut binding |
| 🎨 **Color Picker** | `CreateColorPicker({Name, Default, Callback})` | Color selection |
| 📑 **Section** | `CreateSection({Text})` | Category divider with underline |

---

## 🎨 Customization

```lua
-- Change theme colors
AetherLib.Config.Theme.Primary = Color3.fromRGB(255, 0, 128)  -- Main accent
AetherLib.Config.Theme.Accent = Color3.fromRGB(0, 255, 255)   -- Highlight
AetherLib.Config.Theme.Background = Color3.fromRGB(15, 15, 25) -- Background

-- Disable sound effects
AetherLib.Config.Sounds.Enabled = false

-- Adjust animation speed
AetherLib.Config.Animation.TweenTime = 0.5
```

### Default Theme Palette

| Token | Color | Usage |
|-------|-------|-------|
| `Primary` | `#8A2BE2` | Borders, highlights |
| `Accent` | `#00FFFF` | Active states, values |
| `Background` | `#0F0F19` | Window background |
| `Surface` | `#191928` | Card backgrounds |
| `Success` | `#00FF96` | Positive feedback |
| `Error` | `#FF3264` | Errors, close button |
| `Warning` | `#FFB400` | Warnings, minimize |

---

## 🛠️ API Reference

### Window
```lua
local Window = AetherLib:CreateWindow({
    Name = "Window Title",           -- string
    Icon = "rbxassetid://...",       -- string (optional)
    Size = UDim2.new(0, 600, 0, 400) -- UDim2
})
```

### Tab
```lua
local Tab = Window:CreateTab({
    Name = "Tab Name",               -- string
    Icon = "rbxassetid://..."        -- string (optional)
})
```

### Notification
```lua
AetherLib:Notify({
    Title = "Title",                 -- string
    Message = "Message body",        -- string
    Type = "Info",                   -- "Info" | "Success" | "Warning" | "Error"
    Duration = 4                     -- number (seconds)
})
```

---

## ⚡ Features

- 🎭 **Glassmorphism UI** — Frosted glass panels with backdrop blur effect
- 🌟 **Particle System** — Floating ethereal particles in the background
- 💡 **Glow Effects** — Soft ambient glow around the window frame
- 🎵 **Audio Feedback** — Subtle sounds on interaction (toggleable)
- 🖱️ **Draggable** — Move the window by dragging the title bar
- 📐 **Minimize** — Collapse to title bar only
- 📬 **Notification Queue** — Notifications stack and display sequentially
- 🎯 **Spring Animations** — Physics-based UI transitions
- 📱 **Touch Support** — Works with both mouse and touch input

---

## 📋 Requirements

- Roblox Executor (Synapse X, KRNL, Fluxus, etc.)
- `loadstring` or `require` support
- `game:GetService("TweenService")` access

---

## 📄 License

MIT License — Free to use, modify, and distribute.

---

<p align="center">
  <b>Made with 💜 for the Roblox scripting community</b>
</p>
