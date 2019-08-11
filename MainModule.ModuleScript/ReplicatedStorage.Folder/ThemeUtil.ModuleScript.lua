local ThemeUtil = { }

ThemeUtil.BaseThemeChanged = Instance.new( "BindableEvent" )

ThemeUtil.BaseThemeAdded = Instance.new( "BindableEvent" )

ThemeUtil.ThemeKeyChanged = Instance.new( "BindableEvent" )

local CategoryLoaded = Instance.new( "BindableEvent" )

local BoundUpdates = { }

local ObjBoundUpdates = setmetatable( { }, { __newindex = function ( self, Key, Value )
	
	Key:GetPropertyChangedSignal( "Parent" ):Connect( function ( )
		
		if not Key.Parent then
			
			rawset( self, Key, nil )
			
		end
		
	end )
	
	rawset( self, Key, Value )
	
end } )

function ThemeUtil.BindUpdate( Obj, PropKeys )
	
	if type( Obj ) == "table" then
		
		for _, AObj in ipairs( Obj ) do
			
			ThemeUtil.BindUpdate( AObj, PropKeys )
			
		end
		
		return
		
	end
	
	if type( PropKeys ) == "function" then
		
		BoundUpdates[ Obj ] = PropKeys
		
		coroutine.wrap( function( )
			
			local Ran, Error = pcall( PropKeys )
			
			if not Ran then
				
				warn( "ThemeUtil - Bound Update " .. Obj .. " errored for the initial call\n" .. Error .. "\n" .. debug.traceback( ) )
				
			end
			
		end )( )
		
	else
		
		ObjBoundUpdates[ Obj ] = ObjBoundUpdates[ Obj ] or { }
		
		for Props, Keys in pairs( PropKeys ) do
			
			if type( Keys ) == "function" then
				
				local Ran, Theme = pcall( ThemeUtil.GetThemeFor, Props )
				
				if Ran then
					
					ObjBoundUpdates[ Obj ][ Props ] = Keys
					
					coroutine.wrap( function( )
						
						local Ran, Error = pcall( Keys, Obj, Theme )
						
						if not Ran then
							
							warn( "ThemeUtil - Object Bound Update " .. Obj:GetFullName( ) .. " errored for the initial call for the key '" .. Props .. "'\n" .. Error .. "\n" .. debug.traceback( ) )
							
						end
						
					end )( )
					
				else
					
					warn( "ThemeUtil - Couldn't bind object update for " .. Obj:GetFullName ( ) .. " because " .. Props .. " is not a valid theme key\n" .. debug.traceback( ) )
					
				end
				
			else
				
				
				
				for _, Prop in ipairs( type( Props ) == "table" and Props or { Props } ) do
					
					ObjBoundUpdates[ Obj ][ Prop ] = Keys
					
					local Ran, Error = pcall( function ( ) Obj[ Prop ] = ThemeUtil.GetThemeFor( Keys ) end )
					
					if not Ran then
						
						warn( "ThemeUtil - Object Bound Update " .. Obj:GetFullName( ) .. " errored for the initial call for the property '" .. Prop .. "'\n" .. Error .. "\n" .. debug.traceback( ) )
						
					end
					
				end
				
			end
			
		end
		
	end
	
end

function ThemeUtil.UnbindUpdate( Obj, Properties )
	
	if type( Obj ) == "table" then
		
		for _, AObj in ipairs( Obj ) do
			
			ThemeUtil.UnbindUpdate( AObj, Properties )
			
		end
		
		return
		
	end
	
	if type( Obj ) == "string" then
		
		BoundUpdates[ Obj ] = nil
		
	elseif ObjBoundUpdates[ Obj ] then
		
		Properties = type( Properties ) == "table" and Properties or { Properties }
		
		for a, b in pairs( ObjBoundUpdates[ Obj ] ) do
			
			for _, Prop in ipairs( Properties ) do
				
				if Prop == a then
					
					ObjBoundUpdates[ Obj ][ a ] = nil
					
					break
					
				end
				
			end
			
		end
		
		if not next( ObjBoundUpdates[ Obj ] ) then
			
			ObjBoundUpdates[ Obj ] = nil
			
		end
		
	end
	
end

function ThemeUtil.IsPriorityKey( Keys, Key )
	
	if type( Keys ) == "string" then return Keys == Key end
	
	for _, OKey in ipairs( Keys ) do
		
		if OKey == Key then
			
			return true
			
		elseif ThemeUtil.Theme[ OKey ] then
			
			return
			
		end
		
	end
	
