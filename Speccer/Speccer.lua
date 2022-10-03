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
    if not C_EquipmentSet.CanUseEquipmentSets() then Speccer:Print("CANNOT USE EQUIPMENT SETS. DISABLING.") return end
	
	self.db = LibStub("AceDB-3.0"):New("SpeccerDB", defaults) -- load defaults

    self:SetupOptions() -- initialize and register the options menu

    Speccer:Print("Initialized Speccer") -- Print is from AceConsole
	
	Speccer:InitializeWindow()
end

function Speccer:InitializeWindow()
	frame:SetWidth(70)
	frame:SetHeight(40)
	frame:SetPoint("BOTTOMLEFT", UIParent, 270, 20)
	frame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
					   edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
					   tile = true, 
					   tileSize = 32, 
					   edgeSize = 8, 
					   insets = { left = 2, right = 2, top = 2, bottom = 2 }	})
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
	
	local db = CreateFrame("Button", "DamageButton", frame, "UIPanelButtonTemplate")
	db:SetSize(30, 30)
	db:SetText("D")
	db:SetPoint("CENTER", frame, "CENTER", -15, -0)
	db:SetScript("OnClick", function() Speccer:ChangeSpecsDamage() end)
	
	local hb = CreateFrame("Button", "HealButton", frame, "UIPanelButtonTemplate")
	hb:SetSize(30, 30)
	hb:SetText("H")
	hb:SetPoint("CENTER", frame, "CENTER", 15, 0)
	hb:SetScript("OnClick", function() Speccer:ChangeSpecsHeal() end)
	
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

function Speccer:ChangeSpecsHeal()
	EquipmentManager_EquipSet(0)
	SetActiveTalentGroup(1)
end

function Speccer:ChangeSpecsDamage()
	EquipmentManager_EquipSet(1)
	SetActiveTalentGroup(2)
end

function Speccer:ChangeSpecs()
	--EquipmentManager_EquipSet(1)
	--SetActiveTalentGroup(2)
	
	local getids = C_EquipmentSet.GetEquipmentSetIDs()
	for i=1,#getids do
		local n = C_EquipmentSet.GetEquipmentSetInfo(getids[i])
		table.insert(found_gearsets, n)
	end
	
	Speccer:Print("Following Gearsets Found:")
	for i=1,#found_gearsets do
		Speccer:Print(found_gearsets[i])
	end
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

