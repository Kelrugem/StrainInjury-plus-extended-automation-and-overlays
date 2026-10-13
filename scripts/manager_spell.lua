-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local tSpellsets = { "spellset" };

-- Compatiblity check for Advanced Charsheet and several spellsets
function onInit()
	if SpellManagerAC then
		tSpellsets = { "spellset", "weaponspellset", "itemspellset", "otherspellset" };
	end
end

-- KEL adding nomnom and short rest reset (also some change in manager_combat2 stored in _combat3)
function resetSpells(nodeCaster)
	for _,sSpellset in ipairs(tSpellsets) do
		for _,nodeSpellClass in ipairs(DB.getChildList(nodeCaster, sSpellset)) do
			DB.setValue(nodeSpellClass, "pointsused", "number", 0);

			for _,nodeLevel in ipairs(DB.getChildList(nodeSpellClass, "levels")) do
				for _,nodeSpell in ipairs(DB.getChildList(nodeLevel, "spells")) do
					-- KEL Beware the actions of one spell contain all actions, also damage and other casts and so on
					local bSleep = true;
					for _,nodeAction in ipairs(DB.getChildList(nodeSpell, "actions")) do
						if DB.getValue(nodeAction, "usereset", "") == "consumable" then
							bSleep = false;
						end
					end
					if bSleep then
						DB.setValue(nodeSpell, "cast", "number", 0);
					end
				end
			end
		end
	end
end

function resetShortSpells(rActor)
	local nodeCaster = ActorManager.getCreatureNode(rActor);
	if not nodeCaster then
		return;
	end
	for _,sSpellset in ipairs(tSpellsets) do
		for _,nodeSpellClass in ipairs(DB.getChildList(nodeCaster, sSpellset)) do
			for _,nodeLevel in ipairs(DB.getChildList(nodeSpellClass, "levels")) do
				for _,nodeSpell in ipairs(DB.getChildList(nodeLevel, "spells")) do
					-- KEL Beware the actions of one spell contain all actions, also damage and other casts and so on
					local bSleep = false;
					for _,nodeAction in ipairs(DB.getChildList(nodeSpell, "actions")) do
						if DB.getValue(nodeAction, "usereset", "") == "shortrest" then
							bSleep = true;
						end
					end
					if bSleep then
						DB.setValue(nodeSpell, "cast", "number", 0);
					end
				end
			end
		end
	end
end

-- END

-- Iterate through each spell to reset, KEL add compatibility tSpellsets
function resetPrepared(nodeCaster)
	for _,sSpellset in ipairs(tSpellsets) do
		for _,nodeSpellClass in ipairs(DB.getChildList(nodeCaster, sSpellset)) do
			for _,nodeLevel in ipairs(DB.getChildList(nodeSpellClass, "levels")) do
				for _,nodeSpell in ipairs(DB.getChildList(nodeLevel, "spells")) do
					DB.setValue(nodeSpell, "prepared", "number", 0);
				end
			end
		end
	end
end

-- KEL If I want to adjust the considered tags: edit getPowerTags in SpellManager

