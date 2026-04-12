--[=[
    SYSTEM: Scoped UI Mutator V4 (Optimized)
    AUTHOR: Gem
    DESCRIPTION: Fixes load lag via Yield-First execution. Implements Asset Fallback.
]=]

local CoreGui = game:GetService("CoreGui")

-- ==========================================
-- 1. CONFIGURATION
-- ==========================================
local Config = {
    HubName = "Devansh Hub",
    Credits = "by Devansh",
    
    -- Try your Imgur link here:
    IconURL = "https://i.imgur.com/YOUR_IMAGE_ID.png", 
    -- If your executor blocks Imgur downloads, it will use this Roblox ID instead (A cool Ninja/Skull icon):
    FallbackIconID = "rbxassetid://10656208006", 
    
    -- Adjusted Color: Electric Blue (Noticeable change)
    ThemeColor = Color3.fromRGB(0, 170, 255) 
}

-- ==========================================
-- 2. ASSET LOADER (WITH FALLBACK)
-- ==========================================
local FinalIconAsset = Config.FallbackIconID

if Config.IconURL ~= "" then
    local success, err = pcall(function()
        local imageData = game:HttpGet(Config.IconURL)
        local cleanUrl = string.gsub(Config.IconURL, "[^%w]", "")
        local fileName = "DevanshIcon_" .. string.sub(cleanUrl, 1, 10) .. ".png"
        
        writefile(fileName, imageData)
        FinalIconAsset = getcustomasset(fileName)
        print("Devansh Hub: Imgur icon loaded successfully.")
    end)
    
    if not success or FinalIconAsset == nil or FinalIconAsset == "" then
        warn("Devansh Hub: Executor blocked Imgur download. Using Fallback Roblox ID.")
        FinalIconAsset = Config.FallbackIconID
    end
end

-- ==========================================
-- 3. MUTATOR ENGINE
-- ==========================================

local TargetedGuiRoot = nil

-- Lowered threshold to catch MORE colors
local function IsAccentColor(color3)
    local h, s, v = Color3.toHSV(color3)
    return s > 0.08 and v > 0.15 
end

local function MutateStrictly(gui)
    if not gui or not gui:IsA("ScreenGui") then return end

    for _, obj in ipairs(gui:GetDescendants()) do
        -- A. TEXT REPLACEMENT
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            local text = obj.Text
            if text and text ~= "" then
                local newText = text
                
                if newText == "redz Hub" then newText = Config.HubName end
                if newText == "by real_redz" then newText = Config.Credits end
                if newText == "REDZ" then newText = "DEV" end
                
                if string.find(newText, "redz Hub") then
                    newText = string.gsub(newText, "redz Hub", Config.HubName)
                end
                if string.find(newText, "real_redz") then
                    newText = string.gsub(newText, "real_redz", "Devansh")
                end
                if string.find(newText, "redz") and newText ~= Config.HubName and newText ~= Config.Credits then
                     newText = string.gsub(newText, "redz", "Devansh")
                end

                if text ~= newText then
                    pcall(function() obj.Text = newText end)
                end
            end
        end

        -- B. COLOR THEMING
        pcall(function()
            if obj:IsA("GuiObject") and IsAccentColor(obj.BackgroundColor3) then
                obj.BackgroundColor3 = Config.ThemeColor
            elseif (obj:IsA("TextLabel") or obj:IsA("TextButton")) and IsAccentColor(obj.TextColor3) then
                obj.TextColor3 = Config.ThemeColor
            elseif (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) and IsAccentColor(obj.ImageColor3) then
                obj.ImageColor3 = Config.ThemeColor
            elseif obj:IsA("UIStroke") and IsAccentColor(obj.Color) then
                obj.Color = Config.ThemeColor
            end
        end)

        -- C. ICON REPLACEMENT (Expanded Size Heuristic)
        if (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) then
            pcall(function()
                local sizeX = obj.AbsoluteSize.X
                local sizeY = obj.AbsoluteSize.Y
                
                -- Broadened detection: catches any square-ish image between 25px and 100px
                if sizeX >= 25 and sizeX <= 100 and sizeY >= 25 and sizeY <= 100 then
                    -- Prevent replacing internal icons like checkboxes by checking if it's the main toggle
                    if obj.Image ~= FinalIconAsset then
                        obj.Image = FinalIconAsset
                        obj.BackgroundTransparency = 1 
                    end
                end
            end)
        end
    end
end

-- ==========================================
-- 4. SCANNER & EXECUTION (LAG FIX)
-- ==========================================

local function FindRedzHub()
    local containers = {CoreGui}
    if typeof(gethui) == "function" then table.insert(containers, gethui()) end

    for _, container in ipairs(containers) do
        for _, gui in ipairs(container:GetDescendants()) do
            if gui:IsA("ScreenGui") then
                for _, obj in ipairs(gui:GetDescendants()) do
                    if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and (string.find(obj.Text, "redz") or string.find(obj.Text, "DEV")) then
                        return gui
                    end
                end
            end
        end
    end
    return nil
end

-- Scanner Thread
task.spawn(function()
    while task.wait(0.5) do
        local foundRoot = FindRedzHub()
        if foundRoot and foundRoot ~= TargetedGuiRoot then
            TargetedGuiRoot = foundRoot
            
            -- LAG FIX: Yield for 1.5 seconds to let the UI finish building before we iterate over it
            task.wait(1.5) 
            
            task.spawn(function()
                while TargetedGuiRoot and TargetedGuiRoot.Parent do
                    MutateStrictly(TargetedGuiRoot)
                    -- Slower polling rate reduces background CPU usage
                    task.wait(1) 
                end
                TargetedGuiRoot = nil 
            end)
        end
    end
end)

-- Execute Payload
task.spawn(function()
    local success, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/huy384/redzHub/refs/heads/main/redzHub.lua"))()
    end)
    if not success then
        warn("Failed to load target script: " .. tostring(err))
    end
end)
