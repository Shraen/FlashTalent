------------------------------------------------------------
-- FlashTalent by Sonaza
-- All rights reserved
-- http://sonaza.com
------------------------------------------------------------

local ADDON_NAME, Addon = ...;
local _;

local LibQTip = LibStub("LibQTip-1.0");

function FlashTalentSpecButton_OnClick(self, button)
	if(button == "LeftButton") then
		Addon:ChangeDualSpec();
	elseif(button == "RightButton") then
		FlashTalentSpecButton.tooltip:Hide();
		Addon:OpenItemSetsMenu(self);
	end
end

function FlashTalentSpecButton_OnEnter(self)
	self.tooltip = LibQTip:Acquire("FlashTalentSpecButtonTooltip", 2, "LEFT", "RIGHT");
	Addon:OpenSpecializationsMenu(self, self.tooltip);
end

function Addon:OpenSpecializationsMenu(anchorFrame, tooltip, isCursorTip)
	if(not tooltip) then return end
	
	self.specTooltipFrame = tooltip;
	
	tooltip:Clear();
	tooltip:ClearAllPoints();
	tooltip:SetPoint("BOTTOMLEFT", anchorFrame, "TOPLEFT", 0, -2);
	
	tooltip.category = 1;
	
	local areSpecsUnlocked = UnitLevel("player") >= SHOW_SPEC_LEVEL;
	
	tooltip:AddHeader("|cffffd200Specializations|r");
	tooltip:AddSeparator();
	
	for specIndex = 1, GetNumSpecializations() do
		local id, name, description, icon, role = GetSpecializationInfo(specIndex, nil, nil, nil, UnitSex("player"));
		
		local color = "|cffeeeeee";
		local activeText = "";
		
		local isActiveSpecialization = (specIndex == GetSpecialization());
		
		if(isActiveSpecialization) then
			activeText = "|cff00ff00Active|r";
		elseif(Addon.db.char.PreviousSpec == specIndex) then
			activeText = "|cff8ce2ffQuick-Switch|r";
		end
		
		if(isActiveSpecialization) then
			color = "|cff00ff00";
		elseif(Addon.db.char.PreviousSpec == specIndex) then
			color = "|cff8ce2ff";
		end
		
		if(areSpecsUnlocked or isActiveSpecialization) then
			local lineIndex = tooltip:AddLine(
				string.format("%s %s%s|r %s", FLASHTALENT_ICON_PATTERN:format(icon), color, name, FLASHTALENT_ICON_ROLES[role]),
				activeText
			);
			
			if(areSpecsUnlocked) then
				tooltip:SetLineScript(lineIndex, "OnMouseUp", function(self, _, button)
					if(button == "LeftButton") then
						if(specIndex ~= GetSpecialization()) then
							SetSpecialization(specIndex);
						end
					else
						if(specIndex ~= GetSpecialization()) then
							Addon.db.char.PreviousSpec = specIndex;
							Addon:UpdateSpecTooltips();
						end
					end
				end);
			end
		end
	end
	
	if(not isCursorTip and areSpecsUnlocked) then
		if(Addon.db.char.PreviousSpec == nil or Addon.db.char.PreviousSpec == 0) then
			tooltip:AddLine(string.format("|cffffd200Left click a specialization to change to it.|r"));
		end
		tooltip:AddLine(string.format("|cffffd200Right click to set for quick switch.|r"));
	end
	
	if(areSpecsUnlocked) then
		local _, class = UnitClass("player");
		local petname = UnitName("pet");
		if(class == "HUNTER" and petname) then
			tooltip:AddLine(" ");
			tooltip:AddLine(string.format("|cffffd200%s's Specialization|r", petname));
			tooltip:AddSeparator();
			
			for specIndex = 1, GetNumSpecializations(false, true) do
				local id, name, description, icon, role = GetSpecializationInfo(specIndex, false, true);
				
				local color = "";
				local activeText = "";
				
				if(specIndex == GetSpecialization(false, true)) then
					color = "|cff00ff00";
					activeText = "|cff00ff00Active|r";
				end
				
				local lineIndex = tooltip:AddLine(string.format("%s %s%s", FLASHTALENT_ICON_PATTERN:format(icon), color, name), activeText);
				
				tooltip:SetLineScript(lineIndex, "OnMouseUp", function(self, _, button)
					if(specIndex ~= GetSpecialization(false, true)) then
						SetSpecialization(specIndex, true);
					end
				end);
			end
		end
	end
	
	if(areSpecsUnlocked) then
		tooltip:AddLine(" ");
		if(not isCursorTip and Addon.db.char.PreviousSpec ~= nil and Addon.db.char.PreviousSpec ~= 0) then
			local _, name, _, _, role = GetSpecializationInfo(Addon.db.char.PreviousSpec, false, false, nil, UnitSex("player"));
			tooltip:AddLine(string.format("|cff00ff00Left click|r  Switch back to |cffffd200%s|r %s", name, FLASHTALENT_ICON_ROLES[role]));
		end
	else
		tooltip:AddLine(string.format("|cffffd200Specializations unlock at level %s.|r", SHOW_SPEC_LEVEL));
		tooltip:AddLine(" ");
	end
	
	if(not isCursorTip) then
		tooltip:AddLine("|cff00ff00Right click|r  View equipment sets.");
	else
		tooltip:AddLine(string.format("|cffffd200Left click a specialization to change to it.|r"));
		tooltip:AddLine(string.format("|cffffd200Right click to set for quick switch.|r"));
	end
	
	tooltip:SetAutoHideDelay(0.4, anchorFrame);
	tooltip.OnRelease = function()
		tooltip = nil;
	end
	
	tooltip:SetClampedToScreen(true);
	tooltip:Show();