function onSpellAction(draginfo, nodeAction, sSubRoll)
	if not nodeAction then
		return;
	end
	local rActor = ActorManager.resolveActor(DB.getChild(nodeAction, "........."));
	if not rActor then
		return;
	end
	-- KEL CL effect
	local rFirstCastAction = SpellManager.getFirstCastAction(nodeAction);
	local sFirstCastTags = "";
	if rFirstCastAction.tags then
		sFirstCastTags = table.concat(rFirstCastAction.tags, ";");
	else
		sFirstCastTags = nil;
	end
	local aAddDice, nAddMod, nEffectCount = EffectManager35E.getEffectsBonus(rActor, "CL", false, nil, nil, false, sFirstCastTags);
	local nClMod = 0;
	if nEffectCount > 0 then
		nClMod = StringManager.evalDice(aAddDice, nAddMod);
	end
	-- local originalCl = DB.getValue(nodeAction, ".......cl", 0);
	local nodeSpellClass = DB.getChild(nodeAction, ".......");
	local originalCl = DB.getValue(nodeSpellClass, "cl", 0)
	local NewCL = originalCl + nClMod;
	DB.setValue(nodeSpellClass, "cl", "number", NewCL);
	--END
	local rAction = getSpellAction(rActor, nodeAction, sSubRoll);
	-- KEL Reset CL to original value
	DB.setValue(nodeSpellClass, "cl", "number", originalCl);
	-- END
	
	local rRolls = {};
	local rCustom = nil;
	if rAction.type == "cast" then
		-- KEL Use Cast-specific tags (?)
		if not rAction.subtype then
			table.insert(rRolls, ActionSpell.getSpellCastRoll(rActor, rAction));
		end
		
		if not rAction.subtype or rAction.subtype == "atk" then
			if rAction.range then
				-- KEL add tag in getRoll itself, since that is need for IFTAG-KEEN; similar for following getRoll
				local rRoll = ActionAttack.getRoll(rActor, rAction);
				table.insert(rRolls, rRoll);
			end
		end

		if not rAction.subtype or rAction.subtype == "clc" then
			local rRoll = ActionSpell.getCLCRoll(rActor, rAction);
			if not rAction.subtype then
				rRoll.sType = "castclc";
				rRoll.aDice = {};
			end
			table.insert(rRolls, rRoll);
		end

		if not rAction.subtype or rAction.subtype == "save" then
			if rAction.save and rAction.save ~= "" then
				local rRoll = ActionSpell.getSaveVsRoll(rActor, rAction);
				if not rAction.subtype then
					rRoll.sType = "castsave";
				end
				table.insert(rRolls, rRoll);
			end
		end
		
	elseif rAction.type == "damage" then
		-- KEL add range and tag stuff to spells
		SpellManager.decorateActionWithCastMetadata(rAction, rFirstCastAction);
		--END
		local rRoll = ActionDamage.getRoll(rActor, rAction);
		if rAction.bSpellDamage then
			rRoll.sType = "spdamage";
		else
			rRoll.sType = "damage";
		end
		
		table.insert(rRolls, rRoll);
		
	elseif rAction.type == "heal" then
		-- KEL add tags
		SpellManager.decorateActionWithCastMetadata(rAction, rFirstCastAction);
		-- END
		local rRoll = ActionHeal.getRoll(rActor, rAction);
		table.insert(rRolls, rRoll);

	elseif rAction.type == "effect" then
		local rRoll;
		-- KEL
		SpellManager.decorateActionWithCastMetadata(rAction, rFirstCastAction);
		-- END
		rRoll = ActionEffect.getRoll(draginfo, rActor, rAction);
		if rRoll then
			-- KEL adding tags, just in case :)
			if tag then
				rRoll.tags = tag;
			end
			-- END
			table.insert(rRolls, rRoll);
		end
	end
	
	if #rRolls > 0 then
		ActionsManager.performMultiAction(draginfo, rActor, rRolls[1].sType, rRolls);
	end
end

-- KEL get first cast action to extract tags, range, etc
function getFirstCastAction(nodeAction)
	local rCastAction = {};
	-- KEL If multiple cast actions: Important that all cast actions have the same tags? Also adding ranges
	local nodeSpellActions = DB.getChildList(nodeAction, "..")	for _, v in ipairs(nodeSpellActions) do
		if DB.getValue(v, "type") == "cast" then
			rCastAction = SpellManager.getSpellAction(rActor, v);
			break;
		end
	end
	return rCastAction;
end
-- END

-- KEL decorate action with cast metadata (tags, range, etc)
function decorateActionWithCastMetadata(rAction, rCastAction)
	if rCastAction.range and not rAction.range then
		rAction.range = rCastAction.range;
	end
	if rCastAction.tags and not rAction.tags then
		rAction.tags = rCastAction.tags;
	end


end
-- END

function getActionAbilityBonus(nodeAction)
	local nodeSpellClass = DB.getChild(nodeAction, ".......");
	-- KEl comp with Zarestia
	if not nodeSpellClass then
		return 0;
	end
	-- END
	local nodeCreature = DB.getChild(nodeSpellClass, "...");

	local sAbility = DB.getValue(nodeSpellClass, "dc.ability", "");

	local rActor = ActorManager.resolveActor(nodeCreature);
	local nStat = ActorManager35E.getAbilityBonus(rActor, sAbility);
	
	-- KEL replace DC if necessary; use getAbilityBonus to have the DC update when ability changes because replacedc.abilitymod does only get updated when save definition window is opened
	local sReplAbil = DB.getValue(nodeAction, "replacedc.ability", "");
	if sReplAbil ~= "" then
		-- nStat = DB.getValue(nodeAction, "replacedc.abilitymod", 0);
		nStat = ActorManager35E.getAbilityBonus(rActor, sReplAbil);
	end
	-- END
	
	return nStat;
