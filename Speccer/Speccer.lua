--[[
    A basic template for quickly spinning up a new addon
]]
local _, Speccer = ...
Speccer = LibStub("AceAddon-3.0"):NewAddon(Speccer, "Speccer", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")

_G.Speccer = Speccer -- "_G" is essentially the greater environment all AddOns exist within

local _G = _G
local type, pairs, hooksecurefunc = type, pairs, hooksecurefunc

local WoWWrath = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)

local found_gearsets = {}
Speccer.gearset_options_dropdown_populator = {}
Speccer.spec_options_dropdown_populator = {}
Speccer.btn1_setID = ''
Speccer.btn2_setID = ''
Speccer.btn1_specID = 1
Speccer.btn2_specID = 2
Speccer.btn1_specName = ""
Speccer.btn2_specName = ""
Speccer.PrimaryTalentIdx = 1
Speccer.SecondaryTalentIdx = 2

local defaults = {
    profile = {
        teststring = "testoption1",
        testboolean = false,
        testnumber = 69
    }
}

Speccer.CONFIG_VERSION = 1

local frame = CreateFrame("Frame", "Speccer", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)

-- Code that you want to run when the addon is first loaded goes here. (Actual Blizzard functionality)
function Speccer:OnInitialize() 
    -- TODO
	-- TODO
	-- TODO
	-- TODO
	-- TODO!!! SCAN FOR ALL SPECS AND GEARSETS ON INIT
	-- save this info to arrays like Speccer.FOUND_GEARSETS and Speccer.FOUND_SPECS
	-- if only 1 spec is found then just quit initializing Speccer
	-- TODO
	-- TODO
	-- TODO
	-- TODO
	-- when this is done use these new arrays to populate the options dialog
	-- also need to figure out how to save and retrieve variables SpeccerDB
	
	if not C_EquipmentSet.CanUseEquipmentSets() then Speccer:Print("CANNOT USE EQUIPMENT SETS. DISABLING.") return end
	
	
	
	self.db = LibStub("AceDB-3.0"):New("SpeccerDB", defaults) -- load defaults

    self:SetupOptions() -- initialize and register the options menu

    Speccer:Print("Initialized Speccer") -- Print is from AceConsole
	
	Speccer:InitializeWindow()
	
	Speccer:LoadCurrentGearsetData()
	Speccer:LoadCurrentSpecData()
	
end

function Speccer:InitializeWindow()
	frame:SetWidth(70)
	frame:SetHeight(40)
	frame:SetPoint("BOTTOMLEFT", UIParent, 270, 20)
--	frame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
--					   edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
--					   tile = true, 
--					   tileSize = 32, 
--					   edgeSize = 8, 
--					   insets = { left = 2, right = 2, top = 2, bottom = 2 }	})
	frame:SetBackdropColor(0,0,0,1)
	frame:EnableMouse(true)
	frame:SetMovable(false)
	Speccer.Locked = true
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:RegisterForDrag("");
	frame:SetClampedToScreen(true)
	frame:SetScript("OnDragStart", function()	frame:StartMoving()	end)
	frame:SetScript("OnDragStop", function()	frame:StopMovingOrSizing(); end)
	frame:SetScript("OnMouseUp", function(self, button) if button == "RightButton" then LibStub("AceConfigDialog-3.0"):Open("Speccer") end end)
	
	b1 = CreateFrame("Button", "DamageButton", frame, "UIPanelButtonTemplate")
	b1:SetSize(30, 30)
	--b1:SetText("1")
	b1:SetPoint("CENTER", frame, "CENTER", -15, -0)
	b1:SetScript("OnClick", function() Speccer:ChangeSpecsButton1() end)
	b1:SetScript("OnMouseUp", function(self, button) if button == "RightButton" then LibStub("AceConfigDialog-3.0"):Open("Speccer") end end)
	--b1:SetNormalTexture(133537)
	
	b2 = CreateFrame("Button", "HealButton", frame, "UIPanelButtonTemplate")
	b2:SetSize(30, 30)
	--b2:SetText("2")
	b2:SetPoint("CENTER", frame, "CENTER", 15, 0)
	b2:SetScript("OnClick", function() Speccer:ChangeSpecsButton2() end)
	b2:SetScript("OnMouseUp", function(self, button) if button == "RightButton" then LibStub("AceConfigDialog-3.0"):Open("Speccer") end end)
	--b2:SetNormalTexture(135487)
	
	frame:Show()
	Speccer.Visible = true
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

