-- Configuration
getgenv().key = Enum.KeyCode.Q
getgenv().prediction = 1.75
getgenv().smoothing = 0.9 

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService") 

local player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local DataFolder = player:WaitForChild("DataFolder", 60)
local Information = DataFolder:WaitForChild("Information", 10)
local CrewValue = Information:FindFirstChild("Crew")
local Crew = CrewValue and tonumber(CrewValue.Value) or 0

local HB = RunService.Heartbeat

local AimlockEnabled = true

local function getTorso(character)
    return character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso")
end

local function validCharacter(character)
    if character.PrimaryPart and character:FindFirstChild("Head") and character:FindFirstChildOfClass("Humanoid") and getTorso(character) then
        return true
    else
        return false
    end
end

local function mobileCharacter(char)
    local character = char or player.Character

    if validCharacter(character) then
        local root = character.PrimaryPart
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local torso = getTorso(character)

        local motor = torso:FindFirstChildOfClass("Motor6D")

        if humanoid.Health > 0 and motor then
            return character
        end
    end

    return false
end

local function resetCharacter(shouldYield)
    if shouldYield == nil then
        shouldYield = true
    end

    local character = mobileCharacter()

    if character then
        local start = os.clock()

        local humanoid = character:FindFirstChildOfClass("Humanoid")

        humanoid.Health = 0

        local shouldReturn = false

        local addedEvent

        local g = Instance.new("BindableEvent")

        addedEvent = player.CharacterAdded:Connect(function()
            local g = Instance.new("BindableEvent")
            local w = nil
            w = HB:Connect(function()
                if addedEvent then
                    g:Fire()
                    w:Disconnect()
                end
            end)
            g.Event:Wait()
            g:Destroy()

            addedEvent:Disconnect()
            shouldReturn = true
        end)

        local g = Instance.new("BindableEvent")

        local d = nil
        d = HB:Connect(function()
            if shouldReturn then
                g:Fire()
                d:Disconnect()
            end
        end)

        g.Event:Wait()

        g:Destroy()
    end
end

local function tp(goal, shouldYield)
    local char = mobileCharacter()

    if not char and shouldYield then
        local b = Instance.new("BindableEvent")
        local c = nil
        c = HB:Connect(function()
            local e = mobileCharacter()
            if e then
                char = e
                c:Disconnect()
                b:Fire()
            end
        end)
        b.Event:Wait()
        b:Destroy()
    end
    if char then
        char.PrimaryPart.CFrame = goal
    end
end

-- Constants for GUI appearance and behavior
local GUI_SIZE = UDim2.new(0, 280, 0, 120)  -- Size of the GUI
local GUI_POSITION = UDim2.new(0.5, -140, 0.5, -60)  -- Centered position of the GUI
local DRAG_AREA = UDim2.new(0, 0, 0, 20)  -- Draggable area at the top of the GUI

-- Prediction default value
local predictionValue = getgenv().prediction or 1.45  -- Default prediction value

-- Create the GUI
local gui = Instance.new("ScreenGui")
gui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = GUI_SIZE
frame.Position = GUI_POSITION
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)  -- Dark background color
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true  -- Make the frame draggable
frame.ClipsDescendants = true  -- Clip contents that go beyond frame boundaries
frame.BackgroundTransparency = 0.2  -- Partial transparency for a modern look
frame.ZIndex = 2  -- Ensure it's above other UI elements

-- Create GUI elements with gradients and rounded corners
local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 0, 30)
label.Position = UDim2.new(0, 0, 0, 0)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(255, 255, 255)  -- White text color
label.TextSize = 18
label.Font = Enum.Font.GothamBold
label.Text = "Aimbot Settings"
label.Parent = frame

local textBox = Instance.new("TextBox")
textBox.Size = UDim2.new(0.8, 0, 0, 30)
textBox.Position = UDim2.new(0.1, 0, 0.5, -15)
textBox.AnchorPoint = Vector2.new(0.5, 0.5)
textBox.BackgroundTransparency = 0.5
textBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)  -- Darker background color
textBox.TextColor3 = Color3.fromRGB(200, 200, 200)  -- Light text color
textBox.TextSize = 16
textBox.Font = Enum.Font.SourceSans
textBox.PlaceholderText = "Prediction Value"
textBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)  -- Placeholder text color
textBox.Text = tostring(predictionValue)
textBox.Parent = frame

