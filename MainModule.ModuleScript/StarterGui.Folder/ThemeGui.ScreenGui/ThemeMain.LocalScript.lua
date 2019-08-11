local ThemeUtil = require( game:GetService( "ReplicatedStorage" ):WaitForChild( "ThemeUtil" ):WaitForChild( "ThemeUtil" ) )

local TweenService = game:GetService( "TweenService" )

local ThemeRemote = game:GetService( "ReplicatedStorage" ):WaitForChild( "ThemeUtil" ):WaitForChild( "ThemeRemote" )

ThemeUtil.BindUpdate( script.Parent.ThemeFrame, { BackgroundColor3 = "Primary_BackgroundColor", BackgroundTransparency = "Primary_BackgroundTransparency" } )

ThemeUtil.BindUpdate( script.Parent.ThemeFrame.Main, { ScrollBarImageColor3 = "Secondary_BackgroundColor", ScrollBarImageTransparency = "Secondary_BackgroundTransparency" } )

ThemeUtil.BindUpdate( script.Parent.ThemeFrame.Search, { BackgroundColor3 = "Secondary_BackgroundColor", BackgroundTransparency = "Secondary_BackgroundTransparency", TextColor3 = "Primary_TextColor", TextTransparency = "Primary_TextTransparency", PlaceholderColor3 = "Secondary_TextColor" } )

script.Parent.ThemeFrame.Main.UIListLayout:GetPropertyChangedSignal( "AbsoluteContentSize" ):Connect( function ( )
	
	script.Parent.ThemeFrame.Main.CanvasSize = UDim2.new( 0, 0, 0, script.Parent.ThemeFrame.Main.UIListLayout.AbsoluteContentSize.Y )
	
end )

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

local Invalid = true

function Redraw( )
	
	for _, Obj in ipairs( script.Parent.ThemeFrame.Main:GetChildren( ) ) do
		
		if Obj:IsA( "Frame" ) or Obj:IsA( "TextButton" ) then Obj:Destroy( ) end
		
	end
	
	local Txt = script.Parent.ThemeFrame.Search.Text:lower( ):gsub( ".", EscapePatterns )
	
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
				
				local CurBase = script.Parent.ThemeFrame.Main:FindFirstChild( ThemeUtil.CurrentBase )
				
				if CurBase then
					
					CurBase.Example.Selected.BackgroundColor3 = ThemeUtil.BaseThemes[ ThemeUtil.CurrentBase ].Negative_Color3
					
					ThemeUtil.BindUpdate( CurBase.Title, { BorderColor3 = "Secondary_BackgroundColor" } )
					
				end
				
				Base.Example.Selected.BackgroundColor3 = b.Positive_Color3
				
				ThemeUtil.BindUpdate( Base.Title, { BorderColor3 = "Selection_Color3" } )
				
				ThemeUtil.SetBaseTheme( a )
				
				ThemeRemote:FireServer( a )
				
				Invalid = true
				
			end )
			
			Base.Parent = script.Parent.ThemeFrame.Main
			
		end
		
	end
	
end

ThemeUtil.BaseThemeChanged.Event:Connect( function ( NewBase )
	
	if script.Parent.ThemeFrame.Visible then
		
		local Base = script.Parent.ThemeFrame.Main:FindFirstChild( ThemeUtil.CurrentBase )
		
		if Base then
			
			Base.Example.Selected.BackgroundColor3 = ThemeUtil.BaseThemes[ ThemeUtil.CurrentBase ].Negative_Color3
			
		end
		
		Base = script.Parent.ThemeFrame.Main:FindFirstChild( NewBase )
		
		if Base then
			
			Base.Example.Selected.BackgroundColor3 = ThemeUtil.BaseThemes[ NewBase ].Positive_Color3
			
		end
		
	else
		
		Invalid = true
		
	end
	
end )

ThemeUtil.BaseThemeAdded.Event:Connect( function ( )
	
	if script.Parent.ThemeFrame.Visible then
		
		Redraw( )
		
	else
		
		Invalid = true
		
	end
	
end )

script.Parent.ThemeFrame.Search:GetPropertyChangedSignal( "Text" ):Connect( function ( )
	
	if script.Parent.ThemeFrame.Visible then
		
		Redraw( )
		
	else
		
		Invalid = true
		
	end
	
end )

