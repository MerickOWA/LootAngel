--for i = 1, NUM_CHAT_WINDOWS do
--	_G["ChatFrame"..i.."EditBox"]:SetAltArrowKeyMode(false)
--end
-------------------------------------------------------------

local RANDOM_ROLL_PATTERN = RANDOM_ROLL_RESULT:gsub("[().%%+-*?[%]^$]", "%%%1"):gsub("%%%%s", "(.+)"):gsub("%%%%d", "(%%d+)")
local currentSession = 1

function LootAngel_OnCommand(cmd)
	if cmd == "show" then
		LootAngelFrame:Show()
	elseif cmd == "clear" then
		LootAngel_Clear()
	elseif cmd == "reset" then
		LootAngelFrame:ClearAllPoints()
		LootAngelFrame:SetPoint("CENTER")
		LootAngelFrame:SetSize(180, 216)
	elseif cmd == "new" then
		LootAngel_NewSession()
	elseif cmd == "prev" then
		LootAngel_PreviousSession()
	elseif cmd == "next" then
		LootAngel_NextSession()
	elseif cmd == "last" then
		LootAngel_LastSession()
	else
		print("Command: "..cmd)
	end
end

function LootAngelFrame_OnLoad(self)
	self:RegisterForDrag("LeftButton")
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

function LootAngelFrame_OnDragStart(self)
	self:StartMoving()
end

function LootAngelFrame_OnDragStop(self)
	self:StopMovingOrSizing()
end

function LootAngel_OnLoad()
	print("Loot Angel Loaded!")

	if LootAngelDB == nil then
		print("Creating new LootAngelDB?")
		LootAngelDB = {}
		LootAngel_Clear()
	else
		LootAngel_LastSession()
	end
end

function LootAngel_CHAT_MSG_SYSTEM(msg)
	for name, roll, low, high in msg:gmatch(RANDOM_ROLL_PATTERN) do
		LootAngel_OnRoll(name, roll, low, high)
	end
end

function LootAngel_OnRoll(name, roll, low, high)

	local rollData = LootAngelDB.sessions[#LootAngelDB.sessions].data

	local count = 1
	for i,item in pairs(rollData) do
		if item.name == name then count=count+1 end
	end

	table.insert(rollData, {
		name = name,
		roll = tonumber(roll),
		low = tonumber(low),
		high = tonumber(high),
		count = count
	})

	table.sort(rollData, function(a, b) return a.roll > b.roll end)
	
	LootAngel_UpdateUI()
end

function LootAngel_Clear()
	LootAngelDB.sessions = {{data={}}}
	currentSession = 1
	LootAngel_UpdateUI()
end

function LootAngel_NewSession()
	table.insert(LootAngelDB.sessions, {data={}})
	currentSession = #LootAngelDB.sessions
	LootAngel_UpdateUI()
end

function LootAngel_NextSession()
	currentSession = math.min(currentSession + 1, #LootAngelDB.sessions)
	LootAngel_UpdateUI()
end

function LootAngel_PreviousSession()
	currentSession = math.max(currentSession - 1, 1)
	LootAngel_UpdateUI()
end

function LootAngel_LastSession()
	currentSession = #LootAngelDB.sessions
	print("Switching to session "..currentSession)
	LootAngel_UpdateUI()
end

function LootAngel_UpdateUI()
	
	local rollData = LootAngelDB.sessions[currentSession].data

	local rollText = ""
	for i, roll in pairs(rollData) do
		local tied = (rollData[i + 1] and roll.roll == rollData[i + 1].roll) or (rollData[i - 1] and roll.roll == rollData[i - 1].roll)
		rollText = rollText .. string.format("|c%s%d|r: |c%s%s%s%s|r\n",
				tied and "ffffff00" or "ffffffff",
				roll.roll,
				((roll.low ~= 1 or roll.high ~= 100) or (roll.count > 1)) and  "ffffcccc" or "ffffffff",
				roll.name,
				(roll.low ~= 1 or roll.high ~= 100) and format(" (%d-%d)", roll.low, roll.high) or "",
				roll.count > 1 and format(" [%d]", roll.count) or "")
	end
	LootAngelRollText:SetText(rollText)
	LootAngelFrameStatusText:SetText(string.format("Session %d: %d Roll(s)", currentSession, #rollData))	
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