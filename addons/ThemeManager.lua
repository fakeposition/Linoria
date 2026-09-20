local httpService = game:GetService('HttpService')
local ThemeManager = {} do
	ThemeManager.Folder = 'LinoriaLibSettings'

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
		local options = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }
		for i, field in next, options do
			if Options and Options[field] then
				self.Library[field] = Options[field].Value
			end
		end

		self.Library.AccentColorDark = self.Library:GetDarkerColor(self.Library.AccentColor)
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
				isDefault = false
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

	-- UpdateBackground は CreateThemeManager より前に定義（コールバックから参照されるため）
	function ThemeManager:UpdateBackground()
		local L    = game:GetService('Lighting')
		local blur = L:FindFirstChild('ThemeManager_Blur')
		local cc   = L:FindFirstChild('ThemeManager_CC')

		if blur then
			blur.Size = Options.BG_Blur and Options.BG_Blur.Value or 0
		end
		if cc then
			cc.Contrast   = Options.BG_Contrast   and Options.BG_Contrast.Value   or 0
			cc.Saturation = Options.BG_Saturation and Options.BG_Saturation.Value or 0
			cc.Brightness = Options.BG_Brightness and Options.BG_Brightness.Value or 0
		end

		if self._BgFrame then
			-- t=1: 背景がそのまま見える  t→0: BG_Colorで塗りつぶされる
			local t = Options.BG_Transparency and Options.BG_Transparency.Value or 1
			self._BgFrame.BackgroundTransparency = t
			self._BgFrame.BackgroundColor3 = Options.BG_Color and Options.BG_Color.Value or Color3.new(0, 0, 0)
		end
	end

	function ThemeManager:CreateThemeManager(tabbox)
		-- ===== Tab 1: Themes =====
		local themesTab = tabbox:AddTab('Themes')

		-- UI テーマカラーピッカー
		themesTab:AddLabel('Background color'):AddColorPicker('BackgroundColor', { Default = self.Library.BackgroundColor })
		themesTab:AddLabel('Main color')      :AddColorPicker('MainColor',       { Default = self.Library.MainColor })
		themesTab:AddLabel('Accent color')    :AddColorPicker('AccentColor',     { Default = self.Library.AccentColor })
		themesTab:AddLabel('Outline color')   :AddColorPicker('OutlineColor',    { Default = self.Library.OutlineColor })
		themesTab:AddLabel('Font color')      :AddColorPicker('FontColor',       { Default = self.Library.FontColor })

		-- Built-in theme dropdown
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

		-- Custom theme
		themesTab:AddInput('ThemeManager_CustomThemeName', { Text = 'Custom theme name' })
		themesTab:AddDropdown('ThemeManager_CustomThemeList', { Text = 'Custom themes', Values = self:ReloadCustomThemes(), AllowNull = true, Default = 1 })

		themesTab:AddDivider()

		-- Save theme (full width)
		themesTab:AddButton('Save theme', function()
			self:SaveCustomTheme(Options.ThemeManager_CustomThemeName.Value)
			Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
			Options.ThemeManager_CustomThemeList:SetValue(nil)
		end)

		-- [              Load theme              ]
		themesTab:AddButton('Load theme', function()
			local name = Options.ThemeManager_CustomThemeList.Value
			if not name or name == '' then
				return self.Library:Notify('No custom theme selected', 2)
			end
			self:ApplyTheme(name)
		end)

		-- [Overwrite theme] [Delete theme]  ← ダブルクリック確認付き
		do
			local overwriteClicks = 0
			local deleteClicks    = 0

			themesTab:AddButton('Overwrite theme', function()
				local name = Options.ThemeManager_CustomThemeList.Value
				if not name or name == '' then
					return self.Library:Notify('No custom theme selected', 2)
				end
				overwriteClicks = overwriteClicks + 1
				if overwriteClicks >= 2 then
					overwriteClicks = 0
					self:SaveCustomTheme(name)
					self.Library:Notify(string.format('Overwrote theme %q', name))
				else
					self.Library:Notify('Click again to confirm overwrite', 2)
					task.delay(2, function() overwriteClicks = 0 end)
				end
			end):AddButton('Delete theme', function()
				local name = Options.ThemeManager_CustomThemeList.Value
				if not name or name == '' then
					return self.Library:Notify('No custom theme selected', 2)
				end
				deleteClicks = deleteClicks + 1
				if deleteClicks >= 2 then
					deleteClicks = 0
					local path = self.Folder .. '/themes/' .. name
					if isfile(path) then
						delfile(path)
						self.Library:Notify(string.format('Deleted theme %q', name))
					end
					Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
					Options.ThemeManager_CustomThemeList:SetValue(nil)
				else
					self.Library:Notify('Click again to confirm delete', 2)
					task.delay(2, function() deleteClicks = 0 end)
				end
			end)
		end

		-- [Set default] [Reset default]
		themesTab:AddButton('Set default', function()
			local customVal  = Options.ThemeManager_CustomThemeList.Value
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

		-- [              Refresh              ]
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

		-- Lighting / BgFrame セットアップ（コールバックより先）
		local Lighting = game:GetService('Lighting')

		if not Lighting:FindFirstChild('ThemeManager_Blur') then
			local blur = Instance.new('BlurEffect')
			blur.Name   = 'ThemeManager_Blur'
			blur.Size   = 0
			blur.Parent = Lighting
		end

		if not Lighting:FindFirstChild('ThemeManager_CC') then
			local cc = Instance.new('ColorCorrectionEffect')
			cc.Name   = 'ThemeManager_CC'
			cc.Parent = Lighting
		end

		if not self._BgFrame then
			local bg = Instance.new('Frame')
			bg.Name                   = 'ThemeManager_BgFrame'
			bg.Size                   = UDim2.new(1, 0, 1, 0)
			bg.Position               = UDim2.new(0, 0, 0, 0)
			bg.BackgroundColor3       = Color3.new(0, 0, 0)
			bg.BackgroundTransparency = 1
			bg.BorderSizePixel        = 0
			bg.ZIndex                 = -1
			bg.Parent                 = self.Library.ScreenGui
			self._BgFrame = bg
		end

		-- Background color（透明度なし）
		bgTab:AddLabel('Background color'):AddColorPicker('BG_Color', {
			Default = Color3.fromRGB(0, 0, 0),
		})
		Options.BG_Color:OnChanged(function() ThemeManager:UpdateBackground() end)

		-- Transparency (0.01〜1, assert回避のためDefault/Min/Roundingは非ゼロ)
		bgTab:AddSlider('BG_Transparency', {
			Text     = 'Transparency',
			Default  = 1,
			Min      = 0.01,
			Max      = 1,
			Rounding = 2,
			Callback = function() ThemeManager:UpdateBackground() end,
		})

		-- [Blur 0→1で代用してMin問題を回避: Min=0はassert失敗するのでAddSliderRowを使用]
		-- Blur: Min=0はfalsyなのでAddSliderRowで横並びにしてassertを回避
		bgTab:AddSliderRow(
			'BG_Blur', {
				Text     = 'Blur',
				Default  = 1,    -- 表示上の初期値、実際は0相当
				Min      = 1,    -- assert回避(実質0)
				Max      = 50,
				Rounding = 1,
				Callback = function() ThemeManager:UpdateBackground() end,
			},
			'BG_Blur_dummy', {   -- 横並び右側はダミーとして非表示用の超小スライダー
				Text     = 'Blur',
				Default  = 1,
				Min      = 1,
				Max      = 50,
				Rounding = 1,
			}
		)

		-- Contrast / Saturation 横並び
		-- Min=-10はassert通過するが念のためAddSliderRowを使用
		bgTab:AddSliderRow(
			'BG_Contrast', {
				Text     = 'Contrast',
				Default  = 0.1,
				Min      = -10,
				Max      = 10,
				Rounding = 1,
				Callback = function() ThemeManager:UpdateBackground() end,
			},
			'BG_Saturation', {
				Text     = 'Saturation',
				Default  = 0.1,
				Min      = -10,
				Max      = 10,
				Rounding = 1,
				Callback = function() ThemeManager:UpdateBackground() end,
			}
		)

		-- Brightness
		bgTab:AddSlider('BG_Brightness', {
			Text     = 'Brightness',
			Default  = 0.1,
			Min      = -1,
			Max      = 1,
			Rounding = 1,
			Callback = function() ThemeManager:UpdateBackground() end,
		})
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

	-- Tabbox版（ApplyToTabが使う）
	function ThemeManager:CreateTabbox(tab)
		assert(self.Library, 'Must set ThemeManager.Library first!')
		return tab:AddLeftTabbox('Themes')
	end

	-- 後方互換
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
