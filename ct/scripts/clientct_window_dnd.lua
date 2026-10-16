--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	super.onInit();
	OptionsManager.registerCallback("SHPC", self.updateHealthDisplay);
	OptionsManager.registerCallback("SHNPC", self.updateHealthDisplay);
	self.updateHealthDisplay();
end
function onClose()
	super.onClose();
	OptionsManager.unregisterCallback("SHPC", self.updateHealthDisplay);
	OptionsManager.unregisterCallback("SHNPC", self.updateHealthDisplay);
end

function updateHealthDisplay()
	local sOptSHPC = OptionsManager.getOption("SHPC");
	local sOptSHNPC = OptionsManager.getOption("SHNPC");
	local bShowDetail = (sOptSHPC == "detailed") or (sOptSHNPC == "detailed");
	local bShowStatus = ((sOptSHPC == "status") or (sOptSHNPC == "status")) and not bShowDetail;

	local w = self;
	if sub_header then
		w = sub_header.subwindow;
	end

	-- General
	if w.label_hp then
		w.label_hp.setVisible(bShowDetail);
	end
	if w.label_temp then
		w.label_temp.setVisible(bShowDetail);
	end
	if w.label_wounds then
		w.label_wounds.setVisible(bShowDetail);
	end

	-- KEL
	if w.label_strain then
		w.label_strain.setVisible(bShowDetail);
	end
	if w.label_injury then
		w.label_injury.setVisible(bShowDetail);
	end
	-- END

	w.label_status.setVisible(bShowStatus);

	for _,wChild in pairs(list.getWindows()) do
		wChild.updateHealthDisplay();
	end
end
