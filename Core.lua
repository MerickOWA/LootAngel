SLASH_RELOADUI1 = "/rl"
SlashCmdList.RELOADUI = ReloadUI

SLASH_FRAMESTK1 = "/fs"
SlashCmdList.FRAMESTK = function()
	LoadAddOn('Blizzard_DebugTools')
	FrameStackTooltip_Toggle()
end

for i = 1, NUM_CHAT_WINDOWS do
	_G["ChatFrame"..i.."EditBox"]:SetAltArrowKeyMode(false)
end
-------------------------------------------------------------

local RANDOM_ROLL_PATTERN = RANDOM_ROLL_RESULT:gsub("[().%%+-*?[%]^$]", "%%%1"):gsub("%%%%s", "(.+)"):gsub("%%%%d", "(%%d+)")

function LootAngelFrame_OnLoad(self)
	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("CHAT_MSG_SYSTEM")
end

function LootAngelFrame_OnEvent(self, event, arg1)
	if  (event == "ADDON_LOADED" and arg1 == "LootAngel") then
		self:UnregisterEvent("ADDON_LOADED")
		LootAngel_OnLoad()
	elseif (event == "CHAT_MSG_SYSTEM") then
		LootAngel_CHAT_MSG_SYSTEM(arg1)
	end
end

function LootAngel_OnLoad()
	print("Loot Angel Loaded!")
end

function LootAngel_CHAT_MSG_SYSTEM(msg)
	for name, roll, low, high in msg:gmatch(RANDOM_ROLL_PATTERN) do
		print(name..": Rolled a "..roll.." using from "..low.." to "..high)
	end
end