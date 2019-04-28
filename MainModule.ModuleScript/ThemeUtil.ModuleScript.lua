local ThemeUtil = { }

local BoundUpdates = { }

local ObjBoundUpdates = setmetatable( { }, { __newindex = function ( self, Key, Value )
	
	Key:GetPropertyChangedSignal( "Parent" ):Connect( function ( )
		
		if not Key.Parent then
			
			rawset( self, Key, nil )
			
		end
		
	end )
	
	rawset( self, Key, Value )
	
end } )

function ThemeUtil.BindUpdate( Obj, Properties, Keys )
	
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
				
				local Ran, Error = pcall( function ( ) Obj[ Properties[ a ] ] = ThemeUtil.GetThemeFor( unpack( Keys ) ) end )
				
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
			
			Obj.TextStrokeColor3 = ThemeUtil.GetThemeFor( "InvertedBackground" )
			
		else
			
			Obj.TextStrokeColor3 = ThemeUtil.GetThemeFor( "Background" )
			
		end
		
	elseif math.abs( V2 - V ) <= 0.25 then
		
		Obj.TextStrokeTransparency = 0
		
		if V2 > 0.5 then
			
			Obj.TextStrokeColor3 = ThemeUtil.GetThemeFor( "InvertedBackground" )
			
		else
			
			Obj.TextStrokeColor3 = ThemeUtil.GetThemeFor( "Background" )
			
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
	
	ThemeUtil.BindUpdate( Obj, "BackgroundColor3", Subtype .. "Background")
	
	if Obj:IsA( "TextButton" ) or Obj:IsA( "TextLabel" ) or Obj:IsA( "TextBox" ) then
		
		ThemeUtil.BindUpdate( Obj, "TextColor3", { Subtype .. "TextColor", ( Subtype ~= "Inverted" and "Inverted" or "" ) .. Subtype .. "Background" } )
		
	elseif Obj:IsA( "ImageButton" ) or Obj:IsA( "ImageLabel" ) then
		
		ThemeUtil.BindUpdate( Obj, "ImageColor3", { Subtype .. "ImageColor", ( Subtype ~= "Inverted" and "Inverted" or "" ) .. Subtype .. "Background" } )
		
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
				
				local Ran, Error = pcall( function ( ) a[ c ] = ThemeUtil.GetThemeFor( unpack( d ) ) end )
				
				if not Ran then
					
					warn( "ThemeUtil - Object Bound Update " .. a:GetFullName( ) .. " errored when updating all themes for the property '" .. c .. "\n" .. Error .. "\n" .. debug.traceback( ) )
					
				end
				
			end
			
		end
		
	end
	
end

ThemeUtil.BaseThemes = { Light = { } }

function ThemeUtil.AddBaseTheme( Name, Inherits )
	
	ThemeUtil.BaseThemes[ Name ] = setmetatable( { }, { __index = ThemeUtil.BaseThemes[ Inherits ] } )
	
end

ThemeUtil.AddBaseTheme( "OLEDLight", "Light" )

ThemeUtil.AddBaseTheme( "Dark", "Light" )

ThemeUtil.AddBaseTheme( "OLEDDark", "Dark" )

ThemeUtil.Theme = { }

function ThemeUtil.SetBaseTheme( NewBase )
	
	if not ThemeUtil.BaseThemes[ NewBase ] then warn( "ThemeUtil - " .. NewBase .. " is not a valid base theme\n" .. debug.traceback( ) ) end
	
	setmetatable( ThemeUtil.Theme, { __index = ThemeUtil.BaseThemes[ NewBase ] } )
	
	ThemeUtil.UpdateAll( )
	
end

ThemeUtil.SetBaseTheme( "Dark" )

function ThemeUtil.AddDefaultThemeFor( Key, Themes )
	
	if not Themes.Light then error( Key .. " cannot be added as a default theme because it didn't include a value for the Light theme" ) end
	
	for a, b in pairs( Themes ) do
		
		ThemeUtil.BaseThemes[ a ][ Key ] = b
		
	end
	
	ThemeUtil.UpdateAll( )
	
