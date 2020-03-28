local ThemeUtil = {
	BaseThemeChanged = Instance.new("BindableEvent"),
	BaseThemeAdded = Instance.new("BindableEvent"),
	ThemeKeyChanged = Instance.new("BindableEvent"),
	CategoryLoaded = Instance.new("BindableEvent"),
	BaseThemes = {},
	Theme = {},
	ThemeKeys = {},
	CurrentBase = nil,
}


---- Theming related functions ----

function ThemeUtil.IsPriorityKey(Keys, Key)
	if type(Keys) == "string" then
		return Keys == Key
	else
		for _, OKey in ipairs(Keys) do
			if OKey == Key then
				return true
			elseif ThemeUtil.Theme[OKey] then
				return
			end
		end
	end
end

function ThemeUtil.GetThemeFor(Keys, ...)
	local Keys = type(Keys) == "table" and Keys or {Keys, ...}
	for _, Key in ipairs(Keys) do
		if ThemeUtil.Theme[Key] ~= nil then
			return ThemeUtil.Theme[Key]
		end
	end
	
	error("ThemeUtil - GetThemeFor failed for key " .. tostring(Keys[1]))
end

local function SetPropThemeFor(Obj, Prop, Keys)
	Obj[Prop] = ThemeUtil.GetThemeFor(Keys)
end

local function SetProp(Obj, Prop, Value)
	Obj[Prop] = Value
end

local BoundUpdates = {}
local ObjBoundUpdates = setmetatable({}, {__newindex = function(self, Key, Value)
	Key:GetPropertyChangedSignal("Parent"):Connect(function()
		if not Key.Parent then
			rawset(self, Key, nil)
		end
	end)
	rawset(self, Key, Value)
end})
function ThemeUtil.BindUpdate(Obj, PropKeys)
	if type(Obj) == "table" then
		for _, AObj in ipairs(Obj) do
			ThemeUtil.BindUpdate(AObj, PropKeys)
		end
	elseif type(PropKeys) == "function" then
		BoundUpdates[Obj] = PropKeys
		
		coroutine.wrap(function()
			local Ran, Error = pcall(PropKeys)
			if not Ran then
				warn("ThemeUtil - Bound Update " .. Obj .. " errored for the initial call\n" .. Error .. "\n" .. debug.traceback())
			end
		end)()
	else
		ObjBoundUpdates[Obj] = ObjBoundUpdates[Obj] or {}
		for Props, Keys in pairs(PropKeys) do
			if type(Keys) == "function" then
				local Ran, Theme = pcall(ThemeUtil.GetThemeFor, Props)
				if Ran then
					ObjBoundUpdates[Obj][Props] = Keys
					
					coroutine.wrap(function()
						local Ran, Error = pcall(Keys, Obj, Theme)
						if not Ran then
							warn("ThemeUtil - Object Bound Update " .. Obj:GetFullName() .. " errored for the initial call for the key '" .. Props .. "'\n" .. Error .. "\n" .. debug.traceback())
						end
					end)()
				else
					warn("ThemeUtil - Couldn't bind object update for " .. Obj:GetFullName () .. " because " .. Props .. " is not a valid theme key\n" .. debug.traceback())
				end
			else
				for _, Prop in ipairs(type(Props) == "table" and Props or {Props}) do
					ObjBoundUpdates[Obj][Prop] = Keys
					
					local Ran, Error = pcall(SetPropThemeFor, Obj, Prop, Keys)
					if not Ran then
						warn("ThemeUtil - Object Bound Update " .. Obj:GetFullName() .. " errored for the initial call for the property '" .. Prop .. "'\n" .. Error .. "\n" .. debug.traceback())
					end
				end
			end
		end
	end
end

function ThemeUtil.UnbindUpdate(Obj, Properties)
	if type(Obj) == "table" then
		for _, AObj in ipairs(Obj) do
			ThemeUtil.UnbindUpdate(AObj, Properties)
		end
	elseif type(Obj) == "string" then
		BoundUpdates[Obj] = nil
	elseif ObjBoundUpdates[Obj] then
		Properties = type(Properties) == "table" and Properties or {Properties}
		for a, b in pairs(ObjBoundUpdates[Obj]) do
			for _, Prop in ipairs(Properties) do
				if Prop == a then
					ObjBoundUpdates[Obj][a] = nil
					break
				end
			end
		end
		
		if not next(ObjBoundUpdates[Obj]) then
			ObjBoundUpdates[Obj] = nil
		end
	end
end