-- Function to update prediction value
local function updatePrediction(newValue)
    predictionValue = tonumber(newValue) or predictionValue
    getgenv().prediction = predictionValue  -- Update the global prediction value
end

-- Connect TextBox input changed event
textBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        updatePrediction(textBox.Text)
    end
end)

-- Apply rounded corners and gradient background
local gradient = Instance.new("UIGradient")
gradient.Rotation = 90
gradient.Parent = frame

local roundedCorner = Instance.new("UICorner")
roundedCorner.CornerRadius = UDim.new(0, 10)
roundedCorner.Parent = frame

frame.Parent = gui



-- Aimlock Logic
do
    local target = nil
    local holding = false

    UIS.InputBegan:Connect(function(keygo, gpe)
        if keygo.KeyCode == getgenv().key and not gpe then
            if not holding then
                local me = mobileCharacter()

                if me then
                    local mr = me.PrimaryPart

                    local selected = nil

                    local params = RaycastParams.new()
                    local filter = {}

                    for i, v in pairs(Players:GetPlayers()) do
                        if v ~= player and mobileCharacter(v.Character) then
                            table.insert(filter, v.Character)
                        end
                    end

                    params.FilterDescendantsInstances = filter
                    params.FilterType = Enum.RaycastFilterType.Whitelist
                    params.IgnoreWater = false

                    local mousePos = UIS:GetMouseLocation()

                    local unitRay = Camera:ScreenPointToRay(mousePos.X, mousePos.Y)

                    local ray = workspace:Raycast(unitRay.Origin, unitRay.Direction * 100, params)

                    if ray then
                        selected = Players:GetPlayerFromCharacter(ray.Instance:FindFirstAncestorOfClass("Model"))

                        target = selected
                        holding = true
                    end

                    if not selected then
                        local closest = nil
                        local dist = math.huge

                        Crew = CrewValue and tonumber(CrewValue.Value) or 0

                        for i, v in pairs(Players:GetPlayers()) do
                            if v ~= player then
                                local c = v.Character

                                if mobileCharacter(c) then
                                    local r = c.PrimaryPart

                                    local _, onScreen = Camera:WorldToScreenPoint(r.Position)

                                    if onScreen then
                                        local distance = (r.Position - mr.Position).Magnitude

                                        local dataFolder = v:FindFirstChild("DataFolder")
                                        local information = dataFolder and dataFolder:FindFirstChild("Information")
                                        local crew = information and information:FindFirstChild("Crew")

                                        local otherCrewId = crew and tonumber(crew.Value)

                                        if Crew ~= otherCrewId and distance < dist then
                                            dist = distance
                                            closest = v
                                        end
                                    end
                                end
                            end
                        end

                        if closest then
                            target = closest
                            holding = true
                        end
                    end
                end
            else
                holding = false
            end
        end
    end)

    local preciseAimFactor = 1

    local update = HB:Connect(function()
        if AimlockEnabled then
            if holding then
                local them = target.Character

                if them then
                    them = mobileCharacter(them)

                    if them then
                        local root = them.PrimaryPart
                        local humanoid = them:FindFirstChildOfClass("Humanoid")

                        local preciseAimOffset = (root.Position - Camera.CFrame.Position).unit * preciseAimFactor

                        local goal = root.CFrame + (humanoid.MoveDirection * getgenv().prediction) + (root.Velocity * getgenv().prediction / 10) + preciseAimOffset

                        local zoom = (Camera.CFrame.Position - Camera.Focus.Position).Magnitude
                        local point, onScreen = Camera:WorldToScreenPoint(goal.Position)

                        if UIS.MouseBehavior ~= Enum.MouseBehavior.LockCurrentPosition then
                            if UIS.MouseBehavior == Enum.MouseBehavior.LockCenter or not onScreen then
                                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.Focus.Position, goal.Position), getgenv().smoothing)
                            else
                                UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
                            end
                        end

                        return
                    end
                end
                holding = false
            end
        else
            holding = false
        end
    end)
end
