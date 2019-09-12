local TweenService, ThemeUtil = game:GetService( "TweenService" ), require( game:GetService( "ReplicatedStorage" ):WaitForChild( "ThemeUtil" ):WaitForChild( "ThemeUtil" ) )

local EscapePatterns = {
	
	[ "(" ] = "%(",
		
	[ ")" ] = "%)",
	
	[ "." ] = "%.",
	
	[ "%" ] = "%%",
	
	[ "+" ] = "%+",
	
	[ "-" ] = "%-",
	
	[ "*" ] = "%*",
	
	[ "?" ] = "%?",
	
	[ "[" ] = "%[",
	
	[ "]" ] = "%]",
	
	[ "^" ] = "%^",
	
	[ "$" ] = "%$",
	
	[ "\0" ] = "%z"
	
}

return {
	
	RequiresRemote = true,
	
	GetCustomGui = function ( )
		
		return game:GetService( "Players" ).LocalPlayer:WaitForChild( "PlayerGui" ):WaitForChild( "ThemeGui" )
		
	end,
	
	CustomMenuFunc = function ( Remote, Gui )
		
		ThemeUtil.BindUpdate( Gui.Frame, { BackgroundColor3 = "Primary_BackgroundColor", BackgroundTransparency = "Primary_BackgroundTransparency" } )
		
		ThemeUtil.BindUpdate( Gui.Frame.Main, { ScrollBarImageColor3 = "Secondary_BackgroundColor", ScrollBarImageTransparency = "Secondary_BackgroundTransparency" } )
		
		ThemeUtil.BindUpdate( Gui.Frame.Search, { BackgroundColor3 = "Secondary_BackgroundColor", BackgroundTransparency = "Secondary_BackgroundTransparency", TextColor3 = "Primary_TextColor", TextTransparency = "Primary_TextTransparency", PlaceholderColor3 = "Secondary_TextColor" } )
		
		Gui.Frame.Main.UIListLayout:GetPropertyChangedSignal( "AbsoluteContentSize" ):Connect( function ( )
			
			Gui.Frame.Main.CanvasSize = UDim2.new( 0, 0, 0, Gui.Frame.Main.UIListLayout.AbsoluteContentSize.Y )
			
		end )
		
		local Invalid = true
		
		function Redraw( )
			
			for _, Obj in ipairs( Gui.Frame.Main:GetChildren( ) ) do
				
				if Obj:IsA( "Frame" ) or Obj:IsA( "TextButton" ) then Obj:Destroy( ) end
				
			end
			
			local Txt = Gui.Frame.Search.Text:lower( ):gsub( ".", EscapePatterns )
			
			local Categories = { }
			
			for a, b in pairs( ThemeUtil.BaseThemes ) do
				
				if a:lower( ):find( Txt ) then
					
					local Base = script.Base:Clone( )
					
					ThemeUtil.BindUpdate( Base.Title, { TextColor3 = "Primary_TextColor", BorderColor3 = ThemeUtil.CurrentBase == a and "Selection_Color3" or "Secondary_BackgroundColor", BackgroundColor3 = "Secondary_BackgroundColor", BackgroundTransparency = "Secondary_BackgroundTransparency" } )
					
					Base.Name = a
					
					Base.Title.Text = a
					
					Base.LayoutOrder = ThemeUtil.CurrentBase == a and 1 or 2
					
					Base.Example.Selected.BackgroundColor3 = ThemeUtil.CurrentBase == a and b.Positive_Color3 or b.Negative_Color3
					
					Base.Example.BackgroundColor3 = b.Primary_BackgroundColor
					
					Base.Example.BackgroundTransparency = b.Primary_BackgroundTransparency
					
					Base.MouseButton1Click:Connect( function ( )
						
						if ThemeUtil.CurrentBase == a then return end
						
						ThemeUtil.SetBaseTheme( a )
						
						Remote:FireServer( a )
						
						Invalid = true
						
					end )
					
					Base.Parent = Gui.Frame.Main
					
				end
				
			end
			
		end
		
		ThemeUtil.BaseThemeChanged.Event:Connect( function ( OldBase )
			
			if Gui.Frame.Visible then
				
				local Base = Gui.Frame.Main:FindFirstChild( OldBase )
				print( OldBase, ThemeUtil.CurrentBase, Base)
				if Base then
					
					Base.Example.Selected.BackgroundColor3 = ThemeUtil.BaseThemes[ OldBase ].Negative_Color3
					
					ThemeUtil.BindUpdate( Base.Title, { BorderColor3 = "Secondary_BackgroundColor" } )
					
				end
				
				Base = Gui.Frame.Main:FindFirstChild( ThemeUtil.CurrentBase )
				
				if Base then
					
					Base.Example.Selected.BackgroundColor3 = ThemeUtil.BaseThemes[ ThemeUtil.CurrentBase ].Positive_Color3
					
					ThemeUtil.BindUpdate( Base.Title, { BorderColor3 = "Selection_Color3" } )
					
				end
				
			else
				
				Invalid = true
				
			end
			
		end )
		
		ThemeUtil.BaseThemeAdded.Event:Connect( function ( )
			
			if Gui.Frame.Visible then
				
				Redraw( )
				
			else
				
				Invalid = true
				
			end
			
		end )
		
		Gui.Frame.Search:GetPropertyChangedSignal( "Text" ):Connect( function ( )
			
			if Gui.Frame.Visible then
				
				Redraw( )
				
			else
				
				Invalid = true
				
			end
			
		end )
		
		Remote.OnClientEvent:Connect( function ( NewBase )
			
			if NewBase and ThemeUtil.BaseThemes[ NewBase ] then
				
				ThemeUtil.SetBaseTheme( NewBase )
				
			end
			
		end )
		
		
		if Gui:FindFirstChild( "Toggle" ) then
			
			local function HandleTransparency( Obj, Transparency )
				
				Obj.BackgroundTransparency = Transparency
				
				if Transparency > 0.9 then
					
					ThemeUtil.BindUpdate( Obj, { TextColor3 = Gui.Open.Value and "Selection_Color3" or "Primary_BackgroundColor" } )
					
					Obj.TextStrokeTransparency = 0
					
				else
					
					ThemeUtil.BindUpdate( Obj, { TextColor3 = "Primary_TextColor" } )
					
					Obj.TextStrokeTransparency = 1
					
				end
				
			end
			
			ThemeUtil.BindUpdate( { Gui.Toggle, Gui.AltToggle }, { BackgroundColor3 = Gui.Open.Value and "Selection_Color3" or "Primary_BackgroundColor", TextTransparency = "Primary_TextTransparency", TextStrokeColor3 = "Primary_TextColor", Primary_BackgroundTransparency = HandleTransparency } )
			
			local function ToggleGui( )
				
				if Gui.Open.Value and _G.OpenPxlGui then
					
					_G.OpenPxlGui.Value = false
					
				end
				
				if Gui.Open.Value then
					
					_G.OpenPxlGui = Gui.Open
					
					if Invalid then Redraw( ) Invalid = nil end
					
					Gui.Frame.Visible = true
					
					TweenService:Create( Gui.Frame, TweenInfo.new( 0.5, Enum.EasingStyle.Sine ), { Position = UDim2.new( 0.15, 0, 0.43, 0 ), Size = UDim2.new( 0.2, 0, 0.4, 0 ) } ):Play( )
					
					ThemeUtil.BindUpdate( { Gui.Toggle, Gui.AltToggle }, { BackgroundColor3 = "Selection_Color3" } )
					
				else
					
					_G.OpenPxlGui = nil
					
					local Toggle = Gui.Toggle.Visible and Gui.Toggle or Gui.AltToggle
					
					local Tween = TweenService:Create( Gui.Frame, TweenInfo.new( 0.5, Enum.EasingStyle.Sine ), { Position = Toggle.Position, Size = Toggle.Size } )
					
					Tween.Completed:Connect( function ( State )
						
						if State == Enum.PlaybackState.Completed then
							
							Gui.Frame.Visible = false
							
						end
						
					end )
					
					Tween:Play( )
					
					ThemeUtil.BindUpdate( { Gui.Toggle, Gui.AltToggle }, { BackgroundColor3 = "Primary_BackgroundColor" } )
					
				end
				
			end
			
			Gui.Frame.Position = Gui.AltToggle.Position
			
			Gui.Frame.Size = Gui.AltToggle.Size
			
			Gui.Toggle.MouseButton1Click:Connect( function ( )
				
				Gui.Open.Value = not Gui.Open.Value
				
			end )
			
			Gui.AltToggle.MouseButton1Click:Connect( function ( )
				
				Gui.Open.Value = not Gui.Open.Value
				
			end )
			
			Gui.Open:GetPropertyChangedSignal( "Value" ):Connect( ToggleGui )
			
			if Gui.Open.Value then
				
				ToggleGui( )
				
			end
			
			local S2 = game:GetService( "ReplicatedStorage" ):WaitForChild( "S2", 5 )
			
			if S2 then
				
				Gui.AltToggle.Visible = false
				
				Gui.Toggle.Visible = true
				
				if not Gui.Open.Value then
					
					Gui.Frame.Position = Gui.Toggle.Position
					
					Gui.Frame.Size = Gui.Toggle.Size
					
				end
				
			end
			
		else
			
			Gui.Frame:GetPropertyChangedSignal( "Visible" ):Connect( function ( )
				
				if Gui.Frame.Visible and Invalid then
					
					Redraw( )
					
				end
				
			end )
			
			if Gui.Frame.Visible then
				
				Redraw( )
				
			end
			
		end
		
	end
	
}