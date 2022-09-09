-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	super.super.onInit();
	self.onHealthChanged();
	
	-- Register the deletion menu item for the host
	registerMenuItem(Interface.getString("list_menu_deleteitem"), "delete", 6);
	registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 6, 7);
end
-- KEL Delete function in CoreRPG as reference
function delete()
	local node = getDatabaseNode();
	if not node then
		close();
		return;
	end
	
	-- Clear any effects first, so that saves aren't triggered when initiative advanced
	DB.deleteChildren(node, "effects");

	-- Clear NPC wounds, so that ruleset turn end dying checks aren't triggered when initiative advanced
	-- KEL
	if wounds and injury and not self.isPC() then
		DB.setValue(node, "wounds", "number", 0);
		DB.setValue(node, "injury", "number", 0);
	end
	-- END
	-- Move to the next actor, if this CT entry is active
	if self.isActive() then
		CombatManager.nextActor();
	end

	-- Delete the database node and close the window
	local cList = windowlist;
	node.delete();

	-- Update list information (global subsection toggles)
	cList.onVisibilityToggle();
end
-- END
function onHealthChanged()
	local rActor = ActorManager.resolveActor(getDatabaseNode());
	local _,sStatus,sColor = ActorHealthManager.getHealthInfo(rActor);
	
	wounds.setColor(sColor);
	injury.setColor(sColor);
	status.setValue(sStatus);
	
	if not self.isPC() then
		idelete.setVisibility(ActorHealthManager.isDyingOrDeadStatus(sStatus));
	end
end

function linkPCFields()
	local nodeChar = link.getTargetDatabaseNode();
	if nodeChar then
		name.setLink(nodeChar.createChild("name", "string"), true);
		senses.setLink(nodeChar.createChild("senses", "string"), true);

		hp.setLink(nodeChar.createChild("hp.total", "number"));
		hptemp.setLink(nodeChar.createChild("hp.temporary", "number"));
		injury.setLink(nodeChar.createChild("hp.injury", "number"));
		wounds.setLink(nodeChar.createChild("hp.wounds", "number"));

		if DataCommon.isPFRPG() then
			type.addSource(DB.getPath(nodeChar, "alignment"), true);
		else
			alignment.setLink(nodeChar.createChild("alignment", "string"));
		end
		type.addSource(DB.getPath(nodeChar, "size"), true);
		type.addSource(DB.getPath(nodeChar, "race"));
		
		grapple.setLink(nodeChar.createChild("attackbonus.grapple.total", "number"), true);
		
		ac_final.setLink(nodeChar.createChild("ac.totals.general", "number"), true);
		ac_touch.setLink(nodeChar.createChild("ac.totals.touch", "number"), true);
		ac_flatfooted.setLink(nodeChar.createChild("ac.totals.flatfooted", "number"), true);
		cmd.setLink(nodeChar.createChild("ac.totals.cmd", "number"), true);
		
		fortitudesave.setLink(nodeChar.createChild("saves.fortitude.total", "number"), true);
		reflexsave.setLink(nodeChar.createChild("saves.reflex.total", "number"), true);
		willsave.setLink(nodeChar.createChild("saves.will.total", "number"), true);
		
		sr.setLink(nodeChar.createChild("defenses.sr.total", "number"), true);

		init.setLink(nodeChar.createChild("initiative.total", "number"), true);
	end
end

function onSectionChanged(sKey)
	local sSectionName = "sub_" .. sKey;

	local cSection = self[sSectionName];
	if cSection then
		local bShow = self.getSectionToggle(sKey);

		if bShow then
			local sSectionClass = "ct_section_" .. sKey;
			if sKey == "active" then
				if self.isRecordType("npc") then
					sSectionClass = sSectionClass .. "_npc";
				end
			end
			cSection.setValue(sSectionClass, getDatabaseNode());
		else
			cSection.setValue("", "");
		end
		cSection.setVisible(bShow);
	end

	local sSummaryName = "summary_" .. sKey;
	local cSummary = self[sSummaryName];
	if cSummary then
		cSummary.onToggle();
	end
end
