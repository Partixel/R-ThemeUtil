local Players = game:GetService( "Players" )

require( script.ThemeUtil )

script.ThemeUtil.Parent = game:GetService( "ReplicatedStorage" )

if not game:GetService( "StarterGui" ):FindFirstChild( "ThemeGui" ) then
	
	local Gui = script.ThemeGui
	
	Gui.Parent = game:GetService( "StarterGui" )
	
	local Plrs = game:GetService( "Players" ):GetPlayers( )
	
	for a = 1, #Plrs do
		
		if Plrs[ a ]:FindFirstChild( "PlayerGui" ) and Plrs[ a ].Character and not Plrs[ a ].PlayerGui:FindFirstChild( Gui.Name ) then
			
			Gui:Clone( ).Parent = Plrs[ a ].PlayerGui
			
		end
		
	end
	
end

local DataStore2 = require(1936396537)

DataStore2.Combine("PartixelsVeryCoolMasterKey", "Theme1")

local GetTheme = Instance.new( "RemoteFunction" )

GetTheme.Name = "GetTheme"

function GetTheme.OnServerInvoke( Plr )
	
	return DataStore2( "Theme1", Plr ):Get( )
	
end

GetTheme.Parent = game:GetService( "ReplicatedStorage" )

local SaveTheme = Instance.new( "RemoteEvent" )

SaveTheme.Name = "SaveTheme"

SaveTheme.OnServerEvent:Connect( function ( Plr, Theme )
	
	DataStore2( "Theme1", Plr ):Set( Theme )
	
end )

SaveTheme.Parent = game:GetService( "ReplicatedStorage" )

return nil