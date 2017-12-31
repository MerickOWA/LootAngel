--for i = 1, NUM_CHAT_WINDOWS do
--	_G["ChatFrame"..i.."EditBox"]:SetAltArrowKeyMode(false)
--end
-------------------------------------------------------------

local RANDOM_ROLL_PATTERN = RANDOM_ROLL_RESULT:gsub("[().%%+-*?[%]^$]", "%%%1"):gsub("%%%%s", "(.+)"):gsub("%%%%d", "(%%d+)")
local rollHistory = {}
local rollCounts = {}

function LootAngel_OnCommand(cmd)
	if (cmd == "show") then
		LootAngelFrame:Show()
	end
	print("Command: "..cmd)
end

function LootAngelFrame_OnLoad(self)
	self:RegisterForDrag("LeftButton")
	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("CHAT_MSG_SYSTEM")
	rollHistory = {}
	rollCounts = {}
end

function LootAngelFrame_OnEvent(self, event, arg1)
	if  (event == "ADDON_LOADED" and arg1 == "LootAngel") then
		self:UnregisterEvent("ADDON_LOADED")
		LootAngel_OnLoad()
	elseif (event == "CHAT_MSG_SYSTEM") then
		LootAngel_CHAT_MSG_SYSTEM(arg1)
	end
end

function LootAngelFrame_OnDragStart(self)
	self:StartMoving()
end

function LootAngelFrame_OnDragStop(self)
	self:StopMovingOrSizing()
end

function LootAngel_OnLoad()
	print("Loot Angel Loaded!")
end

function LootAngel_CHAT_MSG_SYSTEM(msg)
	for name, roll, low, high in msg:gmatch(RANDOM_ROLL_PATTERN) do
		LootAngel_OnRoll(name, roll, low, high)
	end
end

function LootAngel_OnRoll(name, roll, low, high)

	local count = rollCounts[name] and rollCounts[name] + 1 or 1

	table.insert(rollHistory, {
		name = name,
		roll = tonumber(roll),
		low = tonumber(low),
		high = tonumber(high),
		count = count
	})
	rollCounts[name] = count

	LootAngel_UpdateUI()
end

function LootAngel_UpdateUI()
	table.sort(rollHistory, function(a, b) return a.roll > b.roll end)

	for i, data in pairs(rollHistory) do
		print(data.name..": Rolled a "..data.roll.." using from "..data.low.." to "..data.high.." for the "..data.count.." time")
	end
end

-- Slash commands

SLASH_RELOADUI1 = "/rl"
SlashCmdList.RELOADUI = ReloadUI

SLASH_FRAMESTK1 = "/fs"
SlashCmdList.FRAMESTK = function()
	LoadAddOn('Blizzard_DebugTools')
	FrameStackTooltip_Toggle()
end

SLASH_LOOTANGEL1 = "/la"
SLASH_LOOTANGEL2 = "/lootangel"
SlashCmdList.LOOTANGEL = LootAngel_OnCommand