--// AetherLib v1.0.1
--// Premium Roblox UI Library
--// Fixed: Unable to cast value to Object error
--// Compatible with most Roblox Executors

local AetherLib = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

--// Configuration
AetherLib.Config = {
    Theme = {
        Primary = Color3.fromRGB(138, 43, 226),
        Secondary = Color3.fromRGB(75, 0, 130),
        Accent = Color3.fromRGB(0, 255, 255),
        Background = Color3.fromRGB(15, 15, 25),
        Surface = Color3.fromRGB(25, 25, 40),
        Text = Color3.fromRGB(240, 240, 255),
        SubText = Color3.fromRGB(160, 160, 190),
        Success = Color3.fromRGB(0, 255, 150),
        Error = Color3.fromRGB(255, 50, 100),
        Warning = Color3.fromRGB(255, 180, 0),
    },
    Animation = {
        TweenTime = 0.35,
        EasingStyle = Enum.EasingStyle.Quart,
        EasingDirection = Enum.EasingDirection.Out,
    },
    Sounds = {
        Enabled = true,
        Click = "rbxassetid://6895079853",
        Hover = "rbxassetid://6895079853",
        Toggle = "rbxassetid://6895079853",
        Notify = "rbxassetid://6895079853",
    }
}

--// Utility Functions
local function Create(instanceType, properties)
    local success, instance = pcall(Instance.new, instanceType)
    if not success or not instance then
        warn("[AetherLib] Failed to create instance: " .. tostring(instanceType))
        return nil
    end
    for prop, value in pairs(properties or {}) do
        local ok, err = pcall(function()
            instance[prop] = value
        end)
        if not ok then
            warn("[AetherLib] Failed to set property " .. tostring(prop) .. ": " .. tostring(err))
        end
    end
    return instance
end

local function Tween(instance, properties, duration, easingStyle, easingDirection, callback)
    if not instance or typeof(instance) ~= "Instance" then
        warn("[AetherLib] Tween failed: invalid instance")
        return nil
    end
    if not properties or typeof(properties) ~= "table" then
        warn("[AetherLib] Tween failed: invalid properties")
        return nil
    end

    local tweenInfo = TweenInfo.new(
        duration or AetherLib.Config.Animation.TweenTime,
        easingStyle or AetherLib.Config.Animation.EasingStyle,
        easingDirection or AetherLib.Config.Animation.EasingDirection
    )

    local success, tween = pcall(function()
        return TweenService:Create(instance, tweenInfo, properties)
    end)

    if not success or not tween then
        warn("[AetherLib] TweenService:Create failed")
        return nil
    end

    if callback and typeof(callback) == "function" then
        local connSuccess, conn = pcall(function()
            return tween.Completed:Connect(callback)
        end)
        if not connSuccess then
            warn("[AetherLib] Failed to connect tween callback")
        end
    end

    tween:Play()
    return tween
end

local function PlaySound(soundId, volume)
    if not AetherLib.Config.Sounds.Enabled then return end
    local sound = Create("Sound", {
        SoundId = soundId,
        Volume = volume or 0.3,
        Parent = game:GetService("SoundService")
    })
    if sound then
        sound:Play()
        delay(1, function()
            if sound then sound:Destroy() end
        end)
    end
end

local function MakeDraggable(frame, handle)
    if not frame or not handle then return end
    local dragging = false
    local dragStart, startPos
    handle = handle or frame

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