end

function ThemeUtil.UpdateThemeFor( Key, Value )
	
	ThemeUtil.Theme[ Key ] = Value
	
	Value = ThemeUtil.Theme[ Key ]
	
	for a, b in pairs( BoundUpdates ) do
		
		coroutine.wrap( function( )
			
			local Ran, Error = pcall( b, Key, Value )
			
			if not Ran then
				
				warn( "ThemeUtil - Bound Update " .. a .. " errored for '" .. Key .. "'\n" .. Error .. "\n" .. debug.traceback( ) )
				
			end
			
		end )( )
		
	end
	
	for Obj, PropKeys in pairs( ObjBoundUpdates ) do
		
		for Prop, Keys in pairs( PropKeys ) do
			
			if type( Keys ) == "function" then
				
				if ThemeUtil.IsPriorityKey( Prop, Key )then 
					
					coroutine.wrap( function( )
						
						local Ran, Error = pcall( Keys, Obj, Value )
						
						if not Ran then
							
							warn( "ThemeUtil - Object Bound Update " .. Obj:GetFullName( ) .. " errored for the initial call for the key '" .. Key .. "'\n" .. Error .. "\n" .. debug.traceback( ) )
							
						end
						
					end )( )
					
				end
				
			elseif ThemeUtil.IsPriorityKey( Keys, Key ) then
				
				local Ran, Error = pcall( function ( ) Obj[ Prop ] = Value end )
				
				if not Ran then
					
					warn( "ThemeUtil - Object Bound Update " .. Obj:GetFullName( ) .. " errored for the initial call for the property '" .. Prop .. "'\n" .. Error .. "\n" .. debug.traceback( ) )
					
				end
				
			end
			
		end
		
	end
	
end

function ThemeUtil.GetThemeFor( Keys, ... )
	
	local Keys = type( Keys ) == "table" and Keys or { Keys, ... }
	
	for _, Key in ipairs( Keys ) do
		
		if ThemeUtil.Theme[ Key ] ~= nil then
			
			return ThemeUtil.Theme[ Key ]
			
		end
		
	end
	
	error( "ThemeUtil - GetThemeFor failed for key " .. Keys[ 1 ] )
	
end

function ThemeUtil.ContrastTextStroke( Obj, Bkg )
	
	if type( Obj ) == "table" then
		
		for _, AObj in ipairs( Obj ) do
			
			ThemeUtil.ContrastTextStroke( AObj, Bkg )
			
		end
		
		return
		
	end
	
	local _, _, V = Color3.toHSV( Obj.TextColor3 )
	
	local _, _, V2 = Color3.toHSV( Bkg )
	
	if math.abs( V2 - V ) <= 0.25 then
		
		Obj.TextStrokeTransparency = 0
		
		if V2 > 0.5 then
			
			Obj.TextStrokeColor3 = ThemeUtil.GetThemeFor( "Inverted_BackgroundColor" )
			
		else
			
			Obj.TextStrokeColor3 = ThemeUtil.GetThemeFor( "Primary_BackgroundColor" )
			
		end
		
	else
		
		Obj.TextStrokeTransparency = 1
		
	end
	
end

function ThemeUtil.ApplyBasicTheming( Obj, Subtype, DontInvert )
	
	Subtype = Subtype or ""
	
	if type( Obj ) == "table" then
		
		for _, AObj in ipairs( Obj ) do
			
			ThemeUtil.ApplyBasicTheming( AObj, Subtype, DontInvert )
			
		end
		
		return
		
	end
	
	ThemeUtil.BindUpdate( Obj, { BackgroundColor3 = Subtype .. "_BackgroundColor" } )
	
	if Obj:IsA( "TextButton" ) or Obj:IsA( "TextLabel" ) or Obj:IsA( "TextBox" ) then
		
		ThemeUtil.BindUpdate( Obj, { TextColor3 = { Subtype .. "_TextColor", ( Subtype ~= "Inverted" and "Inverted" or "" ) .. Subtype .. "_BackgroundColor" } } )
		
	elseif Obj:IsA( "ImageButton" ) or Obj:IsA( "ImageLabel" ) then
		
		ThemeUtil.BindUpdate( Obj, { ImageColor3 = { Subtype .. "_ImageColor", ( Subtype ~= "Inverted" and "Inverted" or "" ) .. Subtype .. "_BackgroundColor" } } )
		
	end
	
end

