local LoaderModule = require( game:GetService( "ServerStorage" ):FindFirstChild( "LoaderModule" ) and game:GetService( "ServerStorage" ).LoaderModule:FindFirstChild( "MainModule" ) or 03593768376 )( "ThemeUtil" )

require( game:GetService( "ServerStorage" ):FindFirstChild( "MenuLib" ) and game:GetService( "ServerStorage" ).MenuLib:FindFirstChild( "MainModule" ) or 3717582194 ) -- MenuLib

require( script.ReplicatedStorage.ThemeUtil )

LoaderModule( script:WaitForChild( "StarterGui" ) )

LoaderModule( script:WaitForChild( "ReplicatedStorage" ) )

LoaderModule( script:WaitForChild( "MenuModules" ), game:GetService( "ServerStorage" ):WaitForChild( "MenuModules" ) )

local DataStore2 = require( 1936396537 )

DataStore2.Combine( "PartixelsVeryCoolMasterKey", "Theme1" )

local ThemeRemote = Instance.new( "RemoteEvent" )

ThemeRemote.Name = "ThemeRemote"

ThemeRemote.OnServerEvent:Connect( function ( Plr, Theme )
	
	DataStore2( "Theme1", Plr ):Set( Theme )
	
end )

ThemeRemote.Parent = game:GetService( "ReplicatedStorage" ).ThemeUtil

function HandlePlr( Plr )
	
	local Theme = DataStore2( "Theme1", Plr ):Get( )
	
	if Theme then
		
		ThemeRemote:FireClient( Plr, Theme )
		
	end
	
end

for _, Plr in ipairs( game:GetService( "Players" ):GetPlayers( ) ) do
	
	HandlePlr( Plr )
	
end

game.Players.PlayerAdded:Connect( HandlePlr )

return nil