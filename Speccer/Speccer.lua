--[[
    Speccer, a clean way to change specs
	Author: Marxwasright (Grobbulus - H)
	Version: 0.1
	
	TODO:
	1. Interface options
		- button resizing
		- add ability to stack buttons vertically or horizontally (arbitrary positioning??)
	2. We don't really need to have 2 buttons always showing, we can toggle the current spec's button OFF
		- however that button is useful to change to that gearset quickly, even if you're already in that talent tree
]]
local _, Speccer = ...
Speccer = LibStub("AceAddon-3.0"):NewAddon(Speccer, "Speccer", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")

_G.Speccer = Speccer -- "_G" is essentially the greater environment all AddOns exist within

local _G = _G
local type, pairs, hooksecurefunc = type, pairs, hooksecurefunc

local WoWWrath = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)

-- these are arrays for holding the spec/gear data we scan on initialization
local found_gearsets = {}
Speccer.gearset_options_dropdown_populator = {}
Speccer.spec_options_dropdown_populator = {}

-- SpeccerDB defaults if none found
local defaults = {
    char = {
		btn1_setID = "",
		btn2_setID = "",
		btn1_specID = 1,
		btn2_specID = 1,
		btn1_specName = "",  
		btn2_specName = "",
		btn1_iconID = 69,
		btn2_iconID = 420,
		frame_pos_x = 300,
		frame_pos_y = 300,
		Visible = true,
		Locked = true
    }
}

Speccer.CONFIG_VERSION = 1

local frame = CreateFrame("Frame", "Speccer", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)

function Speccer:OnInitialize() 
    -- DB init
	self.db = LibStub("AceDB-3.0"):New("SpeccerDB", defaults)
	Speccer:LoadPreferencesFromDB()
    -- Options init
    self:SetupOptions()
    -- Gather player data init
	Speccer:LoadCurrentGearsetData()
	Speccer:LoadCurrentSpecData()
	--Speccer:Print("Loaded SpeccerDB")
	-- Graphics init
	Speccer:InitializeWindow()
	Speccer:Print("Loaded Speccer! /sp or right click the frame for options")
end

function Speccer:InitializeWindow()
	frame:SetWidth(70)
	frame:SetHeight(40)
	frame:SetPoint("BOTTOMLEFT", UIParent, self.db.char.frame_pos_x, self.db.char.frame_pos_y)
--	frame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
--					   edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
--					   tile = true, 
--					   tileSize = 32, 
--					   edgeSize = 8, 
--					   insets = { left = 2, right = 2, top = 2, bottom = 2 }	})
	frame:SetBackdropColor(0,0,0,1)
	frame:EnableMouse(true)
	frame:SetMovable(self.db.char.Locked)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:RegisterForDrag("");
	frame:SetClampedToScreen(true)
	frame:SetScript("OnDragStart", function()	frame:StartMoving()	end)
	frame:SetScript("OnDragStop", function()
									frame:StopMovingOrSizing();
									--Speccer:SaveFrameDataToDB();
								  end)
	frame:SetScript("OnMouseUp", function(self, button) if button == "RightButton" then LibStub("AceConfigDialog-3.0"):Open("Speccer") end end)
	
	b1 = CreateFrame("Button", "DamageButton", frame, "UIPanelButtonTemplate")
	b1:SetSize(25, 25) -- TODO: btn size and position to options and save to DB
	--b1:SetText("1")
	b1:SetPoint("CENTER", frame, "CENTER", -15, -0)
	b1:SetScript("OnClick", function() Speccer:ChangeSpecsButton1() end)
	b1:SetScript("OnMouseUp", function(self, button) if button == "RightButton" then LibStub("AceConfigDialog-3.0"):Open("Speccer") end end)
	b1:SetNormalTexture(self.db.char.btn1_iconID)
	
	b2 = CreateFrame("Button", "HealButton", frame, "UIPanelButtonTemplate")
	b2:SetSize(25, 25) -- TODO: btn size and position to options and save to DB
	--b2:SetText("2")
	b2:SetPoint("CENTER", frame, "CENTER", 15, 0)
	b2:SetScript("OnClick", function() Speccer:ChangeSpecsButton2() end)
	b2:SetScript("OnMouseUp", function(self, button) if button == "RightButton" then LibStub("AceConfigDialog-3.0"):Open("Speccer") end end)
	b2:SetNormalTexture(self.db.char.btn2_iconID)
	
	if(self.db.char.Visible) then frame:Show() else frame:Hide() end
	if(self.db.char.Locked) then Speccer:LockMainFrame() else Speccer:UnlockMainFrame() end
end

--[[ 
    you don't have to use these unless you need them (at least it seems so)
    --> the OnDisable() could be useful to save profile options or things last minute

-- Called when the addon is enabled (Ace library level function)
function Speccer:OnEnable()
    --Speccer:Print("Enabling Speccer") -- also prints in the OnInitialize() function
end

-- Called when the addon is disabled (Ace library level function)
function Speccer:OnDisable()
end

]]