end

function getActionCLC(nodeAction)
	local nStat = DB.getValue(nodeAction, ".......cl", 0);
	local nPen = DB.getValue(nodeAction, ".......sp", 0);
	local nMod = DB.getValue(nodeAction, "clcmod", 0);
	
	return nStat + nPen + nMod;
end

function getActionSaveDC(nodeAction)
	local nTotal;
	
	if DB.getValue(nodeAction, "savedctype", "") == "fixed" then
		nTotal = DB.getValue(nodeAction, "savedcmod", 0);
    elseif DB.getValue(nodeAction, "savedctype", "") == "casterlevel" then
		local nClassStat = getActionAbilityBonus(nodeAction);
		local nClassMisc = DB.getValue(nodeAction, ".......dc.misc", 0);
        local nCasterLevel = math.floor(DB.getValue(nodeAction, ".......cl", 0)/2);
        local nMod = DB.getValue(nodeAction, "savedcmod", 0);

        nTotal = 10 + nClassStat + nClassMisc + nCasterLevel + nMod;
	else
		local nClassStat = getActionAbilityBonus(nodeAction);
		local nClassMisc = DB.getValue(nodeAction, ".......dc.misc", 0);
		local nSpellLevel = DB.getValue(nodeAction, ".....level", 0);
		local nMod = DB.getValue(nodeAction, "savedcmod", 0);
		
		nTotal = 10 + nClassStat + nClassMisc + nSpellLevel + nMod;
	end
	
	return nTotal;
end
-- KEL Adding new CL and LVL mods
function getActionMod(rActor, nodeAction, sStat, nStatMax)
	local nStat;
	
	if sStat == "" then
		nStat = 0;
	elseif sStat == "cl" or sStat == "halfcl" or sStat == "oddcl" or sStat =="thirdcl" then
		nStat = DB.getValue(nodeAction, ".......cl", 0);
		if sStat == "halfcl" then
			nStat = math.floor((nStat + 0.5) / 2);
		elseif sStat == "oddcl" then
			nStat = math.floor((nStat + 1.5) / 2);
		elseif sStat == "thirdcl" then
			nStat = math.floor(nStat / 3);
		end
	-- elseif sStat == "totallvl" then
		-- nStat = ActorManager35E.getAbilityBonus(rActor, "level");
	else
		nStat = ActorManager35E.getAbilityBonus(rActor, sStat);
	end
	
	if nStat > 0 and nStatMax and nStatMax > 0 then
		nStat = math.max(math.min(nStat, nStatMax), 0);
	end
	
	return nStat;
end
-- END
function getActionDamage(rActor, nodeAction)
	if not nodeAction then
		return {};
	end
	
	local clauses = {};
	local aDamageNodes = UtilityManager.getNodeSortedChildren(nodeAction, "damagelist");
	for _,v in ipairs(aDamageNodes) do
		local aDmgDice = DB.getValue(v, "dice", {});
		if #aDmgDice > 0 then
			local sDiceStat = DB.getValue(v, "dicestat", "");
			local nDiceStatMax = DB.getValue(v, "dicestatmax", 0);
			
			local nDiceMult = math.max(getActionMod(rActor, nodeAction, sDiceStat, nDiceStatMax), 1);
			if nDiceMult > 1 then
				local nCopy = #aDmgDice;
				for i = 2, nDiceMult do
					for j = 1, nCopy do
						table.insert(aDmgDice, aDmgDice[j]);
					end
				end
			end
		end
		
		local nDmgMod = DB.getValue(v, "bonus", 0);

		local sDmgStat = DB.getValue(v, "stat", "");
		local nDmgStatMult = 1;
		local nDmgStatMax = 0;
		if sDmgStat ~= "" then
			nDmgStatMult = math.max(DB.getValue(v, "statmult", 1), 0.5);
			nDmgStatMax = math.max(DB.getValue(v, "statmax", 0), 0);
			
			local nDmgStat = getActionMod(rActor, nodeAction, sDmgStat, nDmgStatMax);
			nDmgMod = nDmgMod + math.floor(nDmgStat * nDmgStatMult);
		end

		local aDamageTypes = ActionDamage.getDamageTypesFromString(DB.getValue(v, "type", ""));
		local sDmgType = table.concat(aDamageTypes, ",");
		
		table.insert(clauses, { dice = aDmgDice, modifier = nDmgMod, mult = 2, stat = sDmgStat, statmax = nDmgStatMax, statmult = nDmgStatMult, dmgtype = sDmgType });
	end

	return clauses;