ThemeRemote.OnClientEvent:Connect( function ( NewBase )
	
	if NewBase and ThemeUtil.BaseThemes[ NewBase ] then
		
		ThemeUtil.SetBaseTheme( NewBase )
		
	end
	
end )


if script.Parent:FindFirstChild( "Toggle" ) then
	
	local function HandleTransparency( Obj, Transparency )
		
		Obj.BackgroundTransparency = Transparency
		
		if Transparency > 0.9 then
			
			ThemeUtil.BindUpdate( Obj, { TextColor3 = script.Parent.Open.Value and "Selection_Color3" or "Primary_BackgroundColor" } )
			
			Obj.TextStrokeTransparency = 0
			
		else
			
			ThemeUtil.BindUpdate( Obj, { TextColor3 = "Primary_TextColor" } )
			
			Obj.TextStrokeTransparency = 1
			
		end
		
	end
	
	ThemeUtil.BindUpdate( { script.Parent.Toggle, script.Parent.AltToggle }, { BackgroundColor3 = script.Parent.Open.Value and "Selection_Color3" or "Primary_BackgroundColor", TextTransparency = "Primary_TextTransparency", TextStrokeColor3 = "Primary_TextColor", Primary_BackgroundTransparency = HandleTransparency } )
	
	function ToggleGui( )
		
		if script.Parent.Open.Value and _G.OpenPxlGui then
			
			_G.OpenPxlGui.Value = false
			
		end
		
		if script.Parent.Open.Value then
			
			_G.OpenPxlGui = script.Parent.Open
			
			if Invalid then Redraw( ) Invalid = nil end
			
			script.Parent.ThemeFrame.Visible = true
			
			TweenService:Create( script.Parent.ThemeFrame, TweenInfo.new( 0.5, Enum.EasingStyle.Sine ), { Position = UDim2.new( 0.15, 0, 0.43, 0 ), Size = UDim2.new( 0.2, 0, 0.4, 0 ) } ):Play( )
			
			ThemeUtil.BindUpdate( { script.Parent.Toggle, script.Parent.AltToggle }, { BackgroundColor3 = "Selection_Color3" } )
			
		else
			
			_G.OpenPxlGui = nil
			
			local Toggle = script.Parent.Toggle.Visible and script.Parent.Toggle or script.Parent.AltToggle
			
			local Tween = TweenService:Create( script.Parent.ThemeFrame, TweenInfo.new( 0.5, Enum.EasingStyle.Sine ), { Position = Toggle.Position, Size = Toggle.Size } )
			
			Tween.Completed:Connect( function ( State )
				
				if State == Enum.PlaybackState.Completed then
					
					script.Parent.ThemeFrame.Visible = false
					
				end
				
			end )
			
			Tween:Play( )
			
			ThemeUtil.BindUpdate( { script.Parent.Toggle, script.Parent.AltToggle }, { BackgroundColor3 = "Primary_BackgroundColor" } )
			
		end
		
	end
	
	script.Parent.ThemeFrame.Position = script.Parent.AltToggle.Position
	
	script.Parent.ThemeFrame.Size = script.Parent.AltToggle.Size
	
	script.Parent.Toggle.MouseButton1Click:Connect( function ( )
		
		script.Parent.Open.Value = not script.Parent.Open.Value
		
	end )
	
	script.Parent.AltToggle.MouseButton1Click:Connect( function ( )
		
		script.Parent.Open.Value = not script.Parent.Open.Value
		
	end )
	
	script.Parent.Open:GetPropertyChangedSignal( "Value" ):Connect( ToggleGui )
	
	if script.Parent.Open.Value then
		
		ToggleGui( )
		
	end
	
	local S2 = game:GetService( "ReplicatedStorage" ):WaitForChild( "S2", 5 )
	
	if S2 then
		
		script.Parent.AltToggle.Visible = false
		
		script.Parent.Toggle.Visible = true
		
		if not script.Parent.Open.Value then
			
			script.Parent.ThemeFrame.Position = script.Parent.Toggle.Position
			
			script.Parent.ThemeFrame.Size = script.Parent.Toggle.Size
			
		end
		
	end
	
else
	
	script.Parent.ThemeFrame.Visible = true
	
	script.Parent.ThemeFrame:GetPropertyChangedSignal( "Visible" ):Connect( function ( )
		
		if script.Parent.ThemeFrame.Visible and Invalid then
			
			Redraw( )
			
		end
		
	end )
	
	Redraw( )
	
end