function Speccer:ChangeSpecsButton1()
	if(Speccer.btn1_specID == '') then Speccer:Print("BTN1 NOT INIT") return end
	EquipmentManager_EquipSet(Speccer.btn1_setID)
	SetActiveTalentGroup(Speccer.btn1_specID)
end

function Speccer:ChangeSpecsButton2()
	if(Speccer.btn2_specID == '') then Speccer:Print("BTN2 NOT INIT") return end
	EquipmentManager_EquipSet(Speccer.btn2_setID)
	SetActiveTalentGroup(Speccer.btn2_specID)
end


function Speccer:UpdateButton1Icon(gsID)	
	--Speccer:Print(gsID)
	for i=1,#found_gearsets do
		local fgs = found_gearsets[i]
		-- setName, iconID, setID, isEquipped
		if(fgs[3] == gsID) then b1:SetNormalTexture(fgs[2]); Speccer.btn1_setID = gsID; break end -- TODO: Also save updates to DB
	end
end

function Speccer:UpdateButton1Spec(sID)	
	-- sID == "PRIMARY" or "SECONDARY"
	-- primary == 1
	-- secondary == 2
	Speccer.btn1_specName = sID
	if(sID == "PRIMARY") then Speccer.btn1_specID = 1 
	elseif(sID == "SECONDARY") then Speccer.btn1_specID = 2 end
	--Speccer:Print("specName: " .. Speccer.btn1_specName .. " specID: " .. Speccer.btn1_specID)
end

function Speccer:UpdateButton2Icon(gsID)
	for i=1,#found_gearsets do
		local fgs = found_gearsets[i]
		-- setName, iconID, setID, isEquipped
		if(fgs[3] == gsID) then b2:SetNormalTexture(fgs[2]); Speccer.btn2_setID = gsID; break end -- TODO: Also save updates to DB
	end
end

function Speccer:UpdateButton2Spec(sID)	
	-- sID == "PRIMARY" or "SECONDARY"
	-- primary == 1
	-- secondary == 2
	Speccer.btn2_specName = sID
	if(sID == "PRIMARY") then Speccer.btn2_specID = 1 
	elseif(sID == "SECONDARY") then Speccer.btn2_specID = 2 end
	--Speccer:Print("specName: " .. Speccer.btn2_specName .. " specID: " .. Speccer.btn2_specID)
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
	
	--Speccer:Print("Following Gearsets Found:")
	for i=1,#found_gearsets do
		local gs = found_gearsets[i]
		Speccer.gearset_options_dropdown_populator[i-1] = gs[1]
	end
end

function Speccer:LoadCurrentSpecData()
	--found_specializations = {}
	
	--local getspecs = C_SpecializationInfo.GetSpecIDs(specSetID)
	local current_spec = GetActiveTalentGroup() -- NOT zero-indexed!!
	Speccer:Print("Current Spec Index: " .. current_spec)
end

function Speccer:UnlockMainFrame()
	frame:SetMovable(true)
	Speccer.Locked = false
	frame:RegisterForDrag("LeftButton","RightButton");
end

function Speccer:LockMainFrame()
	frame:SetMovable(false)
	Speccer.Locked = true
	frame:RegisterForDrag("");
end

function Speccer:ToggleFrameLock()
	Speccer.Locked = not Speccer.Locked
	if(Speccer.Locked) then
		Speccer:LockMainFrame()
	else
		Speccer:UnlockMainFrame()
	end
end

function Speccer:ToggleGUI()
	Speccer.Visible = not Speccer.Visible
	if(Speccer.Visible) then
		frame:Show()
	else
		frame:Hide()
	end
end

