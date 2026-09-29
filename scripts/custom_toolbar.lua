-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- luacheck: globals TokenManagerKel
-- luacheck: globals clearWounds clearSaves

function onTabletopInit()
    ToolbarManager.registerButton("image_clearwounds",
        {
            sType = "action",
            sIcon = "tool_clearwounds",
            sTooltipRes = "image_tooltip_toolbarclearwounds",
			bHostVisibleOnly = true,
            fnActivate = clearWounds,
        });
    ToolbarManager.registerButton("image_clearsaves",
        {
            sType = "action",
            sIcon = "tool_clearsaves",
            sTooltipRes = "image_tooltip_toolbarclearsaves",
			bHostVisibleOnly = true,
            fnActivate = clearSaves,
        });
end

function clearWounds(c)	
	local cImage = WindowManager.callOuterWindowFunction(c.window, "getImage");
	for _,v in pairs(CombatManager.getCombatantNodes()) do	
		TokenManager3.setDeathOverlay(v,0, true); 	
	end
	cImage.setFocus();
end

function clearSaves(c)	
	local cImage = WindowManager.callOuterWindowFunction(c.window, "getImage");
	for _,v in pairs(CombatManager.getCombatantNodes()) do	
		TokenManager3.setSaveOverlay(v,0, true); 	
	end	
	cImage.setFocus();
end