end

function getActionHeal(rActor, nodeAction)
	if not nodeAction then
		return {};
	end
	
	local clauses = {};
	local aDamageNodes = UtilityManager.getNodeSortedChildren(nodeAction, "heallist");
	for _,v in ipairs(aDamageNodes) do
		local aDice = DB.getValue(v, "dice", {});
		if #aDice > 0 then
			local sDiceStat = DB.getValue(v, "dicestat", "");
			local nDiceStatMax = DB.getValue(v, "dicestatmax", 0);
			
			local nDiceMult = math.max(getActionMod(rActor, nodeAction, sDiceStat, nDiceStatMax), 1);
			if nDiceMult > 1 then
				local nCopy = #aDice;
				for i = 2, nDiceMult do
					for j = 1, nCopy do
						table.insert(aDice, aDice[j]);
					end
				end
			end
		end
		
		local nMod = DB.getValue(v, "bonus", 0);

		local sStat = DB.getValue(v, "stat", "");
		local nStatMult = 1;
		local nStatMax = 0;
		if sStat ~= "" then
			nStatMult = math.max(DB.getValue(v, "statmult", 1), 0.5);
			nStatMax = math.max(DB.getValue(v, "statmax", 0), 0);
			
			local nStat = getActionMod(rActor, nodeAction, sStat, nStatMax);
			nMod = nMod + math.floor(nStat * nStatMult);
		end

		table.insert(clauses, { dice = aDice, modifier = nMod, mult = 2, stat = sStat, statmax = nStatMax, statmult = nStatMult });
	end

	return clauses;
end

function getActionEffectDuration(rActor, nodeAction)
	if not nodeAction then
		return {}, 0;
	end
	
	local aDice = DB.getValue(nodeAction, "durdice", {});
	if #aDice > 0 then
		local sDiceStat = DB.getValue(nodeAction, "durdicestat", "");
		local nDiceStatMax = DB.getValue(nodeAction, "durdicestatmax", 0);
		
		local nDiceMult = math.max(getActionMod(rActor, nodeAction, sDiceStat, nDiceStatMax), 1);
		if nDiceMult > 1 then
			local nCopy = #aDice;
			for i = 2, nDiceMult do
				for j = 1, nCopy do
					table.insert(aDice, aDice[j]);
				end
			end
		end
	end
	
	local nMod = DB.getValue(nodeAction, "durmod", 0);
	
	local sStat = DB.getValue(nodeAction, "durstat", "");
	local nStatMult = 1;
	local nStatMax = 0;
	if sStat ~= "" then
		nStatMult = math.max(DB.getValue(nodeAction, "durmult", 1), 1);
		nStatMax = math.max(DB.getValue(nodeAction, "dmaxstat", 0), 0);
		
		local nStat = getActionMod(rActor, nodeAction, sStat, nStatMax);
		nMod = nMod + math.floor(nStat * nStatMult);
	end

	return aDice, nMod;
end

--
-- DISPLAY FUNCTIONS
--

function getActionCLText(nodeAction)
	local nCL = SpellManager.getActionCLC(nodeAction);
	if (nCL or 0) == 0 then
		return "";
	end
	return tostring(nCL) or "";
end

function getActionAttackText(nodeAction)
	local sAttack = "";
	
	local sAttackType = DB.getValue(nodeAction, "atktype", "");
	local nAttackMod = DB.getValue(nodeAction, "atkmod", 0);
	if sAttackType == "melee" then
		sAttack = Interface.getString("power_label_atktypemelee");
	elseif sAttackType == "ranged" then
		sAttack = Interface.getString("power_label_atktyperanged");
	elseif sAttackType == "mtouch" then
		sAttack = Interface.getString("power_label_atktypemtouch");
	elseif sAttackType == "rtouch" then
		sAttack = Interface.getString("power_label_atktypertouch");
	elseif sAttackType == "cm" then
		sAttack = Interface.getString("power_label_atktypegrapple");
	end
	if sAttack ~= "" and nAttackMod ~= 0 then
		sAttack = sAttack .. " + " .. nAttackMod;
	end
	
	return sAttack;
