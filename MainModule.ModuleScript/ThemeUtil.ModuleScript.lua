local ThemeUtil = { }

ThemeUtil.BaseThemeChanged = Instance.new( "BindableEvent" )

ThemeUtil.BaseThemeAdded = Instance.new( "BindableEvent" )

local BoundUpdates = { }

local ObjBoundUpdates = setmetatable( { }, { __newindex = function ( self, Key, Value )
	
	Key:GetPropertyChangedSignal( "Parent" ):Connect( function ( )
		
		if not Key.Parent then
			
			rawset( self, Key, nil )
			
		end
		
	end )
	
	rawset( self, Key, Value )
	
end } )

function ThemeUtil.BindUpdate( Obj, PropKeys, OldKeys )
	
	if OldKeys then
		
		warn( Obj:GetFullName( ) .. " is using the old BindUpdate function, please update to:\nBindUpdate( Obj, { Property = Keys } )" )
		
		return ThemeUtil.OldBindUpdate( Obj, PropKeys, OldKeys )
		
	end
	
	if type( Obj ) == "table" then
		
		for a = 1, #Obj do
			
			ThemeUtil.BindUpdate( Obj[ a ], PropKeys )
			
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
			
			Props = type( Props ) == "table" and Props or { Props }
			
			for a = 1, #Props do
				
				ObjBoundUpdates[ Obj ][ Props[ a ] ] = Keys
				
				if type( Keys ) == "function" then
					
					coroutine.wrap( function( )
						
						local Ran, Error = pcall( Keys, Obj )
						
						if not Ran then
							
							warn( "ThemeUtil - Object Bound Update " .. Obj:GetFullName( ) .. " errored for the initial call for the property '" .. Props[ a ] .. "'\n" .. Error .. "\n" .. debug.traceback( ) )
							
						end
						
					end )( )
					
				else
					
					local Ran, Error = pcall( function ( ) Obj[ Props[ a ] ] = ThemeUtil.GetThemeFor( type( Keys ) ~= "table" and Keys or unpack( Keys ) ) end )
					
					if not Ran then
						
						warn( "ThemeUtil - Object Bound Update " .. Obj:GetFullName( ) .. " errored for the initial call for the property '" .. Props[ a ] .. "'\n" .. Error .. "\n" .. debug.traceback( ) )
						
					end
					
				end
				
			end
			
		end
		
	end
	
end

function ThemeUtil.OldBindUpdate( Obj, Properties, Keys )
	
	if type( Obj ) == "table" then
		
		for a = 1, #Obj do
			
			ThemeUtil.BindUpdate( Obj[ a ], Properties, Keys )
			
		end
		
		return
		
	end
	
	if type( Properties ) == "function" then
		
		BoundUpdates[ Obj ] = Properties
		
		coroutine.wrap( function( )
			
			local Ran, Error = pcall( Properties )
			
			if not Ran then
				
				warn( "ThemeUtil - Bound Update " .. Obj .. " errored for the initial call\n" .. Error .. "\n" .. debug.traceback( ) )
				
			end
			
		end )( )
		
	else
		
		Properties = type( Properties ) == "table" and Properties or { Properties }
		
		Keys = type( Keys ) == "table" and Keys or type( Keys ) == "function" and Keys or { Keys }
			
		ObjBoundUpdates[ Obj ] = ObjBoundUpdates[ Obj ] or { }
		
		for a = 1, #Properties do
			
			ObjBoundUpdates[ Obj ][ Properties[ a ] ] = Keys
			
		end
		
		for a = 1, #Properties do
			
			if type( Keys ) == "function" then
				
				coroutine.wrap( function( )
					
					local Ran, Error = pcall( Keys, Obj )
					
					if not Ran then
						
						warn( "ThemeUtil - Object Bound Update " .. Obj:GetFullName( ) .. " errored for the initial call for the property '" .. Properties[ a ] .. "'\n" .. Error .. "\n" .. debug.traceback( ) )
						
					end
					
				end )( )
				
			else
				
				local Ran, Error = pcall( function ( ) Obj[ Properties[ a ] ] = ThemeUtil.GetThemeFor( type( Keys ) ~= "table" and Keys or unpack( Keys ) ) end )
				
				if not Ran then
					
					warn( "ThemeUtil - Object Bound Update " .. Obj:GetFullName( ) .. " errored for the initial call for the property '" .. Properties[ a ] .. "'\n" .. Error .. "\n" .. debug.traceback( ) )
					
				end
				
			end
			
		end
		
	end
	
end

