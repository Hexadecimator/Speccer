local _, Speccer = ...

local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local error, select, pairs = error, select, pairs
local WoWWrath = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)



local getFunc, setFunc
do
	function getFunc(info)
		return (info.arg and Speccer.db.profile[info.arg] or Speccer.db.profile[info[#info]])
	end

	function setFunc(info, value)
		local key = info.arg or info[#info]
		Speccer.db.profile[key] = value
	end
end

local function generateOptions()
	Speccer.options = {
		type = "group",
		name = "Speccer",
		childGroups = "tree",
		args = {
			lock = {
				order = 1,
				type = "toggle",
				name = "Lock Frame",
				desc = "Unlock to reposition the frame",
				get = function() return Speccer.Locked end,
				set = function(info, value) Speccer:ToggleFrameLock() end, -- TODO lock the frame here
				width = "full",
			},
			bars = {
				order = 20,
				type = "group",
				name = "Options",
				args = {
					options = {
						type = "group",
						order = 0,
						name = function(info) if info.uiType == "dialog" then return "" else return "Options" end end,
						guiInline = true,
						args = {
							enableAddonGUI = {
								order = 1,
								type = "toggle",
								name = "Enable",
								desc = "Enable or disable addon frame",
								width = "full",
								get = function(info) return Speccer.Visible end,
								set = function(info, value) Speccer:ToggleGUI() end, -- TODO hide or show the addon frame here
							},
							TesterControl1 = {
								order = 2,
								type = "toggle",
								name = "Test1",
								desc = "Test1",
								width = "full",
								get = function(info) end,
								set = function(info, value) Speccer:LoadCurrentSpecData() end, -- TODO hide or show the addon frame here
							},
							Button1GearsetDropdown = {
								order = 60,
								type = "select",
								name = "Choose Button 1 Gearset",
								desc = "Set button 1 behavior",
								get = function(info) return Speccer.btn1_setID end,
								set = function(info, value) Speccer:UpdateButton1Icon(value) end,
								values = Speccer.gearset_options_dropdown_populator,
							},
							Button1SpecDropdown = {
								order = 70,
								type = "select",
								name = "Choose Button 1 Spec",
								desc = "Set button 1 Spec",
								get = function(info) return Speccer.btn1_specName end,
								set = function(info, value) Speccer:UpdateButton1Spec(value) end,
								values = { PRIMARY="Primary", SECONDARY="Secondary" },
							},
							Button2GearsetDropdown = {
								order = 80,
								type = "select",
								name = "Choose Button 2 Gearset",
								desc = "Set button 2 behavior",
								get = function(info) return Speccer.btn2_setID end,
								set = function(info, value) Speccer:UpdateButton2Icon(value) end,
								values = Speccer.gearset_options_dropdown_populator,
							},
							Button2SpecDropdown = {
								order = 90,
								type = "select",
								name = "Choose Button 2 Spec",
								desc = "Set button 2 Spec",
								get = function(info) return Speccer.btn2_specName end,
								set = function(info, value) Speccer:UpdateButton2Spec(value) end,
								values = { PRIMARY="Primary", SECONDARY="Secondary" },
							},
						},
					},
				},
			},
		},
	}
	--Speccer.options.plugins.profiles = { profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(Speccer.db) }
	for k,v in Speccer:IterateModules() do
		if v.SetupOptions then
			v:SetupOptions()
		end
	end
end

function Speccer:ChatCmd(input)
	if not input or input:trim() == "" then
		LibStub("AceConfigDialog-3.0"):Open("Speccer")
	else
		LibStub("AceConfigCmd-3.0").HandleCommand(Speccer, "ba", "Speccer", input)
	end
end

local function getOptions()
	if not Speccer.options then
		generateOptions()
		-- let the generation function be GCed
		generateOptions = nil
	end
	return Speccer.options
end

function Speccer:SetupOptions()
	LibStub("AceConfig-3.0"):RegisterOptionsTable("Speccer", getOptions)
	AceConfigDialog:SetDefaultSize("Speccer", 400, 350)
	self:RegisterChatCommand( "ba", "ChatCmd")
	self:RegisterChatCommand( "Speccer", "ChatCmd")
end