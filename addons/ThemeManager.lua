local httpService = game:GetService('HttpService')
local ThemeManager = {} do
	ThemeManager.Folder = 'LinoriaLibSettings'
	-- if not isfolder(ThemeManager.Folder) then makefolder(ThemeManager.Folder) end

	ThemeManager.Library = nil
	ThemeManager.BuiltInThemes = {
		['Default'] 		= { 1, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1c1c1c","AccentColor":"0055ff","BackgroundColor":"141414","OutlineColor":"323232"}') },
		['BBot'] 			= { 2, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1e1e1e","AccentColor":"7e48a3","BackgroundColor":"232323","OutlineColor":"141414"}') },
		['Fatality']		= { 3, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1e1842","AccentColor":"c50754","BackgroundColor":"191335","OutlineColor":"3c355d"}') },
		['Jester'] 			= { 4, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"242424","AccentColor":"db4467","BackgroundColor":"1c1c1c","OutlineColor":"373737"}') },
		['Mint'] 			= { 5, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"242424","AccentColor":"3db488","BackgroundColor":"1c1c1c","OutlineColor":"373737"}') },
		['Tokyo Night'] 	= { 6, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"191925","AccentColor":"6759b3","BackgroundColor":"16161f","OutlineColor":"323232"}') },
		['Ubuntu'] 			= { 7, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"3e3e3e","AccentColor":"e2581e","BackgroundColor":"323232","OutlineColor":"191919"}') },
		['Quartz'] 			= { 8, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"232330","AccentColor":"426e87","BackgroundColor":"1d1b26","OutlineColor":"27232f"}') },
	}

	function ThemeManager:ApplyTheme(theme)
		local customThemeData = self:GetCustomTheme(theme)
		local data = customThemeData or self.BuiltInThemes[theme]

		if not data then return end

		-- custom themes are just regular dictionaries instead of an array with { index, dictionary }

		local scheme = data[2]
		for idx, col in next, customThemeData or scheme do
			self.Library[idx] = Color3.fromHex(col)
			
			if Options[idx] then
				Options[idx]:SetValueRGB(Color3.fromHex(col))
			end
		end

		self:ThemeUpdate()
	end

	function ThemeManager:ThemeUpdate()
		-- This allows us to force apply themes without loading the themes tab :)
		local options = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }
		for i, field in next, options do
			if Options and Options[field] then
				self.Library[field] = Options[field].Value
			end
		end

		self.Library.AccentColorDark = self.Library:GetDarkerColor(self.Library.AccentColor);
		self.Library:UpdateColorsUsingRegistry()
	end

	function ThemeManager:LoadDefault()		
		local theme = 'Default'
		local content = isfile(self.Folder .. '/themes/default.txt') and readfile(self.Folder .. '/themes/default.txt')

		local isDefault = true
		if content then
			if self.BuiltInThemes[content] then
				theme = content
			elseif self:GetCustomTheme(content) then
				theme = content
				isDefault = false;
			end
		elseif self.BuiltInThemes[self.DefaultTheme] then
		 	theme = self.DefaultTheme
		end

		if isDefault then
			Options.ThemeManager_ThemeList:SetValue(theme)
		else
			self:ApplyTheme(theme)
		end
	end

	function ThemeManager:SaveDefault(theme)
		writefile(self.Folder .. '/themes/default.txt', theme)
	end

	function ThemeManager:CreateThemeManager(tabbox)
		-- ===== Tab 1: Themes =====
		local themesTab = tabbox:AddTab('Themes')

		-- Color pickers (UI theme colors)
		themesTab:AddLabel('Background color'):AddColorPicker('BackgroundColor', { Default = self.Library.BackgroundColor })
		themesTab:AddLabel('Main color'):AddColorPicker('MainColor', { Default = self.Library.MainColor })
		themesTab:AddLabel('Accent color'):AddColorPicker('AccentColor', { Default = self.Library.AccentColor })
		themesTab:AddLabel('Outline color'):AddColorPicker('OutlineColor', { Default = self.Library.OutlineColor })
		themesTab:AddLabel('Font color'):AddColorPicker('FontColor', { Default = self.Library.FontColor })

		-- Built-in theme list
		local ThemesArray = {}
		for Name in next, self.BuiltInThemes do
			table.insert(ThemesArray, Name)
		end
		table.sort(ThemesArray, function(a, b) return self.BuiltInThemes[a][1] < self.BuiltInThemes[b][1] end)

		themesTab:AddDivider()
		themesTab:AddDropdown('ThemeManager_ThemeList', { Text = 'Theme list', Values = ThemesArray, Default = 1 })

		Options.ThemeManager_ThemeList:OnChanged(function()
			self:ApplyTheme(Options.ThemeManager_ThemeList.Value)
		end)

		themesTab:AddDivider()

		-- Custom theme name input + custom theme list
		themesTab:AddInput('ThemeManager_CustomThemeName', { Text = 'Custom theme name' })
		themesTab:AddDropdown('ThemeManager_CustomThemeList', { Text = 'Custom themes', Values = self:ReloadCustomThemes(), AllowNull = true, Default = 1 })

		themesTab:AddDivider()

		-- Save custom theme (full width)
		themesTab:AddButton('Save theme', function()
			self:SaveCustomTheme(Options.ThemeManager_CustomThemeName.Value)
			Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
			Options.ThemeManager_CustomThemeList:SetValue(nil)
		end)

		-- [                    Load theme                     ]
		themesTab:AddButton('Load theme', function()
			self:ApplyTheme(Options.ThemeManager_CustomThemeList.Value)
		end)

		-- [Overwrite theme] [Delete theme]
		themesTab:AddButton('Overwrite theme', function()
			local name = Options.ThemeManager_CustomThemeList.Value
			if not name or name == '' then
				return self.Library:Notify('No custom theme selected', 2)
			end
			self:SaveCustomTheme(name)
			self.Library:Notify(string.format('Overwrote theme %q', name))
		end):AddButton('Delete theme', function()
			local name = Options.ThemeManager_CustomThemeList.Value
			if not name or name == '' then
				return self.Library:Notify('No custom theme selected', 2)
			end
			local path = self.Folder .. '/themes/' .. name
			if isfile(path) then
				delfile(path)
				self.Library:Notify(string.format('Deleted theme %q', name))
			end
			Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
			Options.ThemeManager_CustomThemeList:SetValue(nil)
		end)

		-- [Set Default] [Reset default]
		themesTab:AddButton('Set default', function()
			local customVal = Options.ThemeManager_CustomThemeList.Value
			local builtinVal = Options.ThemeManager_ThemeList.Value
			local name = (customVal and customVal ~= '') and customVal or builtinVal
			if not name or name == '' then
				return self.Library:Notify('No theme selected', 2)
			end
			self:SaveDefault(name)
			self.Library:Notify(string.format('Set default theme to %q', name))
		end):AddButton('Reset default', function()
			local path = self.Folder .. '/themes/default.txt'
			if isfile(path) then delfile(path) end
			self.Library:Notify('Removed default theme')
		end)

		-- [                      Refresh                      ]
		themesTab:AddButton('Refresh', function()
			Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
			Options.ThemeManager_CustomThemeList:SetValue(nil)
		end)

		ThemeManager:LoadDefault()

		local function UpdateTheme()
			self:ThemeUpdate()
		end

		Options.BackgroundColor:OnChanged(UpdateTheme)
		Options.MainColor:OnChanged(UpdateTheme)
		Options.AccentColor:OnChanged(UpdateTheme)
		Options.OutlineColor:OnChanged(UpdateTheme)
		Options.FontColor:OnChanged(UpdateTheme)

		-- ===== Tab 2: Background =====
		local bgTab = tabbox:AddTab('Background')

		bgTab:AddLabel('Background color'):AddColorPicker('BG_Color', {
			Default = Color3.fromRGB(0, 0, 0),
		})

		bgTab:AddSlider('BG_Transparency', {
			Text     = 'Transparency',
			Default  = 1,
			Min      = 0.01,
			Max      = 1,
			Rounding = 2,
			Callback = function(val)
				ThemeManager:UpdateBackground()
			end,
		}):AddSlider('BG_Blur', {
			Text     = 'Blur',
			Default  = 0,
			Min      = 0,
			Max      = 50,
			Rounding = 0,
			Callback = function(val)
				ThemeManager:UpdateBackground()
			end,
		})

		bgTab:AddSlider('BG_Contrast', {
			Text     = 'Contrast',
			Default  = 0,
			Min      = -10,
			Max      = 10,
			Rounding = 1,
			Callback = function(val)
				ThemeManager:UpdateBackground()
			end,
		}):AddSlider('BG_Saturation', {
			Text     = 'Saturation',
			Default  = 0,
			Min      = -10,
			Max      = 10,
			Rounding = 1,
			Callback = function(val)
				ThemeManager:UpdateBackground()
			end,
		})

		bgTab:AddSlider('BG_Brightness', {
			Text     = 'Brightness',
			Default  = 0,
			Min      = -1,
			Max      = 1,
			Rounding = 1,
			Callback = function(val)
				ThemeManager:UpdateBackground()
			end,
		})

		-- Background instances
		local Lighting = game:GetService('Lighting')

		-- BlurEffect
		if not Lighting:FindFirstChild('ThemeManager_Blur') then
			local blur = Instance.new('BlurEffect')
			blur.Name  = 'ThemeManager_Blur'
			blur.Size  = 0
			blur.Parent = Lighting
		end

		if not Lighting:FindFirstChild('ThemeManager_CC') then
			local cc = Instance.new('ColorCorrectionEffect')
			cc.Name   = 'ThemeManager_CC'
			cc.Parent = Lighting
		end

		if not self._BgFrame then
			local RunService = game:GetService('RunService')
			local bg = Instance.new('Frame')
			bg.Name              = 'ThemeManager_BgFrame'
			bg.Size              = UDim2.new(1, 0, 1, 0)
			bg.Position          = UDim2.new(0, 0, 0, 0)
			bg.BackgroundColor3  = Options.BG_Color and Options.BG_Color.Value or Color3.new(0,0,0)
			bg.BackgroundTransparency = 1
			bg.BorderSizePixel   = 0
			bg.ZIndex            = -1
			bg.Parent            = self.Library.ScreenGui
			self._BgFrame = bg
		end

		Options.BG_Color:OnChanged(function()
			ThemeManager:UpdateBackground()
		end)

		function ThemeManager:UpdateBackground()
			local Lighting2 = game:GetService('Lighting')
			local blur = Lighting2:FindFirstChild('ThemeManager_Blur')
			local cc   = Lighting2:FindFirstChild('ThemeManager_CC')

			if blur then
				blur.Size = Options.BG_Blur and Options.BG_Blur.Value or 0
			end
			if cc then
				cc.Contrast    = Options.BG_Contrast   and Options.BG_Contrast.Value   or 0
				cc.Saturation  = Options.BG_Saturation and Options.BG_Saturation.Value or 0
				cc.Brightness  = Options.BG_Brightness and Options.BG_Brightness.Value or 0
			end

			if self._BgFrame then
				local t = Options.BG_Transparency and Options.BG_Transparency.Value or 1
				self._BgFrame.BackgroundTransparency = t
				self._BgFrame.BackgroundColor3 = Options.BG_Color and Options.BG_Color.Value or Color3.new(0,0,0)
			end
		end
	end

	function ThemeManager:GetCustomTheme(file)
		local path = self.Folder .. '/themes/' .. file
		if not isfile(path) then
			return nil
		end

		local data = readfile(path)
		local success, decoded = pcall(httpService.JSONDecode, httpService, data)
		
		if not success then
			return nil
		end

		return decoded
	end

	function ThemeManager:SaveCustomTheme(file)
		if file:gsub(' ', '') == '' then
			return self.Library:Notify('Invalid file name for theme (empty)', 3)
		end

		local theme = {}
		local fields = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }

		for _, field in next, fields do
			theme[field] = Options[field].Value:ToHex()
		end

		writefile(self.Folder .. '/themes/' .. file .. '.json', httpService:JSONEncode(theme))
	end

	function ThemeManager:ReloadCustomThemes()
		local list = listfiles(self.Folder .. '/themes')

		local out = {}
		for i = 1, #list do
			local file = list[i]
			if file:sub(-5) == '.json' then
				-- i hate this but it has to be done ...

				local pos = file:find('.json', 1, true)
				local char = file:sub(pos, pos)

				while char ~= '/' and char ~= '\\' and char ~= '' do
					pos = pos - 1
					char = file:sub(pos, pos)
				end

				if char == '/' or char == '\\' then
					table.insert(out, file:sub(pos + 1))
				end
			end
		end

		return out
	end

	function ThemeManager:SetLibrary(lib)
		self.Library = lib
	end

	function ThemeManager:BuildFolderTree()
		local paths = {}

		local parts = self.Folder:split('/')
		for idx = 1, #parts do
			paths[#paths + 1] = table.concat(parts, '/', 1, idx)
		end

		table.insert(paths, self.Folder .. '/themes')
		table.insert(paths, self.Folder .. '/settings')

		for i = 1, #paths do
			local str = paths[i]
			if not isfolder(str) then
				makefolder(str)
			end
		end
	end

	function ThemeManager:SetFolder(folder)
		self.Folder = folder
		self:BuildFolderTree()
	end

	function ThemeManager:CreateTabbox(tab)
		assert(self.Library, 'Must set ThemeManager.Library first!')
		return tab:AddLeftTabbox('Themes')
	end

	function ThemeManager:CreateGroupBox(tab)
		return self:CreateTabbox(tab)
	end

	function ThemeManager:ApplyToTab(tab)
		assert(self.Library, 'Must set ThemeManager.Library first!')
		local tabbox = self:CreateTabbox(tab)
		self:CreateThemeManager(tabbox)
	end

	function ThemeManager:ApplyToGroupbox(groupbox)
		assert(self.Library, 'Must set ThemeManager.Library first!')
		self:CreateThemeManager(groupbox)
	end

	ThemeManager:BuildFolderTree()
end

return ThemeManager
