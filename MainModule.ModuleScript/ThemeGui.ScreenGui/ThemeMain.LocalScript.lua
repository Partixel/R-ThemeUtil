local ThemeUtil = require( game:GetService( "ReplicatedStorage" ):WaitForChild( "ThemeUtil" ) )

local TweenService = game:GetService( "TweenService" )

local SaveTheme = game:GetService( "ReplicatedStorage" ):WaitForChild( "SaveTheme" )

ThemeUtil.BindUpdate( script.Parent.ThemeFrame, { BackgroundColor3 = "Primary_BackgroundColor", BackgroundTransparency = "Primary_BackgroundTransparency" } )

ThemeUtil.BindUpdate( script.Parent.ThemeFrame.Main, { ScrollBarImageColor3 = "Secondary_BackgroundColor", ScrollBarImageTransparency = "Secondary_BackgroundTransparency" } )

ThemeUtil.BindUpdate( { script.Parent.ThemeFrame.Search, script.Parent.ThemeFrame.Bar }, { BackgroundColor3 = "Secondary_BackgroundColor", BackgroundTransparency = "Secondary_BackgroundTransparency" } )

ThemeUtil.BindUpdate( script.Parent.ThemeFrame.Search, { TextColor3 = "Primary_TextColor", TextTransparency = "Primary_TextTransparency", PlaceholderColor3 = "Secondary_TextColor" } )

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
	
	local Old = script.Parent.ThemeFrame.Main:GetChildren( )
	
	for a = 1, #Old do
		
		if Old[ a ]:IsA( "Frame" ) or Old[ a ]:IsA( "TextButton" ) then Old[ a ]:Destroy( ) end
		
	end
	
	local Txt = script.Parent.ThemeFrame.Search.Text:lower( ):gsub( ".", EscapePatterns )
	
	local Categories = { }
	
	for a, b in pairs( ThemeUtil.BaseThemes ) do
		
		if a:lower( ):find( Txt ) then
			
			local Base = script.Parent.ThemeFrame.Base:Clone( )
			
			ThemeUtil.BindUpdate( Base.Title, { TextColor3 = "Primary_TextColor", BorderColor3 = "Secondary_BackgroundColor", BackgroundColor3 = "Secondary_BackgroundColor", BackgroundTransparency = "Secondary_BackgroundTransparency" } )
			
			Base.Visible = true
			
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
					
				end
				
				Base.Example.Selected.BackgroundColor3 = b.Positive_Color3
				
				ThemeUtil.SetBaseTheme( a )
				
				SaveTheme:FireServer( a )
				
				Invalid = true
				
			end )
			
			Base.Parent = script.Parent.ThemeFrame.Main
			
		end
		
	end
	
end

ThemeUtil.BaseThemeChanged.Event:Connect( function ( NewBase )
	
	if script.Parent.Open.Value then
		
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
	
	if script.Parent.Open.Value then
		
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

local SavedBase = game:GetService( "ReplicatedStorage" ):WaitForChild( "GetTheme" ):InvokeServer( )

if SavedBase and ThemeUtil.BaseThemes[ SavedBase ] then
	
	ThemeUtil.SetBaseTheme( SavedBase )
	
end

if script.Parent:FindFirstChild( "Toggle" ) then
	
	function UpdateColor( )
		
		script.Parent.Toggle.BackgroundColor3 = script.Parent.Open.Value and ThemeUtil.GetThemeFor( "Positive_Color3" ) or ThemeUtil.GetThemeFor( "Primary_BackgroundColor" )
		
		script.Parent.AltToggle.BackgroundColor3 = script.Parent.Toggle.BackgroundColor3
		
		local Transparency = ThemeUtil.GetThemeFor( "Primary_BackgroundTransparency" )
		
		script.Parent.Toggle.BackgroundTransparency = Transparency
		
		script.Parent.AltToggle.BackgroundTransparency = Transparency
		
		if Transparency > 0.9 then
			
			script.Parent.Toggle.TextStrokeColor3 = ThemeUtil.GetThemeFor( "Primary_TextColor" )
			
			script.Parent.Toggle.TextColor3 = script.Parent.Open.Value and ThemeUtil.GetThemeFor( "Positive_Color3" ) or ThemeUtil.GetThemeFor( "Primary_BackgroundColor" )
			
			script.Parent.Toggle.TextStrokeTransparency = 0
			
			script.Parent.AltToggle.TextStrokeColor3 = script.Parent.Toggle.TextStrokeColor3
			
			script.Parent.AltToggle.TextColor3 = script.Parent.Toggle.TextColor3
			
			script.Parent.AltToggle.TextStrokeTransparency = 0
			
		else
			
			script.Parent.Toggle.TextColor3 = ThemeUtil.GetThemeFor( "Primary_TextColor" )
			
			script.Parent.Toggle.TextStrokeTransparency = 1
			
			script.Parent.AltToggle.TextColor3 = script.Parent.Toggle.TextColor3
			
			script.Parent.AltToggle.TextStrokeTransparency = 1
			
		end
		
	end
	
	function ToggleGui( )
		
		if script.Parent.Open.Value and script.Parent.Parent:FindFirstChild( "KeybindGui" ) and script.Parent.Parent.KeybindGui.Open.Value then
			
			script.Parent.Parent.KeybindGui.Open.Value = false
			
		end
		
		if script.Parent.Open.Value then
			
			if Invalid then Redraw( ) Invalid = nil end
			
			script.Parent.ThemeFrame.Visible = true
			
			TweenService:Create( script.Parent.ThemeFrame, TweenInfo.new( 0.5, Enum.EasingStyle.Sine ), { Position = UDim2.new( 0.15, 0, 0.43, 0 ), Size = UDim2.new( 0.2, 0, 0.4, 0 ) } ):Play( )
			
			UpdateColor( )
			
		else
			
			local Toggle = script.Parent.Toggle.Visible and script.Parent.Toggle or script.Parent.AltToggle
			
			local Tween = TweenService:Create( script.Parent.ThemeFrame, TweenInfo.new( 0.5, Enum.EasingStyle.Sine ), { Position = Toggle.Position, Size = Toggle.Size } )
			
			Tween.Completed:Connect( function ( State )
				
				if State == Enum.PlaybackState.Completed then
					
					script.Parent.ThemeFrame.Visible = false
					
				end
				
			end )
			
			Tween:Play( )
			
			UpdateColor( )
			
		end
		
	end
	
	ThemeUtil.BindUpdate( script.Parent.Toggle, { BackgroundColor3 = UpdateColor, TextTransparency = "Primary_TextTransparency" } )
	
	ThemeUtil.BindUpdate( script.Parent.AltToggle, { TextTransparency = "Primary_TextTransparency" } )
	
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
	
	local Core = game:GetService( "ReplicatedStorage" ):WaitForChild( "Core", 5 )
	
	if Core then
		
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