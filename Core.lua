--for i = 1, NUM_CHAT_WINDOWS do
--	_G["ChatFrame"..i.."EditBox"]:SetAltArrowKeyMode(false)
--end
-------------------------------------------------------------

local RANDOM_ROLL_PATTERN = RANDOM_ROLL_RESULT:gsub("[().%%+-*?[%]^$]", "%%%1"):gsub("%%%%s", "(.+)"):gsub("%%%%d", "(%%d+)")
local rollHistory = {}
local rollCounts = {}

function LootAngel_OnCommand(cmd)
	if cmd == "show" then
		LootAngelFrame:Show()
	elseif cmd == "clear" then
		LootAngel_Clear()
	else
		print("Command: "..cmd)
	end
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

function LootAngel_Clear()
	rollCounts = {}
	rollHistory = {}

	LootAngel_UpdateUI()
end

function LootAngel_UpdateUI()
	table.sort(rollHistory, function(a, b) return a.roll > b.roll end)

	local rollText = ""
	for i, roll in pairs(rollHistory) do
		local tied = (rollHistory[i + 1] and roll.roll == rollHistory[i + 1].roll) or (rollHistory[i - 1] and roll.roll == rollHistory[i - 1].roll)
		rollText = rollText .. string.format("|c%s%d|r: |c%s%s%s%s|r\n",
				tied and "ffffff00" or "ffffffff",
				roll.roll,
				((roll.low ~= 1 or roll.high ~= 100) or (roll.count > 1)) and  "ffffcccc" or "ffffffff",
				roll.name,
				(roll.low ~= 1 or roll.high ~= 100) and format(" (%d-%d)", roll.low, roll.high) or "",
				roll.count > 1 and format(" [%d]", roll.count) or "")
	end
	LootAngelRollText:SetText(rollText)
	LootAngelFrameStatusText:SetText(string.format("%d Roll(s)", #rollHistory))	
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