function ThemeUtil.UpdateThemeFor(Key, Value)
	if Key then
		ThemeUtil.Theme[Key] = Value
		Value = ThemeUtil.Theme[Key]
	end
	
	for a, b in pairs(BoundUpdates) do
		coroutine.wrap(function()
			local Ran, Error = pcall(b, Key, Value)
			if not Ran then
				warn("ThemeUtil - Bound Update " .. a .. " errored " .. ( Key and ("for '" .. Key .. "'\n" .. Error .. "\n") or "when updating all themes\n") .. debug.traceback())
			end
		end)()
	end
	
	for Obj, PropKeys in pairs(ObjBoundUpdates) do
		for Prop, Keys in pairs(PropKeys) do
			if type(Keys) == "function" then
				if not Key or ThemeUtil.IsPriorityKey(Prop, Key)then 
					coroutine.wrap(function()
						local Ran, Error = pcall(Keys, Obj, Value or ThemeUtil.GetThemeFor(Prop))
						if not Ran then
							warn("ThemeUtil - Object Bound Update " .. Obj:GetFullName() .. " errored for the initial call for the key '" .. (Key or Prop) .. "'\n" .. Error .. "\n" .. debug.traceback())
						end
					end)()
				end
			elseif not Key or ThemeUtil.IsPriorityKey(Keys, Key) then
				local Ran, Error = pcall(Value and SetProp or SetPropThemeFor, Obj, Prop, Value or Keys)
				if not Ran then
					warn("ThemeUtil - Object Bound Update " .. Obj:GetFullName() .. " errored for the initial call for the property '" .. Prop .. "'\n" .. Error .. "\n" .. debug.traceback())
				end
			end
		end
	end
end

---- Base theme related functions ----

local CurDefault
local Processing = {}
function ThemeUtil.AddBaseTheme(Module)
	if ThemeUtil.BaseThemes[Module.Name] then
		local BaseTheme = require(Module)
		if ThemeUtil.BaseThemes[Module.Name] ~= BaseTheme.Theme then
			warn("ThemeUtil - Couldn't add " .. Module.Name .. " as a base theme with that name already exists")
			return false
		end
	elseif Processing[Module.Name] then
		warn("ThemeUtil - Couldn't add " .. Module.Name .. " as it's already in the process of being added (circular inherit) or errored while being added")
		return Processing
	else
		Processing[Module.Name] = true
		local BaseTheme = require(Module)
		local Inherit
		if Module.Name ~= "Light" then
			BaseTheme.Inherits = BaseTheme.Inherits or "Light"
			if type(BaseTheme.Inherits) == "string" then
				Inherit = ThemeUtil.BaseThemes[BaseTheme.Inherits]
				if not Inherit and script:FindFirstChild(BaseTheme.Inherits) then
					Inherit = ThemeUtil.AddBaseTheme(script:FindFirstChild(BaseTheme.Inherits))
				end
			else
				Inherit = ThemeUtil.AddBaseTheme(BaseTheme.Inherits)
			end
		end
		
		if Inherit == false then
			warn("ThemeUtil - Couldn't add " .. Module.Name .. " as a base theme as its inherited theme doesn't exist")
			return false
		elseif Inherit == Processing then
			warn("ThemeUtil - Couldn't add " .. Module.Name .. " as a base theme due to either a circular inherit or it's inherited theme erroring")
			return false
		else
			if Inherit == nil and Module.Name ~= "Light" then
				Inherit = ThemeUtil.BaseThemes["Light"]
			end
			
			ThemeUtil.BaseThemes[Module.Name] = setmetatable(BaseTheme.Theme, {__index = Inherit})
			if BaseTheme.Default and (not CurDefault or BaseTheme.Default > CurDefault) then
				CurDefault = BaseTheme.Default
				ThemeUtil.SetBaseTheme(Module.Name)
			end
			
			Processing[Module.Name] = nil
			
			print("ThemeUtil - Added base theme " .. Module.Name)
			ThemeUtil.BaseThemeAdded:Fire(Module.Name)
			return ThemeUtil.BaseThemes[Module.Name]
		end
	end
end

function ThemeUtil.SetBaseTheme(NewBase)
	if ThemeUtil.BaseThemes[NewBase] then
		local OldBase = ThemeUtil.CurrentBase
		ThemeUtil.CurrentBase = NewBase
		setmetatable(ThemeUtil.Theme, {__index = ThemeUtil.BaseThemes[NewBase]})
		
		ThemeUtil.BaseThemeChanged:Fire(OldBase)
		
		ThemeUtil.UpdateThemeFor()
	else
		warn("ThemeUtil - " .. NewBase .. " is not a valid base theme\n" .. debug.traceback())
	end
end

---- Theme key related functions ----

local FinishedCategories = {}
function ThemeUtil.FinishedCategory(Category)
	FinishedCategories[Category] = true
	ThemeUtil.CategoryLoaded:Fire()
end

function ThemeUtil.WaitForCategory(Category)
	while not FinishedCategories[Category] do
		ThemeUtil.CategoryLoaded.Event:Wait()
	end
end

