--[[
    RIPPED FROM: https://github.com/Averiias/Universal-SilentAim
--]]
local SilentAimSettings = {
    Enabled = false,
    
    ClassName = "Universal Silent Aim - Averiias, Stefanuk12, xaxa",
    ToggleKey = "RightAlt",
    
    TeamCheck = false,
    VisibleCheck = false, 
    TargetPart = "Head",
    SilentAimMethod = "FindPartOnRayWithIgnoreList",
    
    FOVRadius = 130,
    FOVVisible = false,
    ShowSilentAimTarget = false, 
    
    MouseHitPrediction = false,
    MouseHitPredictionAmount = 0.165,
    HitChance = 100
}
local function FindPlrFromName(name)
	local lower_ = string.lower(name)
	for i,v in pairs(game:GetService("Players"):GetChildren()) do
		if v:IsA("Player") then
			if string.lower(v.Name) == lower_ then
				return v
			end
		end
	end
end

-- variables
--getgenv().SilentAimSettings = Settings
local notify = function() end
if getgenv().SilentAimNotify ~= nil then
	notify = getgenv().SilentAimNotify
end
local SilentAim = getgenv().Aimbot
local MainFileName = "UniversalSilentAim"
local SelectedFile, FileToSave = "", ""

local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local GetChildren = game.GetChildren
local GetPlayers = Players.GetPlayers
local WorldToScreen = Camera.WorldToScreenPoint
local WorldToViewportPoint = Camera.WorldToViewportPoint
local GetPartsObscuringTarget = Camera.GetPartsObscuringTarget
local FindFirstChild = game.FindFirstChild
local RenderStepped = RunService.RenderStepped
local GuiInset = GuiService.GetGuiInset
local GetMouseLocation = UserInputService.GetMouseLocation

local resume = coroutine.resume 
local create = coroutine.create

local ValidTargetParts = {"Head", "HumanoidRootPart"}
local PredictionAmount = 0.165

local mouse_box = Drawing.new("Square")
mouse_box.Visible = false 
mouse_box.ZIndex = 999 
mouse_box.Color = Color3.fromRGB(54, 57, 241)
mouse_box.Thickness = 20 
mouse_box.Size = Vector2.new(20, 20)
mouse_box.Filled = true 

local fov_circle = Drawing.new("Circle")
fov_circle.Thickness = 1
fov_circle.NumSides = 100
fov_circle.Radius = 180
fov_circle.Filled = false
fov_circle.Visible = false
fov_circle.ZIndex = 999
fov_circle.Transparency = 1
fov_circle.Color = Color3.fromRGB(54, 57, 241)

local ExpectedArguments = {
    FindPartOnRayWithIgnoreList = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Ray", "table", "boolean", "boolean"
        }
    },
    FindPartOnRayWithWhitelist = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Ray", "table", "boolean"
        }
    },
    FindPartOnRay = {
        ArgCountRequired = 2,
        Args = {
            "Instance", "Ray", "Instance", "boolean", "boolean"
        }
    },
    Raycast = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Vector3", "Vector3", "RaycastParams"
        }
    }
}

-- function
local SA_wl = {}
local Target = nil
local MB2Down = false

local function getPositionOnScreen(Vector)
    local Vec3, OnScreen = WorldToScreen(Camera, Vector)
    return Vector2.new(Vec3.X, Vec3.Y), OnScreen
end

local function ValidateArguments(Args, RayMethod)
    local Matches = 0
    if #Args < RayMethod.ArgCountRequired then
        return false
    end
    for Pos, Argument in next, Args do
        if typeof(Argument) == RayMethod.Args[Pos] then
            Matches = Matches + 1
        end
    end
    return Matches >= RayMethod.ArgCountRequired
end

local function getDirection(Origin, Position)
    return (Position - Origin).Unit * 1000
end

local function getMousePosition()
    return GetMouseLocation(UserInputService)
end

local function IsPlayerVisible(Player)
    local PlayerCharacter = Player.Character
    local LocalPlayerCharacter = LocalPlayer.Character
    
    if not (PlayerCharacter or LocalPlayerCharacter) then return end 
    
    local PlayerRoot = FindFirstChild(PlayerCharacter, SilentAimSettings.TargetPart) or FindFirstChild(PlayerCharacter, "HumanoidRootPart")
    
    if not PlayerRoot then return end 
    
    local CastPoints, IgnoreList = {PlayerRoot.Position, LocalPlayerCharacter, PlayerCharacter}, {LocalPlayerCharacter, PlayerCharacter}
    local ObscuringObjects = #GetPartsObscuringTarget(Camera, CastPoints, IgnoreList)
    
    return ((ObscuringObjects == 0 and true) or (ObscuringObjects > 0 and false))
end
function CalculateChance(Percentage)
    -- // Floor the percentage
    Percentage = math.floor(Percentage)

    -- // Get the chance
    local chance = math.floor(Random.new().NextNumber(Random.new(), 0, 1) * 100) / 100

    -- // Return
    return chance <= Percentage / 100
