local TweenService, ThemeUtil = game:GetService("TweenService"), require(game:GetService("ReplicatedStorage"):WaitForChild("ThemeUtil"):WaitForChild("ThemeUtil"))

local EscapePatterns = {
	["("] = "%(",
	[")"] = "%)",
	["."] = "%.",
	["%"] = "%%",
	["+"] = "%+",
	["-"] = "%-",
	["*"] = "%*",
	["?"] = "%?",
	["["] = "%[",
	["]"] = "%]",
	["^"] = "%^",
	["$"] = "%$",
	["\0"] = "%z",
}

return {
	RequiresRemote = true,
	ButtonText = "Themes",
	OpenSize = UDim2.new(0.3, 0, 0.6, 0),
	SetupGui = function(self)
		ThemeUtil.BindUpdate(self.Gui, {BackgroundColor3 = "Primary_BackgroundColor", BackgroundTransparency = "Primary_BackgroundTransparency"})
		
		self.Remote.OnClientEvent:Connect(function(NewBase)
			if NewBase and ThemeUtil.BaseThemes[NewBase] then
				ThemeUtil.SetBaseTheme(NewBase)
			end
		end)
	end,
	Tabs = {
		{
			Tab = script:WaitForChild("Gui"):WaitForChild("MainTab"),
			SetupTab = function(self)
				ThemeUtil.BindUpdate(self.Tab.ScrollingFrame, {ScrollBarImageColor3 = "Secondary_BackgroundColor", ScrollBarImageTransparency = "Secondary_BackgroundTransparency"})
				ThemeUtil.BindUpdate(self.Tab.Search, {BackgroundColor3 = "Secondary_BackgroundColor", BackgroundTransparency = "Secondary_BackgroundTransparency", TextColor3 = "Primary_TextColor", TextTransparency = "Primary_TextTransparency", PlaceholderColor3 = "Secondary_TextColor"})
				
				ThemeUtil.BaseThemeChanged.Event:Connect(function(OldBase)
					local Base = self.Tab.ScrollingFrame:FindFirstChild(OldBase)
					if Base then
						Base.Example.Selected.BackgroundColor3 = ThemeUtil.BaseThemes[OldBase].Negative_Color3
						ThemeUtil.BindUpdate(Base.Title, {BorderColor3 = "Secondary_BackgroundColor"})
					end
					
					Base = self.Tab.ScrollingFrame:FindFirstChild(ThemeUtil.CurrentBase)
					if Base then
						Base.Example.Selected.BackgroundColor3 = ThemeUtil.BaseThemes[ThemeUtil.CurrentBase].Positive_Color3
						ThemeUtil.BindUpdate(Base.Title, {BorderColor3 = "Selection_Color3"})
					end
				end)
				
				ThemeUtil.BaseThemeAdded.Event:Connect(function()
					self:Invalidate()
				end)
				
				self.Tab.ScrollingFrame.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function ()
					self.Tab.ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, self.Tab.ScrollingFrame.UIListLayout.AbsoluteContentSize.Y)
				end)
				
				self.Tab.Search:GetPropertyChangedSignal("Text"):Connect(function()
					self:Invalidate()
				end)
			end,
			Redraw = function(self)
				for _, Obj in ipairs(self.Tab.ScrollingFrame:GetChildren()) do
					if Obj:IsA("Frame") or Obj:IsA("TextButton") then Obj:Destroy() end
				end
				
				local Txt = self.Tab.Search.Text:lower():gsub(".", EscapePatterns)
				
				local Categories = {}
				
				for a, b in pairs(ThemeUtil.BaseThemes) do
					
					if a:lower():find(Txt) then
						
						local Base = script.Base:Clone()
						
						ThemeUtil.BindUpdate(Base.Title, {TextColor3 = "Primary_TextColor", BorderColor3 = ThemeUtil.CurrentBase == a and "Selection_Color3" or "Secondary_BackgroundColor", BackgroundColor3 = "Secondary_BackgroundColor", BackgroundTransparency = "Secondary_BackgroundTransparency"})
						
						Base.Name = a
						
						Base.Title.Text = a
						
						Base.LayoutOrder = ThemeUtil.CurrentBase == a and 1 or 2
						
						Base.Example.Selected.BackgroundColor3 = ThemeUtil.CurrentBase == a and b.Positive_Color3 or b.Negative_Color3
						
						Base.Example.BackgroundColor3 = b.Primary_BackgroundColor
						
						Base.Example.BackgroundTransparency = b.Primary_BackgroundTransparency
						
						Base.MouseButton1Click:Connect(function ()
							
							if ThemeUtil.CurrentBase == a then return end
							
							ThemeUtil.SetBaseTheme(a)
							
							self.Options.Remote:FireServer(a)
							
							self:Invalidate(false)
							
						end)
						
						Base.Parent = self.Tab.ScrollingFrame
					end
				end
			end
		},
	},
}