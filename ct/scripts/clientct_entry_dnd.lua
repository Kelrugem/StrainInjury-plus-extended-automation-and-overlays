-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	-- KEL
	super.super.onInit();
	-- KEL Darrenan had here onFactionChanged(); Why?
	self.onHealthChanged();
	-- END
end

function onFactionChanged()
	-- KEL
	super.super.onFactionChanged();
	-- END
	updateHealthDisplay();
end

function onHealthChanged()
	local rActor = ActorManager.resolveActor(getDatabaseNode());
	local sColor = ActorHealthManager.getHealthColor(rActor);
	
	if wounds then
		wounds.setColor(sColor);
	end
	-- KEL
    if injury then
		injury.setColor(sColor);
	end
	-- END
	status.setColor(sColor);
end

function updateHealthDisplay()
	local sOption;
	if friendfoe.getStringValue() == "friend" then
		sOption = OptionsManager.getOption("SHPC");
	else
		sOption = OptionsManager.getOption("SHNPC");
	end

	local bShowDetail = (sOption == "detailed");
	local bShowStatus = (sOption == "status");

	status.setVisible(bShowStatus);
	if hp then
		hp.setVisible(bShowDetail);
	end
	if hptemp then
		hptemp.setVisible(bShowDetail);
	end
	-- KEL
	if injury then
		injury.setVisible(bShowDetail);
	end
	-- END
	if wounds then
		wounds.setVisible(bShowDetail);
	end
	local bShowHealthBase = not OptionsManager.isOption("SHPC", "off") or not OptionsManager.isOption("SHNPC", "off");
	healthbase.setVisible(bShowHealthBase);
end