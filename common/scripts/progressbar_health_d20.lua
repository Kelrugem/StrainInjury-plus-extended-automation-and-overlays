-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local sMaxHealthNodePath = nil;
local sTempHealthNodePath = nil;
local sWoundNodePath = nil;
local sNonlethalWoundNodePath = nil;

local _bParsed = false;
local _bInitialized = false;

function parse()
	if _bParsed then
		return;
	end
	_bParsed = true;

	local node = window.getDatabaseNode();
	sMaxHealthNodePath = DB.getPath(node, "hptotal");
	sTempHealthNodePath = DB.getPath(node, "hptemp");
	sWoundNodePath = DB.getPath(node, "wounds");
	-- KEL
	sNonlethalWoundNodePath = DB.getPath(node, "injury");
	-- END
end
function init()
	if _bInitialized then
		return;
	end
	_bInitialized = true;

	self.parse();
	self.addHandlers();
	self.initFillControl();
	self.onHealthChanged();
	self.update();
end

function addHandlers()
	if sMaxHealthNodePath then
		DB.addHandler(sMaxHealthNodePath, "onUpdate", onMaxChanged);
	end
	if sTempHealthNodePath then
		DB.addHandler(sTempHealthNodePath, "onUpdate", onTempChanged);
	end
	if sWoundNodePath then
		DB.addHandler(sWoundNodePath, "onUpdate", onWoundChanged);
	end
	if sNonlethalWoundNodePath then
		DB.addHandler(sNonlethalWoundNodePath, "onUpdate", onNonlethalChanged);
	end

	OptionsManager.registerCallback("BARC", update);
	OptionsManager.registerCallback("WNDC", update);
	if not Session.IsHost then
		OptionsManager.registerCallback("SHPC", update);
	end
end
function removeHandlers()
	if sMaxHealthNodePath then
		DB.removeHandler(sMaxHealthNodePath, "onUpdate", onMaxChanged);
	end
	if sTempHealthNodePath then
		DB.removeHandler(sTempHealthNodePath, "onUpdate", onTempChanged);
	end
	if sWoundNodePath then
		DB.removeHandler(sWoundNodePath, "onUpdate", onWoundChanged);
	end
	if sNonlethalWoundNodePath then
		DB.removeHandler(sNonlethalWoundNodePath, "onUpdate", onNonlethalChanged);
	end

	OptionsManager.unregisterCallback("BARC", update);
	OptionsManager.unregisterCallback("WNDC", update);
	if not Session.IsHost then
		OptionsManager.unregisterCallback("SHPC", update);
	end
end

function onMaxChanged()
	self.onHealthChanged();
end
function onTempChanged()
	self.onHealthChanged();
end
function onWoundChanged()
	self.onHealthChanged();
end
function onNonlethalChanged()
	self.onHealthChanged();
end
-- KEL
function onHealthChanged()
	local nHP = DB.getValue(sMaxHealthNodePath, 0);
	local nTempHP = DB.getValue(sTempHealthNodePath, 0);

	local nWounds = DB.getValue(sWoundNodePath, 0);
	local nInjury = DB.getValue(sNonlethalWoundNodePath, 0);

	local nPercentWounded = 0;
	local nPercentNonlethal = 0;
	if nHP > 0 then
		nPercentWounded = (nWounds + nInjury) / (nHP + nTempHP);
		nPercentNonlethal = nWounds / (nHP + nTempHP);
	end
	
	self.setMax(nHP + nTempHP, true);
	self.setValue(nHP + nTempHP - nWounds - nInjury, true);
	
	local sColor;
	-- KEL adding >= in first line; but still, this part is not completely "correct" due to new nonlethal handling which can not be respected without an overwrite
	if nPercentWounded <= 1 and nPercentNonlethal >= 1 then
		sColor = ColorManager.getUIColor("health_unconscious");
	elseif nPercentWounded == 1 or nPercentNonlethal == 1 then
		sColor = ColorManager.getUIColor("health_simple_bloodied");
	else
		sColor = ColorManager.getHealthColor(nPercentWounded, true);
	end
	self.setFillColor(sColor);
	
	if Session.IsHost or OptionsManager.isOption("SHPC", "detailed") then
		local sText = "" .. (nHP - nWounds - nInjury);
		if nTempHP > 0 then
			sText = sText .. " (+" .. nTempHP .. ")";
		end
		sText = sText .. " / " .. nHP;
		if nTempHP > 0 then
			sText = sText .. " (+" .. nTempHP .. ")";
		end
		local sPrefix = Interface.getString("hp");
		if (sPrefix or "") ~= "" then
			sText = sPrefix .. ": " .. sText;
		end
		self.setText(sText);
	else
		self.setText("");
	end
end
-- END