function Speccer:LoadPreferencesFromDB()
--[[	 
	 Speccer:Print("Loaded DB Prefs: ")
	 Speccer:Print(self.db.char.btn1_setID)
	 Speccer:Print(self.db.char.btn2_setID)
	 Speccer:Print(self.db.char.btn1_specID)
	 Speccer:Print(self.db.char.btn2_specID)
	 Speccer:Print(self.db.char.btn1_specName)
	 Speccer:Print(self.db.char.btn2_specName)
	 Speccer:Print(self.db.char.btn1_iconID)
	 Speccer:Print(self.db.char.btn2_iconID)
	 Speccer:Print(self.db.char.frame_pos_x)
	 Speccer:Print(self.db.char.frame_pos_y)
	 Speccer:Print(self.db.char.Visible)
	 Speccer:Print(self.db.char.Locked)
--]]
end

function Speccer:SaveFrameDataToDB()
	-- x and y are relative to the frame's BOTTOMLEFT anchorpoint 
	self.db.char.frame_pos_x = frame:GetLeft()
	self.db.char.frame_pos_y = frame:GetBottom()
end

function Speccer:ChangeSpecsButton1()
	if(self.db.char.btn1_setID == "") then Speccer:Print("BTN1 NOT INIT") return end
	EquipmentManager_EquipSet(self.db.char.btn1_setID)
	SetActiveTalentGroup(self.db.char.btn1_specID)
end

function Speccer:ChangeSpecsButton2()
	if(self.db.char.btn2_setID == "") then Speccer:Print("BTN2 NOT INIT") return end
	EquipmentManager_EquipSet(self.db.char.btn2_setID)
	SetActiveTalentGroup(self.db.char.btn2_specID)
end


function Speccer:UpdateButton1Icon(gsID)	
	for i=1,#found_gearsets do
		local fgs = found_gearsets[i]
		-- setName, iconID, setID, isEquipped
		if(fgs[3] == gsID) then self.db.char.btn1_iconID = fgs[2]; 
								b1:SetNormalTexture(self.db.char.btn1_iconID); 
								self.db.char.btn1_setID = gsID; break 
							end
	end
end

function Speccer:UpdateButton1Spec(sID)	
	-- sID == "PRIMARY" or "SECONDARY"
	-- primary == 1
	-- secondary == 2
	self.db.char.btn1_specName = sID
	if(sID == "PRIMARY") then self.db.char.btn1_specID = 1 
	elseif(sID == "SECONDARY") then self.db.char.btn1_specID = 2 end
end

function Speccer:UpdateButton2Icon(gsID)
	for i=1,#found_gearsets do
		local fgs = found_gearsets[i]
		-- setName, iconID, setID, isEquipped
		if(fgs[3] == gsID) then self.db.char.btn2_iconID = fgs[2]; b2:SetNormalTexture(self.db.char.btn2_iconID); self.db.char.btn2_setID = gsID; break end -- TODO: Also save updates to DB
	end
end

function Speccer:UpdateButton2Spec(sID)	
	-- sID == "PRIMARY" or "SECONDARY"
	-- primary == 1
	-- secondary == 2
	self.db.char.btn2_specName = sID
	if(sID == "PRIMARY") then self.db.char.btn2_specID = 1 
	elseif(sID == "SECONDARY") then self.db.char.btn2_specID = 2 end
end

function Speccer:LoadCurrentGearsetData()
	found_gearsets = {}
	
	local getids = C_EquipmentSet.GetEquipmentSetIDs()
	for i=1,#getids do
		
		local setName, iconID, setID, isEquipped = C_EquipmentSet.GetEquipmentSetInfo(getids[i])
		local equipset = {
			[1] = setName,
			[2] = iconID,
			[3] = setID,
			[4] = isEquipped,
		}
		table.insert(found_gearsets, equipset)
	end

	for i=1,#found_gearsets do
		local gs = found_gearsets[i]
		Speccer.gearset_options_dropdown_populator[i-1] = gs[1]
	end
end

function Speccer:LoadCurrentSpecData()
	--found_specializations = {}
	
	--local getspecs = C_SpecializationInfo.GetSpecIDs(specSetID)
	local current_spec = GetActiveTalentGroup() -- NOT zero-indexed!!
	--Speccer:Print("Current Spec Index: " .. current_spec)
	
	-- TODO: Should just make this function check if they have more than 1 spec total
	-- if they don't, don't load the addon
end

function Speccer:UnlockMainFrame()
	frame:SetMovable(true)
	self.db.char.Locked = false
	frame:RegisterForDrag("LeftButton","RightButton");
end

function Speccer:LockMainFrame()
	frame:SetMovable(false)
	self.db.char.Locked = true
	frame:RegisterForDrag("");
end

function Speccer:ToggleFrameLock()
	self.db.char.Locked = not self.db.char.Locked
	if(self.db.char.Locked) then
		Speccer:LockMainFrame();
		Speccer:SaveFrameDataToDB();
	else
		Speccer:UnlockMainFrame()
	end
end

function Speccer:ToggleGUI()
	self.db.char.Visible = not self.db.char.Visible
	if(self.db.char.Visible) then
		frame:Show()
	else
		frame:Hide()
	end
end