function ThemeUtil.UpdateAll( )
	
	for a, b in pairs( BoundUpdates ) do
		
		coroutine.wrap( function( )
			
			local Ran, Error = pcall( b )
			
			if not Ran then
				
				warn( "ThemeUtil - Bound Update " .. a .. " errored when updating all themes\n" .. Error .. "\n" .. debug.traceback( ) )
				
			end
			
		end )( )
		
	end
	
	for Obj, PropKeys in pairs( ObjBoundUpdates ) do
		
		for Prop, Keys in pairs( PropKeys ) do
			
			if type( Keys ) == "function" then
				
				coroutine.wrap( function( )
					
					local Ran, Error = pcall( Keys, Obj, ThemeUtil.GetThemeFor( Prop ) )
					
					if not Ran then
						
						warn( "ThemeUtil - Object Bound Update " .. Obj:GetFullName( ) .. " errored for the initial call for the key '" .. Prop .. "'\n" .. Error .. "\n" .. debug.traceback( ) )
						
					end
					
				end )( )
				
			else
				
				local Ran, Error = pcall( function ( ) Obj[ Prop ] = ThemeUtil.GetThemeFor( Keys ) end )
				
				if not Ran then
					
					warn( "ThemeUtil - Object Bound Update " .. Obj:GetFullName( ) .. " errored for the initial call for the property '" .. Prop .. "'\n" .. Error .. "\n" .. debug.traceback( ) )
					
				end
				
			end
			
		end
		
	end
	
end

ThemeUtil.BaseThemes = { }

ThemeUtil.Theme = { }

function ThemeUtil.SetBaseTheme( NewBase )
	
	if not ThemeUtil.BaseThemes[ NewBase ] then warn( "ThemeUtil - " .. NewBase .. " is not a valid base theme\n" .. debug.traceback( ) ) end
	
	ThemeUtil.BaseThemeChanged:Fire( NewBase )
	
	ThemeUtil.CurrentBase = NewBase
	
	setmetatable( ThemeUtil.Theme, { __index = ThemeUtil.BaseThemes[ NewBase ] } )
	
	ThemeUtil.UpdateAll( )
	
end

ThemeUtil.ThemeKeys = { }

function ThemeUtil.AddThemeKey( Key, Category, DefaultVal )
	
	if DefaultVal ~= nil then
		
		while not ThemeUtil.BaseThemes.Light do wait( ) end
		
		if ThemeUtil.BaseThemes.Light[ Key ] == nil then
			
			ThemeUtil.BaseThemes.Light[ Key ] = DefaultVal
			
		end
		
	elseif ThemeUtil.BaseThemes.Light and ThemeUtil.BaseThemes.Light[ Key ] == nil then
		
		error( "ThemeUtil - Could not add theme key " .. Key .. " without a default value as it doesn't exist in the Light theme" )
		
	end
	
	ThemeUtil.ThemeKeys[ Key ] = Category
	
	ThemeUtil.ThemeKeyChanged:Fire( Key, Category )
	
end

function ThemeUtil.RemoveThemeKey( Key )
	
	ThemeUtil.ThemeKeys[ Key ] = nil
	
	ThemeUtil.ThemeKeyChanged:Fire( Key )
	
end

local FinishedCategories = { }

function ThemeUtil.FinishedCategory( Category )
	
	FinishedCategories[ Category ] = true
	
	CategoryLoaded:Fire( )
	
end

function ThemeUtil.WaitForCategory( Category )
	
	while not FinishedCategories[ Category ] do
		
		CategoryLoaded.Event:Wait( )
		
	end
	
end

ThemeUtil.AddThemeKey( "Primary_BackgroundColor", "Core" )

ThemeUtil.AddThemeKey( "Primary_BackgroundTransparency", "Core" )

ThemeUtil.AddThemeKey( "Inverted_BackgroundColor", "Core" )

ThemeUtil.AddThemeKey( "Secondary_BackgroundColor", "Core" )

ThemeUtil.AddThemeKey( "Secondary_BackgroundTransparency", "Core" )

ThemeUtil.AddThemeKey( "Primary_TextColor", "Core" )

ThemeUtil.AddThemeKey( "Primary_TextTransparency", "Core" )

ThemeUtil.AddThemeKey( "Inverted_TextColor", "Core" )

ThemeUtil.AddThemeKey( "Secondary_TextColor", "Core" )

ThemeUtil.AddThemeKey( "Secondary_TextTransparency", "Core" )

ThemeUtil.AddThemeKey( "Positive_Color3", "Core" )

ThemeUtil.AddThemeKey( "Negative_Color3", "Core" )