function ThemeUtil.UnbindUpdate( Obj, Properties )
	
	if type( Obj ) == "table" then
		
		for a = 1, #Obj do
			
			ThemeUtil.UnbindUpdate( Obj[ a ], Properties )
			
		end
		
		return
		
	end
	
	if type( Obj ) == "string" then
		
		BoundUpdates[ Obj ] = nil
		
	elseif ObjBoundUpdates[ Obj ] then
		
		Properties = type( Properties ) == "table" and Properties or { Properties }
		
		for a, b in pairs( ObjBoundUpdates[ Obj ] ) do
			
			for c = 1, #Properties do
				
				if Properties[ c ] == a then
					
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
	
	for a, b in pairs( ObjBoundUpdates ) do
		
		for c, d in pairs( b ) do
			
			if type( d ) == "function" then
				
				coroutine.wrap( function( )
					
					local Ran, Error = pcall( d, a )
					
					if not Ran then
						
						warn( "ThemeUtil - Object Bound Update " .. a:GetFullName( ) .. " errored for the property '" .. c .. "'\n" .. Error .. "\n" .. debug.traceback( ) )
						
					end
					
				end )( )
				
			elseif type( d ) == "string" then
				
				if d == Key then
					
					local Ran, Error = pcall( function ( ) a[ c ] = Value end )
					
					if not Ran then
						
						warn( "ThemeUtil - Object Bound Update " .. a:GetFullName( ) .. " errored for '" .. d .. "' for the property '" .. c .. "\n" .. Error .. "\n" .. debug.traceback( ) )
						
					end
					
				end
				
			else
				
				for e = 1, #d do
					
					if d[ e ] == Key then
						
						local Ran, Error = pcall( function ( ) a[ c ] = Value end )
						
						if not Ran then
							
							warn( "ThemeUtil - Object Bound Update " .. a:GetFullName( ) .. " errored for '" .. d[ e ] .. "' for the property '" .. c .. "\n" .. Error .. "\n" .. debug.traceback( ) )
							
						end
						
						break
						
					elseif ThemeUtil.Theme[ d[ e ] ] then
						
						break
						
					end
					
				end
				
			end
			
		end
		
	end
	
end

function ThemeUtil.GetThemeFor( ... )
	
	local Keys = { ... }
	
	for a = 1, #Keys do
		
		if ThemeUtil.Theme[ Keys[ a ] ] then
			
			return ThemeUtil.Theme[ Keys[ a ] ]
			
		end
		
	end
	
	error( "ThemeUtil - GetThemeFor failed for key " .. Keys[ 1 ] )
	
end

function ThemeUtil.ContrastTextStroke( Obj, Bkg )
	
	if type( Obj ) == "table" then
		
		for a = 1, #Obj do
			
			ThemeUtil.ContrastTextStroke( Obj[ a ], Bkg )
			
		end
		
		return
		
	end
	
	local _, _, V = Color3.toHSV( Obj.TextColor3 )
	
	local _, _, V2 = Color3.toHSV( Bkg )
	
	if Obj.Parent.ImageTransparency >= 1 then
		
		Obj.TextStrokeTransparency = 0
		
		if V > 0.5 then
			
			Obj.TextStrokeColor3 = ThemeUtil.GetThemeFor( "Inverted_BackgroundColor" )
			
		else
			
			Obj.TextStrokeColor3 = ThemeUtil.GetThemeFor( "Primary_BackgroundColor" )
			
		end
		
	elseif math.abs( V2 - V ) <= 0.25 then
		
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
		
		for a = 1, #Obj do
			
			ThemeUtil.ApplyBasicTheming( Obj[ a ], Subtype, DontInvert )
			
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
	
	for a, b in pairs( ObjBoundUpdates ) do
		
		for c, d in pairs( b ) do
			
			if type( d ) == "function" then
				
				coroutine.wrap( function( )
					
					local Ran, Error = pcall( d, a )
					
					if not Ran then
						
						warn( "ThemeUtil - Object Bound Update " .. a:GetFullName( ) .. " errored when updating all themes\n" .. Error .. "\n" .. debug.traceback( ) )
						
					end
					
				end )( )
				
			else
				
				local Ran, Error = pcall( function ( ) a[ c ] = ThemeUtil.GetThemeFor( type( d ) ~= "table" and d or unpack( d ) ) end )
				
				if not Ran then
					
					warn( "ThemeUtil - Object Bound Update " .. a:GetFullName( ) .. " errored when updating all themes for the property '" .. c .. "\n" .. Error .. "\n" .. debug.traceback( ) )
					
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

local CurDefault

function ThemeUtil.AddBaseTheme( Module )
	
	if ThemeUtil.BaseThemes[ Module.Name ] then
		
		warn( "ThemeUtil - Couldn't add " .. Module.Name .. " as a base theme with that name already exists" )
		
		return false
		
	end
	
	local BaseTheme = require( Module )
	
	local Inherit
	
	if BaseTheme.Inherits then
		
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

local Kids = script:GetChildren( )

for a = 1, #Kids do
	
	ThemeUtil.AddBaseTheme( Kids[ a ] )
	
end

local CustomThemes = game:GetService( "ReplicatedStorage" ):FindFirstChild( "CustomThemes" ) or Instance.new( "Folder" )

CustomThemes.Name = "CustomThemes"

CustomThemes.Parent = game:GetService( "ReplicatedStorage" )

Kids = CustomThemes:GetChildren( )

for a = 1, #Kids do
	
	ThemeUtil.AddBaseTheme( Kids[ a ] )
	
end

CustomThemes.ChildAdded:Connect( ThemeUtil.AddBaseTheme )

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