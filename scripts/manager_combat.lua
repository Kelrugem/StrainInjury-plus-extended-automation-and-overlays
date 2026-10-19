-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local _fnOrigOnNPCPostAdd;
local _fnOrigGetEntryInitRecord;
local _fnOrigNextActor;
local _fnOrigNextRound;

function onInit()
	_fnOrigNextActor = CombatManager.nextActor;
	CombatManager.nextActor = nextActor;
	_fnOrigNextRound = CombatManager.nextRound;
	CombatManager.nextRound = nextRound;
	
	CombatManager.deleteCleanup = CombatManagerKel.deleteCleanup;
end

function nextActor(bSkipBell, bNoRoundAdvance)
	_fnOrigNextActor(bSkipBell, bNoRoundAdvance);
	TokenManagerKel.clearSaveOverlays();
end
function nextRound(nRounds)
	_fnOrigNextRound(nRounds);
	TokenManagerKel.clearSaveOverlays();
end

function deleteCleanup(v)
	-- Clear any effects first, so that saves aren't triggered when initiative advanced
	DB.deleteChildren(v, "effects");

	-- Clear NPC wounds, so that ruleset turn end dying checks aren't triggered when initiative advanced
	if not ActorManager.isPC(v) and DB.getChild(v, "wounds") then
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