end

function Addon:OpenSpecializationsMenuAtCursor(anchorFrame)
	Addon.SpecializationCursorMenuTooltip = LibQTip:Acquire("FlashTalentSpecButtonCursorTooltip", 2, "LEFT", "RIGHT");
	Addon:OpenSpecializationsMenu(anchorFrame, Addon.SpecializationCursorMenuTooltip, true);
	
	if(Addon.SpecializationCursorMenuTooltip) then
		Addon.SpecializationCursorMenuTooltip:ClearAllPoints();
		Addon.SpecializationCursorMenuTooltip:SetPoint("TOP", anchorFrame, "CENTER", 0, 1);
	end
end

function Addon:UpdateSpecTooltips()
	if(InCombatLockdown()) then return end
	
	if(FlashTalentSpecButton.tooltip and FlashTalentSpecButton.tooltip:IsVisible() and FlashTalentSpecButton.tooltip.category == 1) then
		FlashTalentSpecButton_OnEnter(FlashTalentSpecButton);
	end
	
	if(Addon.DataBrokerTooltip and Addon.DataBrokerTooltip:IsVisible()) then
		local _, parent = Addon.DataBrokerTooltip:GetPoint()
		Addon:DataBroker_OnEnter(parent);
	end
	
	if(Addon.SpecializationCursorMenuTooltip and Addon.SpecializationCursorMenuTooltip:IsVisible()) then
		local _, anchorFrame = Addon.SpecializationCursorMenuTooltip:GetPoint();
		Addon:OpenSpecializationsMenuAtCursor(anchorFrame);
	end
end

function Addon:HideSpecButtonTooltip()
	if(not FlashTalentSpecButton.tooltip) then return end
	
	FlashTalentSpecButton.tooltip:Hide();
	LibQTip:Release(FlashTalentSpecButton.tooltip);
	FlashTalentSpecButton.tooltip = nil;
end

local playerPreviousSpecialization = GetSpecialization();
function Addon:ACTIVE_TALENT_GROUP_CHANGED(event)
	if(InCombatLockdown()) then return end
	
	if(Addon.OldSpecialization ~= nil and Addon.OldSpecialization ~= 0) then
		Addon.db.char.PreviousSpec = Addon.OldSpecialization;
	end
	
	Addon:UpdateTalentFrame();
	Addon:UpdateSpecTooltips();
	
	local activeSpec = GetSpecialization();
	
	if(playerPreviousSpecialization ~= activeSpec) then
		playerPreviousSpecialization = activeSpec;
		
		local assignedSpecFound = false;
		
		local equipmentSetIDs = C_EquipmentSet.GetEquipmentSetIDs() or {};
		for index, setID in ipairs(equipmentSetIDs) do
			if(C_EquipmentSet.GetEquipmentSetAssignedSpec(setID) == activeSpec) then
				assignedSpecFound = true;
				break;
			end
		end
		
		if(not assignedSpecFound) then
			local _, activeSpecName = GetSpecializationInfo(activeSpec, nil, nil, nil, UnitSex("player"));
			
			local foundSetID;
			for index, setID in ipairs(equipmentSetIDs) do
				local setName = C_EquipmentSet.GetEquipmentSetInfo(setID);
				if(activeSpecName == setName) then
					foundSetID = setID;
					break;
				end
			end
			
			if(foundSetID) then
				local setName, icon, _, isEquipped, numItems, numEquipped, numInventory, numMissing, numIgnored = C_EquipmentSet.GetEquipmentSetInfo(foundSetID);
				if(icon ~= nil and not isEquipped) then
					if(numMissing == 0) then
						local latency = select(4, GetNetStats());
						C_Timer.After(0.3 + latency / 1000, function()
							C_EquipmentSet.UseEquipmentSet(foundSetID);
						end);
					end
				end
			end
		end
	end
	
	Addon:UpdateDatabrokerText();
end

function Addon:PET_SPECIALIZATION_CHANGED()
	Addon:UpdateSpecTooltips();
end

function Addon:ChangeDualSpec()
	if(Addon.db.char.PreviousSpec == 0) then return end
	SetSpecialization(Addon.db.char.PreviousSpec);
end