ThemeUtil.AddThemeKey( "Progress_Color3", "Core" )

ThemeUtil.AddThemeKey( "Selection_Color3", "Core" )

local CurDefault

function ThemeUtil.AddBaseTheme( Module )
	
	if ThemeUtil.BaseThemes[ Module.Name ] then
		
		warn( "ThemeUtil - Couldn't add " .. Module.Name .. " as a base theme with that name already exists" )
		
		return false
		
	end
	
	local BaseTheme = require( Module )
	
	local Inherit
	
	if Module.Name ~= "Light" then
		
		BaseTheme.Inherits = BaseTheme.Inherits or "Light"
		
		if type( BaseTheme.Inherits ) == "string" then
			
			Inherit = ThemeUtil.BaseThemes[ BaseTheme.Inherits ]
			
			if not Inherit and script:FindFirstChild( BaseTheme.Inherits ) then
				
				Inherit = ThemeUtil.AddBaseTheme( Module )
				
			end
			
		else
			
			Inherit = ThemeUtil.AddBaseTheme( BaseTheme.Inherits )
			
		end
		
	end
	
	if Inherit == false then
		
		warn( "ThemeUtil - Couldn't add " .. Module.Name .. " as a base theme as its inherited theme doesn't exist" )
		
		return false
		
	end
	
	if Inherit == nil and Module.Name ~= "Light" then
		
		Inherit = ThemeUtil.BaseThemes[ "Light" ]
		
	end
	
	ThemeUtil.BaseThemes[ Module.Name ] = setmetatable( BaseTheme.Theme, { __index = Inherit } )
	
	if BaseTheme.Default and ( not CurDefault or BaseTheme.Default > CurDefault ) then
		
		CurDefault = BaseTheme.Default
		
		ThemeUtil.SetBaseTheme( Module.Name )
		
	end
	
	ThemeUtil.BaseThemeAdded:Fire( Module.Name )
	
	return ThemeUtil.BaseThemes[ Module.Name ]
	
end

script.ChildAdded:Connect( ThemeUtil.AddBaseTheme )

for _, Obj in ipairs( script:GetChildren( ) ) do
	
	ThemeUtil.AddBaseTheme( Obj )
	
end

local CustomThemes

if game:GetService( "RunService" ):IsServer( ) then
	
	CustomThemes = game:GetService( "ReplicatedStorage" ):FindFirstChild( "CustomThemes" ) or Instance.new( "Folder" )
	
	CustomThemes.Name = "CustomThemes"
	
	CustomThemes.Parent = game:GetService( "ReplicatedStorage" )
	
else
	
	CustomThemes = game:GetService( "ReplicatedStorage" ):WaitForChild( "CustomThemes" )
	
end

CustomThemes.ChildAdded:Connect( ThemeUtil.AddBaseTheme )

for _, Obj in ipairs( CustomThemes:GetChildren( ) ) do
	
	ThemeUtil.AddBaseTheme( Obj )
	
end

if false then
	
	spawn( function ( )
		
		while wait( ) do
			
			local H, S, V = tick( ) * 10 % 255, 127.5 + math.sin( tick( ) * 0.3 ) * 127.5, 127.5 + math.sin( tick( ) * 0.5 + 10 ) * 127.5
			
			ThemeUtil.UpdateThemeFor( "Primary_BackgroundColor", Color3.fromHSV( H / 255, S / 255, V / 255 ) )
			
			ThemeUtil.UpdateThemeFor( "Primary_BackgroundTransparency", math.sin( tick( ) * 0.3 ) )
			
			ThemeUtil.UpdateThemeFor( "Secondary_BackgroundColor", Color3.fromHSV( H / 255, S / 255, ( V > 122.5 and ( V - 75 ) or ( V + 36 ) ) / 255 ) )
			
			if V / 255 > 0.75 then
				
				ThemeUtil.UpdateThemeFor( "Inverted_BackgroundColor", Color3.fromRGB( H / 255, S / 255, ( V - 255 ) / 255 ) )
				
				ThemeUtil.UpdateThemeFor( "Primary_TextColor", Color3.fromRGB( 46, 46, 46 ) )
				
			else
				
				ThemeUtil.UpdateThemeFor( "Inverted_BackgroundColor", Color3.fromRGB( H / 255, S / 255, ( V - 255 ) / 255 ) )
				
				ThemeUtil.UpdateThemeFor( "Primary_TextColor", Color3.fromRGB( 255, 255, 255 ) )
				
			end
			
		end
		
	end )
	
end

return ThemeUtil