function ThemeUtil.AddThemeKey(Key, Category, DefaultVal)
	if DefaultVal ~= nil then
		while not ThemeUtil.BaseThemes.Light do
			ThemeUtil.BaseThemeAdded.Event:Wait()
		end
		
		if ThemeUtil.BaseThemes.Light[Key] == nil then
			ThemeUtil.BaseThemes.Light[Key] = DefaultVal
		end
	elseif ThemeUtil.BaseThemes.Light and ThemeUtil.BaseThemes.Light[Key] == nil then
		error("ThemeUtil - Could not add theme key " .. Key .. " without a default value as it doesn't exist in the Light theme")
	end
	
	ThemeUtil.ThemeKeys[Key] = Category
	ThemeUtil.ThemeKeyChanged:Fire(Key, Category)
end

function ThemeUtil.RemoveThemeKey(Key)
	ThemeUtil.ThemeKeys[Key] = nil
	ThemeUtil.ThemeKeyChanged:Fire(Key)
end

---- Add default theme keys ----

ThemeUtil.AddThemeKey("Primary_BackgroundColor", "Core")
ThemeUtil.AddThemeKey("Primary_BackgroundTransparency", "Core")
ThemeUtil.AddThemeKey("Inverted_BackgroundColor", "Core")
ThemeUtil.AddThemeKey("Secondary_BackgroundColor", "Core")
ThemeUtil.AddThemeKey("Secondary_BackgroundTransparency", "Core")
ThemeUtil.AddThemeKey("Primary_TextColor", "Core")
ThemeUtil.AddThemeKey("Primary_TextTransparency", "Core")
ThemeUtil.AddThemeKey("Inverted_TextColor", "Core")
ThemeUtil.AddThemeKey("Secondary_TextColor", "Core")
ThemeUtil.AddThemeKey("Secondary_TextTransparency", "Core")
ThemeUtil.AddThemeKey("Positive_Color3", "Core")
ThemeUtil.AddThemeKey("Negative_Color3", "Core")
ThemeUtil.AddThemeKey("Progress_Color3", "Core")
ThemeUtil.AddThemeKey("Selection_Color3", "Core")

---- Add default base themes ----

script:WaitForChild("Light")

script.ChildAdded:Connect(ThemeUtil.AddBaseTheme)
for _, Obj in ipairs(script:GetChildren()) do
	ThemeUtil.AddBaseTheme(Obj)
end

---- Add custom base themes ----

local CustomThemes
if game:GetService("RunService"):IsServer() then
	CustomThemes = game:GetService("ReplicatedStorage"):FindFirstChild("CustomThemes") or Instance.new("Folder")
	CustomThemes.Name = "CustomThemes"
	CustomThemes.Parent = game:GetService("ReplicatedStorage")
else
	CustomThemes = game:GetService("ReplicatedStorage"):WaitForChild("CustomThemes")
end

CustomThemes.ChildAdded:Connect(ThemeUtil.AddBaseTheme)
for _, Obj in ipairs(CustomThemes:GetChildren()) do
	ThemeUtil.AddBaseTheme(Obj)
end

---- Helper functions ----

function ThemeUtil.ContrastTextStroke(Obj, Bkg)
	if type(Obj) == "table" then
		for _, AObj in ipairs(Obj) do
			ThemeUtil.ContrastTextStroke(AObj, Bkg)
		end
	else
		local _, _, V = Color3.toHSV(Obj.TextColor3)
		local _, _, V2 = Color3.toHSV(Bkg)
		if math.abs(V2 - V) <= 0.25 then
			Obj.TextStrokeTransparency = 0
			if V2 > 0.5 then
				Obj.TextStrokeColor3 = ThemeUtil.GetThemeFor("Inverted_BackgroundColor")
			else
				Obj.TextStrokeColor3 = ThemeUtil.GetThemeFor("Primary_BackgroundColor")
			end
		else
			Obj.TextStrokeTransparency = 1
		end
	end
end

function ThemeUtil.ApplyBasicTheming(Obj, Subtype, DontInvert)
	Subtype = Subtype or ""
	if type(Obj) == "table" then
		for _, AObj in ipairs(Obj) do
			ThemeUtil.ApplyBasicTheming(AObj, Subtype, DontInvert)
		end
	else
		ThemeUtil.BindUpdate(Obj, {BackgroundColor3 = Subtype .. "_BackgroundColor"})
		if Obj:IsA("TextButton") or Obj:IsA("TextLabel") or Obj:IsA("TextBox") then
			ThemeUtil.BindUpdate(Obj, {TextColor3 = {Subtype .. "_TextColor", (Subtype ~= "Inverted" and "Inverted" or "") .. Subtype .. "_BackgroundColor"}})
		elseif Obj:IsA("ImageButton") or Obj:IsA("ImageLabel") then
			ThemeUtil.BindUpdate(Obj, {ImageColor3 = {Subtype .. "_ImageColor", (Subtype ~= "Inverted" and "Inverted" or "") .. Subtype .. "_BackgroundColor"}})
		end
	end
end

---- Return Module ----

return ThemeUtil