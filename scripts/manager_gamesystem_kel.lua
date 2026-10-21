-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Ruleset action types

function onInit()
	-- GameSystem.actions["fortification"] = { };
	GameSystem.getStabilizationRoll = getStabilizationRoll;
	ModifierManager.addModWindowPresets({ { sCategory = "general", tPresets = { "ADV", "DISADV" } } });
	ModifierManager.addKeyExclusionSets({ { "ADV", "DISADV" } });
end

function getStabilizationRoll(rActor)
	local rRoll = { sType = "stabilization", sDesc = "[STABILIZATION]" };

	if DataCommon.isPFRPG() then
		rRoll.aDice = DiceRollManager.getActorDice({ "d20" }, rActor);
		rRoll.nMod = ActorManager35E.getAbilityBonus(rActor, "constitution");

		local nHP = GameManager.getRecordFieldValueLinked(rActor, "hptotal", 0);
		local nWounds = GameManager.getRecordFieldValueLinked(rActor, "wounds", 0);
		local nInjury = GameManager.getRecordFieldValueLinked(rActor, "injury", 0);

		if nHP > 0 and nWounds + nInjury > nHP then
			rRoll.sDesc = string.format("%s [at %+d]", rRoll.sDesc, (nHP - (nWounds + nInjury)));
			rRoll.nMod = rRoll.nMod + (nHP - (nWounds + nInjury));
		end
	else
		rRoll.aDice = DiceRollManager.getActorDice({ "d100" }, rActor);
		rRoll.nMod = 0;
	end

	return rRoll;
end