--// Particle System
local function CreateParticles(parent)
    if not parent then return nil end
    local particleContainer = Create("Frame", {
        Name = "Particles",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = parent,
        ZIndex = 0,
    })
    if not particleContainer then return nil end

    for i = 1, 12 do
        local size = math.random(2, 5)
        local particle = Create("Frame", {
            Name = "Particle" .. i,
            Size = UDim2.new(0, size, 0, size),
            Position = UDim2.new(math.random() * 0.9, 0, math.random() * 0.9, 0),
            BackgroundColor3 = AetherLib.Config.Theme.Accent,
            BackgroundTransparency = math.random(4, 8) / 10,
            BorderSizePixel = 0,
            Parent = particleContainer,
            ZIndex = 0,
        })
        if particle then
            local corner = Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = particle})
            spawn(function()
                while particle and particle.Parent do
                    local newY = math.random(-40, 40)
                    local newX = math.random(-25, 25)
                    local newTrans = math.random(4, 9) / 10
                    Tween(particle, {
                        Position = UDim2.new(particle.Position.X.Scale, particle.Position.X.Offset + newX, particle.Position.Y.Scale, particle.Position.Y.Offset + newY),
                        BackgroundTransparency = newTrans,
                    }, math.random(3, 6), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                    wait(math.random(3, 6))
                end
            end)
        end
    end
    return particleContainer
end

--// Notification System
AetherLib.Notifications = {}
local NotificationQueue = {}
local NotificationActive = false

function AetherLib:Notify(data)
    data = data or {}
    local title = data.Title or "Aether"
    local message = data.Message or ""
    local duration = data.Duration or 4
    local notifyType = data.Type or "Info"
    local color = AetherLib.Config.Theme.Accent
    if notifyType == "Success" then color = AetherLib.Config.Theme.Success
    elseif notifyType == "Warning" then color = AetherLib.Config.Theme.Warning
    elseif notifyType == "Error" then color = AetherLib.Config.Theme.Error end
    table.insert(NotificationQueue, {title, message, duration, color})
    if not NotificationActive then
        self:ProcessNotificationQueue()
    end
end

function AetherLib:ProcessNotificationQueue()
    if #NotificationQueue == 0 then
        NotificationActive = false
        return
    end
    NotificationActive = true
    local data = table.remove(NotificationQueue, 1)
    local title, message, duration, color = data[1], data[2], data[3], data[4]
    PlaySound(AetherLib.Config.Sounds.Notify, 0.2)

    local gui = LocalPlayer:WaitForChild("PlayerGui")
    local screenGui = gui:FindFirstChild("AetherNotifications")
    if not screenGui then
        screenGui = Create("ScreenGui", {Name = "AetherNotifications", Parent = gui, ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})
    end
    if not screenGui then return end

    local notifFrame = Create("Frame", {
        Name = "Notification",
        Size = UDim2.new(0, 320, 0, 90),
        Position = UDim2.new(1, 20, 0.85, 0),
        BackgroundColor3 = AetherLib.Config.Theme.Surface,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Parent = screenGui,
    })
    if not notifFrame then NotificationActive = false; self:ProcessNotificationQueue(); return end

    Create("UICorner", {CornerRadius = UDim.new(0, 16), Parent = notifFrame})
    Create("UIStroke", {Color = color, Thickness = 1.5, Transparency = 0.5, Parent = notifFrame})
    Create("UIGradient", {
        Color = ColorSequence.new({ColorSequenceKeypoint.new(0, AetherLib.Config.Theme.Background), ColorSequenceKeypoint.new(1, AetherLib.Config.Theme.Surface)}),
        Rotation = 45, Parent = notifFrame,
    })
    local accentBar = Create("Frame", {Name = "AccentBar", Size = UDim2.new(0, 4, 0.7, 0), Position = UDim2.new(0, 12, 0.15, 0), BackgroundColor3 = color, BorderSizePixel = 0, Parent = notifFrame, ZIndex = 2})
    if accentBar then Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = accentBar}) end
    Create("TextLabel", {Name = "Title", Size = UDim2.new(0.75, 0, 0, 22), Position = UDim2.new(0, 28, 0, 10), BackgroundTransparency = 1, Text = title, TextColor3 = AetherLib.Config.Theme.Text, TextSize = 16, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = notifFrame, ZIndex = 2})
    Create("TextLabel", {Name = "Message", Size = UDim2.new(0.85, 0, 0, 40), Position = UDim2.new(0, 28, 0, 34), BackgroundTransparency = 1, Text = message, TextColor3 = AetherLib.Config.Theme.SubText, TextSize = 13, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = notifFrame, ZIndex = 2})
    local progressBar = Create("Frame", {Name = "Progress", Size = UDim2.new(1, 0, 0, 3), Position = UDim2.new(0, 0, 1, -3), BackgroundColor3 = color, BorderSizePixel = 0, Parent = notifFrame, ZIndex = 2})
    if progressBar then Create("UICorner", {CornerRadius = UDim.new(0, 2), Parent = progressBar}) end

    Tween(notifFrame, {Position = UDim2.new(1, -340, 0.85, 0)}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    if progressBar then
        Tween(progressBar, {Size = UDim2.new(0, 0, 0, 3)}, duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
    end

    delay(duration, function()
        Tween(notifFrame, {Position = UDim2.new(1, 20, 0.85, 0)}, 0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In, function()
            if notifFrame then notifFrame:Destroy() end
            self:ProcessNotificationQueue()
        end)
    end)
end

--// Main Window Creation
function AetherLib:CreateWindow(data)
    data = data or {}
    local windowName = data.Name or "AetherLib"
    local windowIcon = data.Icon or ""
    local windowSize = data.Size or UDim2.new(0, 600, 0, 400)
    PlaySound(AetherLib.Config.Sounds.Click, 0.15)

    local gui = LocalPlayer:WaitForChild("PlayerGui")
    local screenGui = Create("ScreenGui", {Name = "AetherLib_" .. HttpService:GenerateGUID(false), Parent = gui, ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})
    if not screenGui then return nil end

    local mainFrame = Create("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = AetherLib.Config.Theme.Background,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Parent = screenGui,
        ClipsDescendants = true,
    })
    if not mainFrame then screenGui:Destroy(); return nil end

    Create("UICorner", {CornerRadius = UDim.new(0, 20), Parent = mainFrame})
    Create("UIStroke", {Color = AetherLib.Config.Theme.Primary, Thickness = 1.2, Transparency = 0.4, Parent = mainFrame})
    Create("UIGradient", {
        Color = ColorSequence.new({ColorSequenceKeypoint.new(0, AetherLib.Config.Theme.Background), ColorSequenceKeypoint.new(0.5, AetherLib.Config.Theme.Surface), ColorSequenceKeypoint.new(1, AetherLib.Config.Theme.Background)}),
        Rotation = 135, Parent = mainFrame,
    })
    Create("ImageLabel", {Name = "Glow", Size = UDim2.new(1.5, 0, 1.5, 0), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Image = "rbxassetid://5028857084", ImageColor3 = AetherLib.Config.Theme.Primary, ImageTransparency = 0.85, Parent = mainFrame, ZIndex = 0})
    CreateParticles(mainFrame)

    local titleBar = Create("Frame", {Name = "TitleBar", Size = UDim2.new(1, 0, 0, 45), BackgroundColor3 = AetherLib.Config.Theme.Surface, BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = mainFrame, ZIndex = 2})
    if not titleBar then screenGui:Destroy(); return nil end
    Create("UICorner", {CornerRadius = UDim.new(0, 20), Parent = titleBar})
    Create("Frame", {Name = "Fix", Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = AetherLib.Config.Theme.Surface, BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = titleBar, ZIndex = 2})
    Create("ImageLabel", {Name = "Icon", Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(0, 15, 0, 10), BackgroundTransparency = 1, Image = windowIcon ~= "" and windowIcon or "rbxassetid://7733965386", ImageColor3 = AetherLib.Config.Theme.Accent, Parent = titleBar, ZIndex = 3})
    Create("TextLabel", {Name = "Title", Size = UDim2.new(0.4, 0, 0, 24), Position = UDim2.new(0, 48, 0, 10), BackgroundTransparency = 1, Text = windowName, TextColor3 = AetherLib.Config.Theme.Text, TextSize = 18, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = titleBar, ZIndex = 3})

    local closeBtn = Create("TextButton", {Name = "Close", Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -40, 0, 7), BackgroundColor3 = AetherLib.Config.Theme.Error, BackgroundTransparency = 0.8, Text = "×", TextColor3 = AetherLib.Config.Theme.Text, TextSize = 22, Font = Enum.Font.GothamBold, Parent = titleBar, ZIndex = 3})
    if closeBtn then
        Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = closeBtn})
        closeBtn.MouseEnter:Connect(function() Tween(closeBtn, {BackgroundTransparency = 0.3}, 0.2) end)
        closeBtn.MouseLeave:Connect(function() Tween(closeBtn, {BackgroundTransparency = 0.8}, 0.2) end)
        closeBtn.MouseButton1Click:Connect(function()
            PlaySound(AetherLib.Config.Sounds.Click, 0.2)
            Tween(mainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In, function() screenGui:Destroy() end)
        end)
    end

    local minimizeBtn = Create("TextButton", {Name = "Minimize", Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -75, 0, 7), BackgroundColor3 = AetherLib.Config.Theme.Warning, BackgroundTransparency = 0.8, Text = "−", TextColor3 = AetherLib.Config.Theme.Text, TextSize = 22, Font = Enum.Font.GothamBold, Parent = titleBar, ZIndex = 3})
    local minimized = false
    if minimizeBtn then
        Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = minimizeBtn})
        minimizeBtn.MouseEnter:Connect(function() Tween(minimizeBtn, {BackgroundTransparency = 0.3}, 0.2) end)
        minimizeBtn.MouseLeave:Connect(function() Tween(minimizeBtn, {BackgroundTransparency = 0.8}, 0.2) end)
        minimizeBtn.MouseButton1Click:Connect(function()
            PlaySound(AetherLib.Config.Sounds.Click, 0.2)
            minimized = not minimized
            if minimized then Tween(mainFrame, {Size = UDim2.new(0, windowSize.X.Offset, 0, 45)}, 0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            else Tween(mainFrame, {Size = windowSize}, 0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out) end
        end)
    end

    local tabContainer = Create("Frame", {Name = "TabContainer", Size = UDim2.new(0, 140, 1, -55), Position = UDim2.new(0, 10, 0, 50), BackgroundColor3 = AetherLib.Config.Theme.Surface, BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = mainFrame, ZIndex = 2})
    Create("UICorner", {CornerRadius = UDim.new(0, 14), Parent = tabContainer})
    local tabList = Create("ScrollingFrame", {Name = "TabList", Size = UDim2.new(1, -10, 1, -10), Position = UDim2.new(0, 5, 0, 5), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = AetherLib.Config.Theme.Primary, CanvasSize = UDim2.new(0, 0, 0, 0), Parent = tabContainer, ZIndex = 2})
    Create("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tabList})

    local contentContainer = Create("Frame", {Name = "ContentContainer", Size = UDim2.new(1, -165, 1, -55), Position = UDim2.new(0, 155, 0, 50), BackgroundColor3 = AetherLib.Config.Theme.Surface, BackgroundTransparency = 0.6, BorderSizePixel = 0, Parent = mainFrame, ZIndex = 2})
    Create("UICorner", {CornerRadius = UDim.new(0, 14), Parent = contentContainer})
    Create("UIStroke", {Color = AetherLib.Config.Theme.Primary, Thickness = 0.8, Transparency = 0.3, Parent = contentContainer})

    MakeDraggable(mainFrame, titleBar)
    Tween(mainFrame, {Size = windowSize}, 0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    local Window = {Tabs = {}, CurrentTab = nil}

    function Window:SelectTab(tabName)
        for name, tab in pairs(Window.Tabs) do
            if name == tabName then
                if tab.Content then
                    tab.Content.Visible = true
                    Tween(tab.Content, {BackgroundTransparency = 0.6}, 0.3)
                end
                if tab.Button then
                    Tween(tab.Button, {BackgroundTransparency = 0.2}, 0.2)
                end
                if tab.ButtonStroke then
                    tab.ButtonStroke.Enabled = true
                    Tween(tab.ButtonStroke, {Transparency = 0.3}, 0.2)
                end
                if tab.ButtonIcon then
                    Tween(tab.ButtonIcon, {ImageColor3 = AetherLib.Config.Theme.Accent}, 0.2)
                end
                if tab.ButtonText then
                    Tween(tab.ButtonText, {TextColor3 = AetherLib.Config.Theme.Accent}, 0.2)
                end
                Window.CurrentTab = tabName
            else
                if tab.Content then
                    tab.Content.Visible = false
                end
                if tab.Button then
                    Tween(tab.Button, {BackgroundTransparency = 0.7}, 0.2)
                end
                if tab.ButtonStroke then
                    tab.ButtonStroke.Enabled = false
                end
                if tab.ButtonIcon then
                    Tween(tab.ButtonIcon, {ImageColor3 = AetherLib.Config.Theme.SubText}, 0.2)
                end
                if tab.ButtonText then
                    Tween(tab.ButtonText, {TextColor3 = AetherLib.Config.Theme.SubText}, 0.2)
                end
            end
        end
    end

    function Window:CreateTab(tabData)
        tabData = tabData or {}
        local tabName = tabData.Name or "Tab"
        local tabIcon = tabData.Icon or ""

        local tabBtn = Create("TextButton", {Name = tabName .. "_Tab", Size = UDim2.new(1, -10, 0, 38), BackgroundColor3 = AetherLib.Config.Theme.Surface, BackgroundTransparency = 0.7, Text = "", Parent = tabList, ZIndex = 3})
        if not tabBtn then return nil end
        Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = tabBtn})
        local tabBtnStroke = Create("UIStroke", {Color = AetherLib.Config.Theme.Primary, Thickness = 1, Transparency = 0, Parent = tabBtn})
        if tabBtnStroke then tabBtnStroke.Enabled = false end
        local tabIconImg = Create("ImageLabel", {Name = "Icon", Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(0, 10, 0.5, -9), BackgroundTransparency = 1, Image = tabIcon ~= "" and tabIcon or "rbxassetid://7733965386", ImageColor3 = AetherLib.Config.Theme.SubText, Parent = tabBtn, ZIndex = 4})
        local tabText = Create("TextLabel", {Name = "Text", Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 34, 0, 0), BackgroundTransparency = 1, Text = tabName, TextColor3 = AetherLib.Config.Theme.SubText, TextSize = 14, Font = Enum.Font.GothamSemibold, TextXAlignment = Enum.TextXAlignment.Left, Parent = tabBtn, ZIndex = 4})

        local tabContent = Create("ScrollingFrame", {Name = tabName .. "_Content", Size = UDim2.new(1, -20, 1, -20), Position = UDim2.new(0, 10, 0, 10), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = AetherLib.Config.Theme.Primary, ScrollBarImageTransparency = 0.5, CanvasSize = UDim2.new(0, 0, 0, 0), Visible = false, Parent = contentContainer, ZIndex = 2})
        if not tabContent then return nil end
        local contentLayout = Create("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tabContent})
        contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tabContent.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 20)
        end)

        tabBtn.MouseButton1Click:Connect(function()
            PlaySound(AetherLib.Config.Sounds.Click, 0.15)
            Window:SelectTab(tabName)
        end)
        tabBtn.MouseEnter:Connect(function()
            if Window.CurrentTab ~= tabName then
                Tween(tabBtn, {BackgroundTransparency = 0.4}, 0.2)
                if tabIconImg then Tween(tabIconImg, {ImageColor3 = AetherLib.Config.Theme.Text}, 0.2) end
                if tabText then Tween(tabText, {TextColor3 = AetherLib.Config.Theme.Text}, 0.2) end
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if Window.CurrentTab ~= tabName then
                Tween(tabBtn, {BackgroundTransparency = 0.7}, 0.2)
                if tabIconImg then Tween(tabIconImg, {ImageColor3 = AetherLib.Config.Theme.SubText}, 0.2) end
                if tabText then Tween(tabText, {TextColor3 = AetherLib.Config.Theme.SubText}, 0.2) end
            end
        end)

        local Tab = {
            Name = tabName,
            Content = tabContent,
            Button = tabBtn,
            ButtonStroke = tabBtnStroke,
            ButtonIcon = tabIconImg,
            ButtonText = tabText,
        }

        function Tab:Select() Window:SelectTab(tabName) end

        function Tab:CreateButton(btnData)
            btnData = btnData or {}
            local btnText = btnData.Name or "Button"
            local btnCallback = btnData.Callback or function() end
            local btnDescription = btnData.Description or ""
            local btnFrame = Create("Frame", {Name = btnText .. "_Button", Size = UDim2.new(1, 0, 0, btnDescription ~= "" and 55 or 40), BackgroundColor3 = AetherLib.Config.Theme.Surface, BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = tabContent, ZIndex = 3})
            if not btnFrame then return nil end
            Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = btnFrame})
            local btnStroke = Create("UIStroke", {Color = AetherLib.Config.Theme.Primary, Thickness = 0.8, Transparency = 0.4, Parent = btnFrame})
            Create("TextLabel", {Name = "Label", Size = UDim2.new(0.7, 0, 0, 20), Position = UDim2.new(0, 12, 0, btnDescription ~= "" and 6 or 10), BackgroundTransparency = 1, Text = btnText, TextColor3 = AetherLib.Config.Theme.Text, TextSize = 14, Font = Enum.Font.GothamSemibold, TextXAlignment = Enum.TextXAlignment.Left, Parent = btnFrame, ZIndex = 4})
            if btnDescription ~= "" then
                Create("TextLabel", {Name = "Description", Size = UDim2.new(0.7, 0, 0, 16), Position = UDim2.new(0, 12, 0, 28), BackgroundTransparency = 1, Text = btnDescription, TextColor3 = AetherLib.Config.Theme.SubText, TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = btnFrame, ZIndex = 4})
            end
            local clickBtn = Create("TextButton", {Name = "ClickArea", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = btnFrame, ZIndex = 5})
            local actionIcon = Create("ImageLabel", {Name = "ActionIcon", Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -32, 0.5, -10), BackgroundTransparency = 1, Image = "rbxassetid://7733717447", ImageColor3 = AetherLib.Config.Theme.Accent, Parent = btnFrame, ZIndex = 4})
            if clickBtn then
                clickBtn.MouseEnter:Connect(function()
                    Tween(btnFrame, {BackgroundTransparency = 0.2}, 0.2)
                    if btnStroke then Tween(btnStroke, {Transparency = 0.1}, 0.2) end
                    if actionIcon then Tween(actionIcon, {ImageColor3 = AetherLib.Config.Theme.Text}, 0.2) end
                end)
                clickBtn.MouseLeave:Connect(function()
                    Tween(btnFrame, {BackgroundTransparency = 0.5}, 0.2)
                    if btnStroke then Tween(btnStroke, {Transparency = 0.4}, 0.2) end
                    if actionIcon then Tween(actionIcon, {ImageColor3 = AetherLib.Config.Theme.Accent}, 0.2) end
                end)
                clickBtn.MouseButton1Click:Connect(function()
                    PlaySound(AetherLib.Config.Sounds.Click, 0.15)
                    Tween(btnFrame, {Size = UDim2.new(0.98, 0, 0, btnDescription ~= "" and 55 or 40)}, 0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, function()
                        Tween(btnFrame, {Size = UDim2.new(1, 0, 0, btnDescription ~= "" and 55 or 40)}, 0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                    end)
                    btnCallback()
                end)
            end
            return btnFrame
        end

        function Tab:CreateToggle(toggleData)
            toggleData = toggleData or {}
            local toggleName = toggleData.Name or "Toggle"
            local toggleCallback = toggleData.Callback or function() end
            local defaultState = toggleData.Default or false
            local toggleDescription = toggleData.Description or ""
            local toggleFrame = Create("Frame", {Name = toggleName .. "_Toggle", Size = UDim2.new(1, 0, 0, toggleDescription ~= "" and 55 or 40), BackgroundColor3 = AetherLib.Config.Theme.Surface, BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = tabContent, ZIndex = 3})
            if not toggleFrame then return nil end
            Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = toggleFrame})
            local toggleStroke = Create("UIStroke", {Color = AetherLib.Config.Theme.Primary, Thickness = 0.8, Transparency = 0.4, Parent = toggleFrame})
            Create("TextLabel", {Name = "Label", Size = UDim2.new(0.6, 0, 0, 20), Position = UDim2.new(0, 12, 0, toggleDescription ~= "" and 6 or 10), BackgroundTransparency = 1, Text = toggleName, TextColor3 = AetherLib.Config.Theme.Text, TextSize = 14, Font = Enum.Font.GothamSemibold, TextXAlignment = Enum.TextXAlignment.Left, Parent = toggleFrame, ZIndex = 4})
            if toggleDescription ~= "" then
                Create("TextLabel", {Name = "Description", Size = UDim2.new(0.6, 0, 0, 16), Position = UDim2.new(0, 12, 0, 28), BackgroundTransparency = 1, Text = toggleDescription, TextColor3 = AetherLib.Config.Theme.SubText, TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = toggleFrame, ZIndex = 4})
            end
            local toggleBackground = Create("Frame", {Name = "Background", Size = UDim2.new(0, 44, 0, 24), Position = UDim2.new(1, -56, 0.5, -12), BackgroundColor3 = AetherLib.Config.Theme.Background, BorderSizePixel = 0, Parent = toggleFrame, ZIndex = 4})
            if not toggleBackground then return nil end
            Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = toggleBackground})
            local toggleStroke2 = Create("UIStroke", {Color = AetherLib.Config.Theme.SubText, Thickness = 1.5, Transparency = 0.5, Parent = toggleBackground})
            local toggleCircle = Create("Frame", {Name = "Circle", Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(0, 3, 0.5, -9), BackgroundColor3 = AetherLib.Config.Theme.Text, BorderSizePixel = 0, Parent = toggleBackground, ZIndex = 5})
            if toggleCircle then Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = toggleCircle}) end
            local toggleBtn = Create("TextButton", {Name = "ClickArea", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = toggleFrame, ZIndex = 6})
            local state = defaultState
            local function UpdateToggle()
                if state then
                    Tween(toggleBackground, {BackgroundColor3 = AetherLib.Config.Theme.Success}, 0.25)
                    if toggleCircle then Tween(toggleCircle, {Position = UDim2.new(1, -21, 0.5, -9)}, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out) end
                    if toggleStroke2 then Tween(toggleStroke2, {Color = AetherLib.Config.Theme.Success, Transparency = 0.2}, 0.25) end
                else
                    Tween(toggleBackground, {BackgroundColor3 = AetherLib.Config.Theme.Background}, 0.25)
                    if toggleCircle then Tween(toggleCircle, {Position = UDim2.new(0, 3, 0.5, -9)}, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out) end
                    if toggleStroke2 then Tween(toggleStroke2, {Color = AetherLib.Config.Theme.SubText, Transparency = 0.5}, 0.25) end
                end
            end
            if state then UpdateToggle() end
            if toggleBtn then
                toggleBtn.MouseButton1Click:Connect(function()
                    PlaySound(AetherLib.Config.Sounds.Toggle, 0.12)
                    state = not state
                    UpdateToggle()
                    toggleCallback(state)
                end)
                toggleBtn.MouseEnter:Connect(function()
                    Tween(toggleFrame, {BackgroundTransparency = 0.2}, 0.2)
                    if toggleStroke then Tween(toggleStroke, {Transparency = 0.1}, 0.2) end
                end)
                toggleBtn.MouseLeave:Connect(function()
                    Tween(toggleFrame, {BackgroundTransparency = 0.5}, 0.2)
                    if toggleStroke then Tween(toggleStroke, {Transparency = 0.4}, 0.2) end
                end)
            end
            local ToggleObj = {}
            function ToggleObj:Set(val) state = val; UpdateToggle(); toggleCallback(state) end
            function ToggleObj:Get() return state end
            return ToggleObj
        end

        function Tab:CreateSlider(sliderData)
            sliderData = sliderData or {}
            local sliderName = sliderData.Name or "Slider"
            local min = sliderData.Min or 0
            local max = sliderData.Max or 100
            local default = sliderData.Default or min
            local increment = sliderData.Increment or 1
            local suffix = sliderData.Suffix or ""
            local callback = sliderData.Callback or function() end
            local sliderFrame = Create("Frame", {Name = sliderName .. "_Slider", Size = UDim2.new(1, 0, 0, 65), BackgroundColor3 = AetherLib.Config.Theme.Surface, BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = tabContent, ZIndex = 3})
            if not sliderFrame then return nil end
            Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = sliderFrame})
            local sliderStroke = Create("UIStroke", {Color = AetherLib.Config.Theme.Primary, Thickness = 0.8, Transparency = 0.4, Parent = sliderFrame})
            Create("TextLabel", {Name = "Label", Size = UDim2.new(0.5, 0, 0, 20), Position = UDim2.new(0, 12, 0, 8), BackgroundTransparency = 1, Text = sliderName, TextColor3 = AetherLib.Config.Theme.Text, TextSize = 14, Font = Enum.Font.GothamSemibold, TextXAlignment = Enum.TextXAlignment.Left, Parent = sliderFrame, ZIndex = 4})
            local valueLabel = Create("TextLabel", {Name = "Value", Size = UDim2.new(0.3, 0, 0, 20), Position = UDim2.new(1, -80, 0, 8), BackgroundTransparency = 1, Text = tostring(default) .. suffix, TextColor3 = AetherLib.Config.Theme.Accent, TextSize = 14, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right, Parent = sliderFrame, ZIndex = 4})
            local sliderBarBg = Create("Frame", {Name = "BarBackground", Size = UDim2.new(1, -24, 0, 8), Position = UDim2.new(0, 12, 0, 38), BackgroundColor3 = AetherLib.Config.Theme.Background, BorderSizePixel = 0, Parent = sliderFrame, ZIndex = 4})
            if not sliderBarBg then return nil end
            Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = sliderBarBg})
            local sliderBarFill = Create("Frame", {Name = "BarFill", Size = UDim2.new((default - min) / (max - min), 0, 1, 0), BackgroundColor3 = AetherLib.Config.Theme.Accent, BorderSizePixel = 0, Parent = sliderBarBg, ZIndex = 5})
            if sliderBarFill then Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = sliderBarFill}) end
            local sliderKnob = Create("Frame", {Name = "Knob", Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new((default - min) / (max - min), -9, 0.5, -9), BackgroundColor3 = AetherLib.Config.Theme.Text, BorderSizePixel = 0, Parent = sliderBarBg, ZIndex = 6})
            if sliderKnob then
                Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = sliderKnob})
                Create("UIStroke", {Color = AetherLib.Config.Theme.Accent, Thickness = 2, Transparency = 0.5, Parent = sliderKnob})
            end
            local dragging = false
            local function UpdateSlider(input)
                local pos = math.clamp((input.Position.X - sliderBarBg.AbsolutePosition.X) / sliderBarBg.AbsoluteSize.X, 0, 1)
                local val = math.floor((min + (max - min) * pos) / increment + 0.5) * increment
                val = math.clamp(val, min, max)
                local scale = (val - min) / (max - min)
                if sliderBarFill then sliderBarFill.Size = UDim2.new(scale, 0, 1, 0) end
                if sliderKnob then sliderKnob.Position = UDim2.new(scale, -9, 0.5, -9) end
                if valueLabel then valueLabel.Text = tostring(val) .. suffix end
                callback(val)
                return val
            end
            sliderBarBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    UpdateSlider(input)
                    if sliderKnob then Tween(sliderKnob, {Size = UDim2.new(0, 22, 0, 22)}, 0.15) end
                end
            end)
            if sliderKnob then
                sliderKnob.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        Tween(sliderKnob, {Size = UDim2.new(0, 22, 0, 22)}, 0.15)
                    end
                end)
            end
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    UpdateSlider(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                    if sliderKnob then Tween(sliderKnob, {Size = UDim2.new(0, 18, 0, 18)}, 0.15) end
                end
            end)
            sliderBarBg.MouseEnter:Connect(function()
                Tween(sliderFrame, {BackgroundTransparency = 0.2}, 0.2)
                if sliderStroke then Tween(sliderStroke, {Transparency = 0.1}, 0.2) end
            end)
            sliderBarBg.MouseLeave:Connect(function()
                if not dragging then
                    Tween(sliderFrame, {BackgroundTransparency = 0.5}, 0.2)
                    if sliderStroke then Tween(sliderStroke, {Transparency = 0.4}, 0.2) end
                end
            end)
            local SliderObj = {}
            function SliderObj:Set(val)
                val = math.clamp(math.floor(val / increment + 0.5) * increment, min, max)
                local scale = (val - min) / (max - min)
                if sliderBarFill then sliderBarFill.Size = UDim2.new(scale, 0, 1, 0) end
                if sliderKnob then sliderKnob.Position = UDim2.new(scale, -9, 0.5, -9) end
                if valueLabel then valueLabel.Text = tostring(val) .. suffix end
                callback(val)
            end
            function SliderObj:Get() return tonumber(valueLabel.Text:gsub(suffix, "")) end
            return SliderObj
        end

        function Tab:CreateDropdown(dropData)
            dropData = dropData or {}
            local dropName = dropData.Name or "Dropdown"
            local options = dropData.Options or {}
            local default = dropData.Default or ""
            local callback = dropData.Callback or function() end
            local dropFrame = Create("Frame", {Name = dropName .. "_Dropdown", Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = AetherLib.Config.Theme.Surface, BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = tabContent, ClipsDescendants = true, ZIndex = 5})
            if not dropFrame then return nil end
            Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = dropFrame})
            local dropStroke = Create("UIStroke", {Color = AetherLib.Config.Theme.Primary, Thickness = 0.8, Transparency = 0.4, Parent = dropFrame})
            Create("TextLabel", {Name = "Label", Size = UDim2.new(0.5, 0, 0, 20), Position = UDim2.new(0, 12, 0, 11), BackgroundTransparency = 1, Text = dropName, TextColor3 = AetherLib.Config.Theme.Text, TextSize = 14, Font = Enum.Font.GothamSemibold, TextXAlignment = Enum.TextXAlignment.Left, Parent = dropFrame, ZIndex = 6})
            local selectedLabel = Create("TextLabel", {Name = "Selected", Size = UDim2.new(0.4, 0, 0, 20), Position = UDim2.new(0.5, 0, 0, 11), BackgroundTransparency = 1, Text = default ~= "" and default or "Select...", TextColor3 = AetherLib.Config.Theme.Accent, TextSize = 13, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Right, Parent = dropFrame, ZIndex = 6})
            local arrowIcon = Create("ImageLabel", {Name = "Arrow", Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -28, 0, 13), BackgroundTransparency = 1, Image = "rbxassetid://7733717447", ImageColor3 = AetherLib.Config.Theme.SubText, Rotation = 90, Parent = dropFrame, ZIndex = 6})
            local dropBtn = Create("TextButton", {Name = "ClickArea", Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, Text = "", Parent = dropFrame, ZIndex = 7})
            local optionsFrame = Create("Frame", {Name = "Options", Size = UDim2.new(1, -16, 0, 0), Position = UDim2.new(0, 8, 0, 46), BackgroundColor3 = AetherLib.Config.Theme.Background, BackgroundTransparency = 0.1, BorderSizePixel = 0, Visible = false, Parent = dropFrame, ZIndex = 8})
            if optionsFrame then
                Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = optionsFrame})
                Create("UIStroke", {Color = AetherLib.Config.Theme.Primary, Thickness = 1, Transparency = 0.3, Parent = optionsFrame})
                Create("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = optionsFrame})
            end
            local open = false
            local function BuildOptions()
                if not optionsFrame then return end
                for _, child in pairs(optionsFrame:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                for _, option in ipairs(options) do
                    local optBtn = Create("TextButton", {Name = option, Size = UDim2.new(1, -8, 0, 32), Position = UDim2.new(0, 4, 0, 0), BackgroundColor3 = AetherLib.Config.Theme.Surface, BackgroundTransparency = 0.6, Text = option, TextColor3 = AetherLib.Config.Theme.Text, TextSize = 13, Font = Enum.Font.Gotham, Parent = optionsFrame, ZIndex = 9})
                    if optBtn then
                        Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = optBtn})
                        optBtn.MouseEnter:Connect(function() Tween(optBtn, {BackgroundTransparency = 0.2, TextColor3 = AetherLib.Config.Theme.Accent}, 0.15) end)
                        optBtn.MouseLeave:Connect(function() Tween(optBtn, {BackgroundTransparency = 0.6, TextColor3 = AetherLib.Config.Theme.Text}, 0.15) end)
                        optBtn.MouseButton1Click:Connect(function()
                            PlaySound(AetherLib.Config.Sounds.Click, 0.12)
                            if selectedLabel then selectedLabel.Text = option end
                            callback(option)
                            open = false
                            Tween(dropFrame, {Size = UDim2.new(1, 0, 0, 42)}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                            if arrowIcon then Tween(arrowIcon, {Rotation = 90}, 0.3) end
                            optionsFrame.Visible = false
                        end)
                    end
                end
                local totalHeight = #options * 36 + 8
                optionsFrame.Size = UDim2.new(1, -16, 0, math.min(totalHeight, 180))
            end
            BuildOptions()
            if dropBtn then
                dropBtn.MouseButton1Click:Connect(function()
                    PlaySound(AetherLib.Config.Sounds.Click, 0.12)
                    open = not open
                    if open then
                        if optionsFrame then optionsFrame.Visible = true end
                        Tween(dropFrame, {Size = UDim2.new(1, 0, 0, math.min(46 + (optionsFrame and optionsFrame.Size.Y.Offset or 0) + 8, 240))}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                        if arrowIcon then Tween(arrowIcon, {Rotation = -90}, 0.3) end
                    else
                        Tween(dropFrame, {Size = UDim2.new(1, 0, 0, 42)}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                        if arrowIcon then Tween(arrowIcon, {Rotation = 90}, 0.3) end
                        delay(0.3, function() if optionsFrame then optionsFrame.Visible = false end end)
                    end
                end)
                dropBtn.MouseEnter:Connect(function()
                    Tween(dropFrame, {BackgroundTransparency = 0.2}, 0.2)
                    if dropStroke then Tween(dropStroke, {Transparency = 0.1}, 0.2) end
                end)
                dropBtn.MouseLeave:Connect(function()
                    Tween(dropFrame, {BackgroundTransparency = 0.5}, 0.2)
                    if dropStroke then Tween(dropStroke, {Transparency = 0.4}, 0.2) end
                end)
            end
            local DropObj = {}
            function DropObj:Set(val)
                if table.find(options, val) then
                    if selectedLabel then selectedLabel.Text = val end
                    callback(val)
                end
            end
            function DropObj:Refresh(newOptions)
                options = newOptions
                BuildOptions()
            end
            function DropObj:Get() return selectedLabel and selectedLabel.Text or "" end
            return DropObj
        end

        function Tab:CreateInput(inputData)
            inputData = inputData or {}
            local inputName = inputData.Name or "Input"
            local default = inputData.Default or ""
            local placeholder = inputData.Placeholder or "Type here..."
            local callback = inputData.Callback or function() end
            local inputFrame = Create("Frame", {Name = inputName .. "_Input", Size = UDim2.new(1, 0, 0, 70), BackgroundColor3 = AetherLib.Config.Theme.Surface, BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = tabContent, ZIndex = 3})
            if not inputFrame then return nil end
            Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = inputFrame})
            local inputStroke = Create("UIStroke", {Color = AetherLib.Config.Theme.Primary, Thickness = 0.8, Transparency = 0.4, Parent = inputFrame})
            Create("TextLabel", {Name = "Label", Size = UDim2.new(0.9, 0, 0, 20), Position = UDim2.new(0, 12, 0, 8), BackgroundTransparency = 1, Text = inputName, TextColor3 = AetherLib.Config.Theme.Text, TextSize = 14, Font = Enum.Font.GothamSemibold, TextXAlignment = Enum.TextXAlignment.Left, Parent = inputFrame, ZIndex = 4})
            local textBox = Create("TextBox", {Name = "TextBox", Size = UDim2.new(1, -24, 0, 30), Position = UDim2.new(0, 12, 0, 34), BackgroundColor3 = AetherLib.Config.Theme.Background, BackgroundTransparency = 0.3, Text = default, PlaceholderText = placeholder, TextColor3 = AetherLib.Config.Theme.Text, PlaceholderColor3 = AetherLib.Config.Theme.SubText, TextSize = 13, Font = Enum.Font.Gotham, ClearTextOnFocus = false, Parent = inputFrame, ZIndex = 4})
            if not textBox then return nil end
            Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = textBox})
            local textBoxStroke = Create("UIStroke", {Color = AetherLib.Config.Theme.Primary, Thickness = 1, Transparency = 0.6, Parent = textBox})
            textBox.Focused:Connect(function()
                PlaySound(AetherLib.Config.Sounds.Hover, 0.08)
                if textBoxStroke then Tween(textBoxStroke, {Transparency = 0.1, Color = AetherLib.Config.Theme.Accent}, 0.2) end
                Tween(textBox, {BackgroundTransparency = 0.1}, 0.2)
            end)
            textBox.FocusLost:Connect(function()
                if textBoxStroke then Tween(textBoxStroke, {Transparency = 0.6, Color = AetherLib.Config.Theme.Primary}, 0.2) end
                Tween(textBox, {BackgroundTransparency = 0.3}, 0.2)
                callback(textBox.Text)
            end)
            textBox:GetPropertyChangedSignal("Text"):Connect(function() callback(textBox.Text) end)
            local InputObj = {}
            function InputObj:Set(text) textBox.Text = text end
            function InputObj:Get() return textBox.Text end
            return InputObj
        end

        function Tab:CreateLabel(labelData)
            labelData = labelData or {}
            local labelText = labelData.Text or "Label"
            local labelColor = labelData.Color or AetherLib.Config.Theme.Text
            local labelFrame = Create("Frame", {Name = "Label", Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = tabContent, ZIndex = 3})
            if not labelFrame then return nil end
            local textLabel = Create("TextLabel", {Name = "Text", Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 1, Text = labelText, TextColor3 = labelColor, TextSize = 13, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = labelFrame, ZIndex = 4})
            local LabelObj = {}
            function LabelObj:Set(text) if textLabel then textLabel.Text = text end end
            function LabelObj:SetColor(color) if textLabel then textLabel.TextColor3 = color end end
            return LabelObj
        end

        function Tab:CreateKeybind(bindData)
            bindData = bindData or {}
            local bindName = bindData.Name or "Keybind"
            local defaultKey = bindData.Default or "None"
            local callback = bindData.Callback or function() end
            local bindFrame = Create("Frame", {Name = bindName .. "_Keybind", Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = AetherLib.Config.Theme.Surface, BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = tabContent, ZIndex = 3})
            if not bindFrame then return nil end
            Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = bindFrame})
            local bindStroke = Create("UIStroke", {Color = AetherLib.Config.Theme.Primary, Thickness = 0.8, Transparency = 0.4, Parent = bindFrame})
            Create("TextLabel", {Name = "Label", Size = UDim2.new(0.6, 0, 0, 20), Position = UDim2.new(0, 12, 0, 10), BackgroundTransparency = 1, Text = bindName, TextColor3 = AetherLib.Config.Theme.Text, TextSize = 14, Font = Enum.Font.GothamSemibold, TextXAlignment = Enum.TextXAlignment.Left, Parent = bindFrame, ZIndex = 4})
            local keyBtn = Create("TextButton", {Name = "KeyButton", Size = UDim2.new(0, 70, 0, 26), Position = UDim2.new(1, -82, 0.5, -13), BackgroundColor3 = AetherLib.Config.Theme.Background, BackgroundTransparency = 0.3, Text = defaultKey, TextColor3 = AetherLib.Config.Theme.Accent, TextSize = 12, Font = Enum.Font.GothamBold, Parent = bindFrame, ZIndex = 4})
            if not keyBtn then return nil end
            Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = keyBtn})
            local keyStroke = Create("UIStroke", {Color = AetherLib.Config.Theme.Primary, Thickness = 1, Transparency = 0.5, Parent = keyBtn})
            local listening = false
            local currentKey = defaultKey
            keyBtn.MouseButton1Click:Connect(function()
                PlaySound(AetherLib.Config.Sounds.Click, 0.12)
                listening = true
                keyBtn.Text = "..."
                Tween(keyBtn, {BackgroundColor3 = AetherLib.Config.Theme.Primary}, 0.2)
            end)
            UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if listening and not gameProcessed then
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        listening = false
                        currentKey = input.KeyCode.Name
                        keyBtn.Text = currentKey
                        Tween(keyBtn, {BackgroundColor3 = AetherLib.Config.Theme.Background}, 0.2)
                        callback(currentKey)
                    end
                elseif input.KeyCode.Name == currentKey and not gameProcessed then
                    callback(currentKey)
                end
            end)
            keyBtn.MouseEnter:Connect(function()
                Tween(bindFrame, {BackgroundTransparency = 0.2}, 0.2)
                if bindStroke then Tween(bindStroke, {Transparency = 0.1}, 0.2) end
            end)
            keyBtn.MouseLeave:Connect(function()
                Tween(bindFrame, {BackgroundTransparency = 0.5}, 0.2)
                if bindStroke then Tween(bindStroke, {Transparency = 0.4}, 0.2) end
            end)
            local BindObj = {}
            function BindObj:Set(key) currentKey = key; keyBtn.Text = key; callback(key) end
            function BindObj:Get() return currentKey end
            return BindObj
        end

        function Tab:CreateColorPicker(pickerData)
            pickerData = pickerData or {}
            local pickerName = pickerData.Name or "Color Picker"
            local defaultColor = pickerData.Default or Color3.fromRGB(138, 43, 226)
            local callback = pickerData.Callback or function() end
            local pickerFrame = Create("Frame", {Name = pickerName .. "_ColorPicker", Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = AetherLib.Config.Theme.Surface, BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = tabContent, ZIndex = 3})
            if not pickerFrame then return nil end
            Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = pickerFrame})
            local pickerStroke = Create("UIStroke", {Color = AetherLib.Config.Theme.Primary, Thickness = 0.8, Transparency = 0.4, Parent = pickerFrame})
            Create("TextLabel", {Name = "Label", Size = UDim2.new(0.6, 0, 0, 20), Position = UDim2.new(0, 12, 0, 10), BackgroundTransparency = 1, Text = pickerName, TextColor3 = AetherLib.Config.Theme.Text, TextSize = 14, Font = Enum.Font.GothamSemibold, TextXAlignment = Enum.TextXAlignment.Left, Parent = pickerFrame, ZIndex = 4})
            local colorPreview = Create("Frame", {Name = "Preview", Size = UDim2.new(0, 50, 0, 26), Position = UDim2.new(1, -62, 0.5, -13), BackgroundColor3 = defaultColor, BorderSizePixel = 0, Parent = pickerFrame, ZIndex = 4})
            if colorPreview then
                Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = colorPreview})
                Create("UIStroke", {Color = AetherLib.Config.Theme.Text, Thickness = 1.5, Transparency = 0.3, Parent = colorPreview})
            end
            local pickerBtn = Create("TextButton", {Name = "ClickArea", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = pickerFrame, ZIndex = 5})
            local currentColor = defaultColor
            if pickerBtn then
                pickerBtn.MouseButton1Click:Connect(function()
                    PlaySound(AetherLib.Config.Sounds.Click, 0.12)
                    local r = math.clamp(math.floor(currentColor.R * 255) + math.random(-30, 30), 0, 255)
                    local g = math.clamp(math.floor(currentColor.G * 255) + math.random(-30, 30), 0, 255)
                    local b = math.clamp(math.floor(currentColor.B * 255) + math.random(-30, 30), 0, 255)
                    currentColor = Color3.fromRGB(r, g, b)
                    if colorPreview then Tween(colorPreview, {BackgroundColor3 = currentColor}, 0.3) end
                    callback(currentColor)
                end)
                pickerBtn.MouseEnter:Connect(function()
                    Tween(pickerFrame, {BackgroundTransparency = 0.2}, 0.2)
                    if pickerStroke then Tween(pickerStroke, {Transparency = 0.1}, 0.2) end
                end)
                pickerBtn.MouseLeave:Connect(function()
                    Tween(pickerFrame, {BackgroundTransparency = 0.5}, 0.2)
                    if pickerStroke then Tween(pickerStroke, {Transparency = 0.4}, 0.2) end
                end)
            end
            local PickerObj = {}
            function PickerObj:Set(color) currentColor = color; if colorPreview then Tween(colorPreview, {BackgroundColor3 = color}, 0.3) end; callback(color) end
            function PickerObj:Get() return currentColor end
            return PickerObj
        end

        function Tab:CreateSection(sectionData)
            sectionData = sectionData or {}
            local sectionText = sectionData.Text or "Section"
            local sectionFrame = Create("Frame", {Name = sectionText .. "_Section", Size = UDim2.new(1, 0, 0, 35), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = tabContent, ZIndex = 3})
            if not sectionFrame then return nil end
            Create("TextLabel", {Name = "Label", Size = UDim2.new(1, -16, 0, 20), Position = UDim2.new(0, 8, 0, 8), BackgroundTransparency = 1, Text = sectionText, TextColor3 = AetherLib.Config.Theme.Accent, TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = sectionFrame, ZIndex = 4})
            local underline = Create("Frame", {Name = "Underline", Size = UDim2.new(0.3, 0, 0, 2), Position = UDim2.new(0, 8, 0, 28), BackgroundColor3 = AetherLib.Config.Theme.Accent, BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = sectionFrame, ZIndex = 4})
            if underline then Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = underline}) end
            return sectionFrame
        end

        Window.Tabs[tabName] = Tab
        if not Window.CurrentTab then
            Window:SelectTab(tabName)
        end
        return Tab
    end
    return Window