end
local function getClosestPlayer()
    if SilentAimSettings.TargetPart == false then return end
    local Closest
    local DistanceToMouse
    for _, Player in next, GetPlayers(Players) do
        if Player == LocalPlayer then continue end
        if SilentAimSettings.TeamCheck == true and Player.Team == LocalPlayer.Team then continue end

        local Character = Player.Character
        if not Character then continue end

        local HumanoidRootPart = FindFirstChild(Character, "HumanoidRootPart")
        local Humanoid = FindFirstChild(Character, "Humanoid")
        if not HumanoidRootPart or not Humanoid or Humanoid and Humanoid.Health <= 0 then continue end

        local ScreenPosition, OnScreen = getPositionOnScreen(HumanoidRootPart.Position)
        if not OnScreen then continue end

        local Distance = (getMousePosition() - ScreenPosition).Magnitude
        if not table.find(SA_wl,Character.Name) then
           if Distance <= (DistanceToMouse or SilentAimSettings.FOVRadius or 2000) then
            Closest = ((SilentAimSettings.TargetPart == "Random" and Character[ValidTargetParts[math.random(1, #ValidTargetParts)]]) or Character[SilentAimSettings.TargetPart])
            DistanceToMouse = Distance
        end 
        end
    end
    if Closest ~= nil then
        Target = Closest.Position
    else
        Target = nil
    end
    return Closest
end
local function Aimbot(Target)
   workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position,Target)
end
    --"Visible", {Text = "Show FOV Circle"}):AddColorPicker("Color", {Default = Color3.fromRGB(54, 57, 241)}):OnChanged(function()
        --fov_circle.Visible = Toggles.Visible.Value
        --SilentAimSettings.FOVVisible = Toggles.Visible.Value
    --"Radius", {Text = "FOV Circle Radius", Min = 0, Max = 360, Default = 130, Rounding = 0}):OnChanged(function()
        --fov_circle.Radius = Options.Radius.Value
        --SilentAimSettings.FOVRadius = Options.Radius.Value
    --"Show Silent Aim Target"
        --mouse_box.Visible = Toggles.MousePosition.Value 
        --SilentAimSettings.ShowSilentAimTarget = Toggles.MousePosition.Value
	SilentAim:AddToggle{text = "Enabled", flag = "SilentAimEnabled", callback = function(state) 
		SilentAimSettings.Enabled = state
	end}
	SilentAim:AddToggle{text = "Team Check", flag = "SilentAimTeamCheck", callback = function(state) 
		SilentAimSettings.TeamCheck = state
	end}
	SilentAim:AddList({text = "Target Part", flag = "SilentAimTargetPart", value = "Head", values = {"Head","HumanoidRootPart","Random"}, callback = function(value) 
		SilentAimSettings.TargetPart = value
	end})
	SilentAim:AddToggle{text = "Show FOV Circle", flag = "SilentAimShowFOVCircle", callback = function(state)
		fov_circle.Visible = state
		SilentAimSettings.FOVVisible = state
	end}
	SilentAim:AddSlider{text = "FOV Circle Radius", flag = "SilentAimFOVRadius", min = 1, max = 1000, value = 100, callback = function(value)
		fov_circle.Radius = value
		SilentAimSettings.FOVRadius = value
	end}
	SilentAim:AddSlider{text = "FOV Circle Sides", flag = "SilentAimFOVSides", min = 1, max = 48, value = 8, callback = function(value)
		fov_circle.NumSides = value
	end}
	SilentAim:AddToggle{text = "Show Silent Aim Target", flag = "SilentAimShowTarget", callback = function(state)
		mouse_box.Visible = state
        SilentAimSettings.ShowSilentAimTarget = state
	end}
resume(create(function()
    RenderStepped:Connect(function()
        if SilentAimSettings.ShowSilentAimTarget == true and SilentAimSettings.Enabled == true then
            if getClosestPlayer() then
                local Root = getClosestPlayer().Parent.PrimaryPart or getClosestPlayer()
                local RootToViewportPoint, IsOnScreen = WorldToViewportPoint(Camera, Root.Position);
                -- using PrimaryPart instead because if your Target Part is "Random" it will flicker the square between the Target's Head and HumanoidRootPart (its annoying)
                
                mouse_box.Visible = IsOnScreen
                mouse_box.Position = Vector2.new(RootToViewportPoint.X, RootToViewportPoint.Y)
                if getgenv().library then
            	      mouse_box.Color = getgenv().library.options["Menu Accent Color"].color
	              end
            else 
                mouse_box.Visible = false 
                mouse_box.Position = Vector2.new()
            end
        end
        
        if SilentAimSettings.FOVVisible == true then 
            fov_circle.Visible = SilentAimSettings.FOVVisible
            if getgenv().library then
            	fov_circle.Color = getgenv().library.options["Menu Accent Color"].color
	          end
            fov_circle.Position = getMousePosition()
        end
    end)
end))
UserInputService.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton2 and SilentAimSettings.Enabled == true then
        MB2Down = true
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton2 then
        MB2Down = false
    end
end)
RunService.RenderStepped:Connect(function()
    if SilentAimSettings.Enabled == true and MB2Down == true and Target ~= nil then
        Aimbot(Target)
    end
end)

