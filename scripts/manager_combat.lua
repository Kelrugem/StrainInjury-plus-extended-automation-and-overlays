-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	OldnextActor = CombatManager.nextActor;
	CombatManager.nextActor = CombatManagerKel.nextActor;
	
	OldnextRound = CombatManager.nextRound;
	CombatManager.nextRound = CombatManagerKel.nextRound;
	
	CombatManager.helperRollEntryInit = CombatManagerKel.helperRollEntryInit;
	
	-- OlddeleteCombatant = CombatManager.deleteCombatant;
	-- CombatManager.deleteCombatant = CombatManagerKel.deleteCombatant;
	CombatManager.deleteCleanup = CombatManagerKel.deleteCleanup;
end

function nextActor(bSkipBell, bNoRoundAdvance)
	if not Session.IsHost then
		return;
	end
	
	OldnextActor(bSkipBell, bNoRoundAdvance);
	-- KEL Clear saves
	for _,v in pairs(CombatManager.getCombatantNodes()) do
		TokenManager3.setSaveOverlay(v,0, true); 
	end
	-- END
end

function nextRound(nRounds)
	if not Session.IsHost then
		return;
	end
	
	OldnextRound(nRounds);
	-- KEL Clear saves
	for _,v in pairs(CombatManager.getCombatantNodes()) do
		TokenManager3.setSaveOverlay(v,0,true); 
	end
	-- END
end

-- function deleteCombatant(v)
	-- Perform any pre-delete activities
	-- CombatManager.onPreDeleteCombatantEvent(v);

	-- Clear any effects first, so that saves aren't triggered when initiative advanced
	-- DB.deleteChildren(v, "effects");

	-- Clear NPC wounds, so that ruleset turn end dying checks aren't triggered when initiative advanced
	-- if not CombatManager.isPC(v) and DB.getChild(v, "wounds") then
		-- DB.setValue(v, "wounds", "number", 0);
		-- KEL
		-- DB.setValue(v, "injury", "number", 0);
		-- END
	-- end

	-- Move to the next actor, if this CT entry is active
	-- if CombatManager.isActive(v) then
		-- CombatManager.nextActor();
	-- end

	-- Delete the database node and close the window
	-- DB.deleteNode(v);
-- end

function deleteCleanup(v)
	-- Clear any effects first, so that saves aren't triggered when initiative advanced
	DB.deleteChildren(v, "effects");

	-- Clear NPC wounds, so that ruleset turn end dying checks aren't triggered when initiative advanced
	if not CombatManager.isPlayerCT(v) and DB.getChild(v, "wounds") then
		DB.setValue(v, "wounds", "number", 0);
		-- KEL
		DB.setValue(v, "injury", "number", 0);
		-- END
	end

	-- Move to the next actor, if this CT entry is active
	if CombatManager.isActive(v) then
		CombatManager.nextActor();
	end
end

function helperRollEntryInit(tInit)
	if not tInit or not tInit.nodeEntry then
		return;
	end
	
	-- KEL FFOS
	local rActor = ActorManager.resolveActor(tInit.nodeEntry);
	local nCurrent = DB.getValue("combattracker.round", 0);
	local sOptFFOS = OptionsManager.getOption("FFOS");
	local bHasUncDodge = false;
	if (sOptFFOS == "on") and (nCurrent == 0) then
		local nodeSource;
		if ActorManager.isPC(rActor) then
			nodeSource = ActorManager.getCreatureNode(rActor);
			for _,v in ipairs(DB.getChildList(nodeSource, "specialabilitylist")) do
				local sAbilityname = string.lower(DB.getValue(v, "name", ""));
				if string.match(sAbilityname, "improved uncanny dodge") or string.match(sAbilityname, "uncanny dodge") then
					bHasUncDodge = true;
				end
			end
		else
			nodeSource = ActorManager.getCTNode(rActor);
			local sAbilityname = string.lower(DB.getValue(nodeSource, "specialqualities", ""));
			if string.match(sAbilityname, "improved uncanny dodge") or string.match(sAbilityname, "uncanny dodge") then
				bHasUncDodge = true;
			end
		end
	end
	-- END
	
	if tInit.nInitMatch then
		DB.setValue(tInit.nodeEntry, "initresult", "number", tInit.nInitMatch);
		-- KEL FFOS
		if sOptFFOS == "on" then
			if nCurrent == 0 and not bHasUncDodge then
				EffectManager.addEffect("", "", tInit.nodeEntry, { sName = "Flatfooted", nDuration = 1, nInit = tInit.nInitMatch, nGMOnly = 1 }, false);
			end
		end
		-- END
		return;
	end

	tInit.nTotal = CombatManager.helperRollRandomInit(tInit);
	DB.setValue(tInit.nodeEntry, "initresult", "number", tInit.nTotal);
	
	-- KEL FFOS
	if CombatManager.isPlayerCT(tInit.nodeEntry) then
		if sOptFFOS == "on" then
			if nCurrent == 0 and not bHasUncDodge then
				EffectManager.addEffect("", "", tInit.nodeEntry, { sName = "Flatfooted", nDuration = 1, nInit = tInit.nTotal, nGMOnly = 0 }, false);
			end
		end
	else
		if sOptFFOS == "on" then
			if nCurrent == 0 and not bHasUncDodge then
				EffectManager.addEffect("", "", tInit.nodeEntry, { sName = "Flatfooted", nDuration = 1, nInit = tInit.nTotal, nGMOnly = 1 }, false);
			end
		end
	end
	-- END

	local rMessage = {
		font = "systemfont",
		icon = "portrait_gm_token",
		type = "init",
		text = string.format("[INIT] %s", DB.getValue(tInit.nodeEntry, "name", "")),
		diemodifier = tInit.nTotal,
		diceskipexpr = true,
		secret = true,
	};
	if (tInit.sSuffix or "") ~= "" then
		rMessage.text = string.format("%s %s", rMessage.text, tInit.sSuffix);
	end
	Comm.addChatMessage(rMessage);
end