end

--// Example Usage (commented out)
--[[
local Window = AetherLib:CreateWindow({
    Name = "Aether Hub",
    Icon = "rbxassetid://7733965386",
    Size = UDim2.new(0, 600, 0, 400)
})

local MainTab = Window:CreateTab({Name = "Main", Icon = "rbxassetid://7733965386"})
local SettingsTab = Window:CreateTab({Name = "Settings", Icon = "rbxassetid://7734053495"})

MainTab:CreateSection({Text = "General"})
MainTab:CreateButton({
    Name = "Execute",
    Description = "Click to run",
    Callback = function()
        AetherLib:Notify({Title = "Success", Message = "Button clicked!", Type = "Success"})
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
    Name = "Speed",
    Min = 0,
    Max = 100,
    Default = 50,
    Suffix = "%",
    Callback = function(val)
        print("Speed:", val)
    end
})

MainTab:CreateDropdown({
    Name = "Select Mode",
    Options = {"Easy", "Medium", "Hard"},
    Default = "Easy",
    Callback = function(val)
        print("Mode:", val)
    end
})

MainTab:CreateInput({
    Name = "Username",
    Placeholder = "Enter username...",
    Callback = function(text)
        print("Input:", text)
    end
})

MainTab:CreateKeybind({
    Name = "Toggle UI",
    Default = "RightShift",
    Callback = function(key)
        print("Key pressed:", key)
    end
})

MainTab:CreateColorPicker({
    Name = "Theme Color",
    Default = Color3.fromRGB(138, 43, 226),
    Callback = function(color)
        print("Color:", color)
    end
})
--]]

return AetherLib
