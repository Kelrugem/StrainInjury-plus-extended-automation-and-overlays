-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- function onInit()
	-- local tOverlayButtons = {"", "clear_wounds", "clear_saves"};
	-- ToolbarManager.addList(subwindow, tOverlayButtons, "right");
-- end

function onTabletopInit()
    ToolbarManager.registerButton("image_clearwounds",
        {
            sType = "action",
            sIcon = "tool_clearwounds",
            sTooltipRes = "image_tooltip_toolbarclearwounds",
			-- bHostVisibleOnly = true,
            fnActivate = clearWounds,
        });
    ToolbarManager.registerButton("image_clearsaves",
        {
            sType = "action",
            sIcon = "tool_clearsaves",
            sTooltipRes = "image_tooltip_toolbarclearsaves",
			-- bHostVisibleOnly = true,
            fnActivate = clearSaves,
        });
		
	-- local tOverlayButtons = {"", "clear_wounds", "clear_saves"};
	-- ToolbarManager.addList(subwindow, tOverlayButtons, "right");
end

function clearWounds()	
	for _,v in pairs(CombatManager.getCombatantNodes()) do	
		TokenManager3.setDeathOverlay(v,0, true); 
		updateDisplay();
		Debug.chat("BUTTON PUSHED");		
	end
	-- function updateDisplay()	
	-- end
end

function clearSaves()	
	for _,v in pairs(CombatManager.getCombatantNodes()) do	
		TokenManager3.setSaveOverlay(v,0, true); 	
	end	
end