end

function getActionSaveText(nodeAction)
	local sSave = "";

	local sSaveType = DB.getValue(nodeAction, "savetype", "");
	local nDC = SpellManager.getActionSaveDC(nodeAction);

	if sSaveType ~= "" and nDC ~= 0 then
		if sSaveType == "fortitude" then
			sSave = Interface.getString("power_label_savetypefort");
		elseif sSaveType == "reflex" then
			sSave = Interface.getString("power_label_savetyperef");
		elseif sSaveType == "will" then
			sSave = Interface.getString("power_label_savetypewill");
		end
		
		sSave = string.format("%s DC %d", sSave, nDC);
		if DB.getValue(nodeAction, "onmissdamage", "") == "half" then
			sSave = sSave .. " (H)";
		end
	end
	
	return sSave;
end

function getActionDamageText(nodeAction)
	local nodeActor = DB.getChild(nodeAction, ".........")
	local rActor = ActorManager.resolveActor(nodeActor);

	local clauses = SpellManager.getActionDamage(rActor, nodeAction);
	
	local aOutput = {};
	local aDamage = ActionDamage.getDamageStrings(clauses);
	for _,rDamage in ipairs(aDamage) do
		local sDice = StringManager.convertDiceToString(rDamage.aDice, rDamage.nMod);
		if sDice ~= "" then
			if rDamage.sType ~= "" then
				table.insert(aOutput, string.format("%s %s", sDice, rDamage.sType));
			else
				table.insert(aOutput, sDice);
			end
		end
	end
	local sDamage = table.concat(aOutput, " + ");
	
	local sMeta = DB.getValue(nodeAction, "meta", "");
	if sMeta == "empower" then
		sDamage = sDamage .. " [E]";
	elseif sMeta == "maximize" then
		sDamage = sDamage .. " [M]";
	end
	
	return sDamage;
end

function getActionHealText(nodeAction)
	local nodeActor = DB.getChild(nodeAction, ".........")
	local rActor = ActorManager.resolveActor(nodeActor);

	local clauses = SpellManager.getActionHeal(rActor, nodeAction);
	
	local aHealDice = {};
	local nHealMod = 0;
	for _,vClause in ipairs(clauses) do
		for _,vDie in ipairs(vClause.dice) do
			table.insert(aHealDice, vDie);
		end
		nHealMod = nHealMod + vClause.modifier;
	end

	local sHeal = StringManager.convertDiceToString(aHealDice, nHealMod);
	if DB.getValue(nodeAction, "healtype", "") == "temp" then
		sHeal = sHeal .. " temporary";
	-- KEL and bmos adding nonlethal healing
	elseif DB.getValue(nodeAction, "healtype", "") == "strain" then
		sHeal = sHeal .. " strain";
	-- END
	end
	
	local sMeta = DB.getValue(nodeAction, "meta", "");
	if sMeta == "empower" then
		sHeal = sHeal .. " [E]";
	elseif sMeta == "maximize" then
		sHeal = sHeal .. " [M]";
	end
	
	return sHeal;
end

function getActionEffectDurationText(node)
	local nodeActor = DB.getChild(node, ".........");
	local rActor = ActorManager.resolveActor(nodeActor);

	local aDice, nMod = getActionEffectDuration(rActor, node);

	local tOutput = {};
	local sDuration = StringManager.convertDiceToString(aDice, nMod);
	if sDuration ~= "" then
		table.insert(tOutput, sDuration);

		local sUnits = DB.getValue(node, "durunit", "");
		if sDuration ~= "" then
			if sUnits == "minute" then
				table.insert(tOutput, "min");
			elseif sUnits == "hour" then
				table.insert(tOutput, "hr");
			elseif sUnits == "day" then
				table.insert(tOutput, "dy");
			else
				table.insert(tOutput, "rd");
			end
		end
	end

	return table.concat(tOutput, " ");
end