end

ThemeUtil.AddDefaultThemeFor( "Background", { Light = Color3.fromRGB( 255, 255, 255 ), Dark = Color3.fromRGB( 46, 46, 46 ), OLEDDark = Color3.fromRGB( 0, 0, 0 ) } )

ThemeUtil.AddDefaultThemeFor( "Background_Transparency", { Light = 0 } )

ThemeUtil.AddDefaultThemeFor( "InvertedBackground", { Light = Color3.fromRGB( 46, 46, 46 ), Dark = Color3.fromRGB( 255, 255, 255 ), OLEDLight = Color3.fromRGB( 0, 0, 0 ) } )

ThemeUtil.AddDefaultThemeFor( "SecondaryBackground", { Light = Color3.fromRGB( 180, 180, 180 ), Dark = Color3.fromRGB( 77, 77, 77 ), OLEDLight = Color3.fromRGB( 255, 255, 255 ), OLEDDark = Color3.fromRGB( 0, 0, 0 ) } )

ThemeUtil.AddDefaultThemeFor( "TextColor", { Light = Color3.fromRGB( 46, 46, 46 ), Dark = Color3.fromRGB( 255, 255, 255 ), OLEDLight = Color3.fromRGB( 0, 0, 0 ) } )

ThemeUtil.AddDefaultThemeFor( "InvertedTextColor", { Light = Color3.fromRGB( 255, 255, 255 ), Dark = Color3.fromRGB( 46, 46, 46 ), OLEDLight = Color3.fromRGB( 255, 255, 255 ), OLEDDark = Color3.fromRGB( 0, 0, 0 ) } )

ThemeUtil.AddDefaultThemeFor( "SecondaryTextColor", { Light = Color3.fromRGB( 100, 100, 100 ), Dark = Color3.fromRGB( 170, 170, 170 ), OLEDLight = Color3.fromRGB( 70, 70, 70 ), OLEDDark = Color3.fromRGB( 200, 200, 200 ) } )

ThemeUtil.AddDefaultThemeFor( "PositiveColor", { Light = Color3.fromRGB( 100, 180, 100 ), Dark = Color3.fromRGB( 0, 150, 0 ) } )

ThemeUtil.AddDefaultThemeFor( "NegativeColor", { Light = Color3.fromRGB( 255, 0, 0 ) } )

ThemeUtil.AddDefaultThemeFor( "ProgressColor", { Light = Color3.fromRGB( 255, 255, 50 ) } )

ThemeUtil.AddDefaultThemeFor( "SelectionColor", { Light = Color3.fromRGB( 105, 145, 255 ), Dark = Color3.fromRGB( 0, 100, 255 ) } )

if false then
	
	spawn( function ( )
		
		while wait( ) do
			
			local H, S, V = tick( ) * 10 % 255, 127.5 + math.sin( tick( ) * 0.3 ) * 127.5, 127.5 + math.sin( tick( ) * 0.5 + 10 ) * 127.5
			
			ThemeUtil.UpdateThemeFor( "Background", Color3.fromHSV( H / 255, S / 255, V / 255 ) )
			
			ThemeUtil.UpdateThemeFor( "SecondaryBackground", Color3.fromHSV( H / 255, S / 255, ( V > 122.5 and ( V - 75 ) or ( V + 36 ) ) / 255 ) )
			
			if V / 255 > 0.75 then
				
				ThemeUtil.UpdateThemeFor( "InvertedBackground", Color3.fromRGB( H / 255, S / 255, ( V - 255 ) / 255 ) )
				
				ThemeUtil.UpdateThemeFor( "TextColor", Color3.fromRGB( 46, 46, 46 ) )
				
			else
				
				ThemeUtil.UpdateThemeFor( "InvertedBackground", Color3.fromRGB( H / 255, S / 255, ( V - 255 ) / 255 ) )
				
				ThemeUtil.UpdateThemeFor( "TextColor", Color3.fromRGB( 255, 255, 255 ) )
				
			end
			
		end
		
	end )
	
end

return ThemeUtil