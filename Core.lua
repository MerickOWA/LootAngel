--for i = 1, NUM_CHAT_WINDOWS do
--	_G["ChatFrame"..i.."EditBox"]:SetAltArrowKeyMode(false)
--end
-------------------------------------------------------------

local RANDOM_ROLL_PATTERN = RANDOM_ROLL_RESULT:gsub("[().%%+-*?[%]^$]", "%%%1"):gsub("%%%%s", "(.+)"):gsub("%%%%d", "(%%d+)")
local ITEM_LINK_PATTERN = "|c[%x]*|Hitem[:%d]*|h.-|h|r"
local currentSession = 1

function LootAngel_OnCommand(text)
	local cmd, args = text:match(" *([^ ]*) *(.*)")

	if cmd == "show" then
		LootAngelFrame:Show()
	elseif cmd == "clear" then
		LootAngel_Clear()
	elseif cmd == "reset" then
		LootAngelFrame:ClearAllPoints()
		LootAngelFrame:SetPoint("CENTER")
		LootAngelFrame:SetSize(180, 216)
	elseif cmd == "new" then
		LootAngel_NewSession(args:match(ITEM_LINK_PATTERN))
	elseif cmd == "prev" then
		LootAngel_PreviousSession()
	elseif cmd == "next" then
		LootAngel_NextSession()
	elseif cmd == "last" then
		LootAngel_LastSession()
	elseif cmd == "help" then
		LootAngel_Help()
	else
		LootAngel_Default()
	end
end

function LootAngelFrame_OnLoad(self)
	self:RegisterForDrag("LeftButton")
	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("CHAT_MSG_SYSTEM")
	self:RegisterEvent("CHAT_MSG_RAID_WARNING")
	LootAngelRollText:SetHyperlinksEnabled(true)
end

function LootAngelFrame_OnEvent(self, event, arg1)
	if  (event == "ADDON_LOADED" and arg1 == "LootAngel") then
		self:UnregisterEvent("ADDON_LOADED")
		LootAngel_OnLoad()
	elseif (event == "CHAT_MSG_SYSTEM") then
		LootAngel_CHAT_MSG_SYSTEM(arg1)
	elseif (event == "CHAT_MSG_RAID_WARNING") then
		LootAngel_CHAT_MSG_RAID_WARNING(arg1)
	end
end

function LootAngelFrame_OnDragStart(self)
	self:StartMoving()
end

function LootAngelFrame_OnDragStop(self)
	self:StopMovingOrSizing()
end

function LootAngelFrame_OnHyperlinkEnter(self, link, text)
	--print("Loot Angel OnHyperlinkEnter: ".. (link:gsub("|", "||")).. "  ---  "..(text:gsub("|", "||")))
	--SetItemRef(link, text, self, "LeftButton")
	ShowUIPanel(GameTooltip)
	GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
	GameTooltip:SetHyperlink(link)
	GameTooltip:Show()
end

function LootAngelFrame_OnHyperlinkLeave(self, linkData, link)
	--print("Loot Angel OnHyperlinkLeave")
	HideUIPanel(GameTooltip)
end

function LootAngel_OnLoad()
	print("Loot Angel Loaded!")

	if LootAngelDB == nil then
		print("Creating new LootAngelDB?")
		LootAngelDB = {}
		LootAngel_Clear()
	end

	LootAngelDB.options = LootAngelDB.options or {
		sessionIdleTimeout = 30
	}

	LootAngel_LastSession()
end

function LootAngel_CHAT_MSG_SYSTEM(msg)
	for name, roll, low, high in msg:gmatch(RANDOM_ROLL_PATTERN) do
		LootAngel_OnRoll(name, roll, low, high)
	end
end

function LootAngel_CHAT_MSG_RAID_WARNING(msg)
	local item = msg:match(ITEM_LINK_PATTERN)
	if (item ~= nil) then
		LootAngel_NewSession(item)
	end
end

function LootAngel_OnRoll(name, roll, low, high)

	local now = GetTime()
	local session = LootAngelDB.sessions[#LootAngelDB.sessions]
	local timeSinceLastRoll = session.lastroll and now - session.lastroll

	-- If the last roll in the session was too long ago, then start a new session
	if timeSinceLastRoll and LootAngelDB.options.sessionIdleTimeout and (timeSinceLastRoll < 0 or timeSinceLastRoll > LootAngelDB.options.sessionIdleTimeout) then
		table.insert(LootAngelDB.sessions, {data={}})
		session = LootAngelDB.sessions[#LootAngelDB.sessions]
	end

	local data = session.data

	local count = 1
	for i,item in pairs(data) do
		if item.name == name then count=count+1 end
	end

	table.insert(data, {
		name = name,
		roll = tonumber(roll),
		low = tonumber(low),
		high = tonumber(high),
		count = count
	})

	table.sort(data, function(a, b) return a.roll > b.roll end)

	session.lastroll = now

	-- switch to the current session that the roll was just added to
	-- TODO: Make this an option?
	currentSession = #LootAngelDB.sessions
	LootAngelFrame:Show()
	
	LootAngel_UpdateUI()
end

function LootAngel_Clear()
	LootAngelDB.sessions = {{data={}}}
	currentSession = 1
	LootAngel_UpdateUI()
end

function LootAngel_NewSession(item)
	local session = LootAngelDB.sessions[#LootAngelDB.sessions];

	if session.lastroll ~= nil then
		table.insert(LootAngelDB.sessions, {item=item, data={}})
		currentSession = #LootAngelDB.sessions
	else
		session.item = item;
	end

	LootAngelFrame:Show()	
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
	LootAngel_UpdateUI()
end

function LootAngel_UpdateUI()
	
	local session = LootAngelDB.sessions[currentSession]
	local data = session.data

	local rollText = session.item and session.item.."\n" or ""
	for i, roll in pairs(data) do
		local tied = (data[i + 1] and roll.roll == data[i + 1].roll) or (data[i - 1] and roll.roll == data[i - 1].roll)
		rollText = rollText .. string.format("|c%s%d|r: |c%s%s%s%s|r\n",
				tied and "ffffff00" or "ffffffff",
				roll.roll,
				((roll.low ~= 1 or roll.high ~= 100) or (roll.count > 1)) and  "ffffcccc" or "ffffffff",
				roll.name,
				(roll.low ~= 1 or roll.high ~= 100) and format(" (%d-%d)", roll.low, roll.high) or "",
				roll.count > 1 and format(" [%d]", roll.count) or "")
	end
	LootAngelRollText:SetText(rollText)
	LootAngelFrameStatusText:SetText(string.format("Session %d: %d Roll(s)", currentSession, #data))	
end

function LootAngel_Help()
	print("LootAngel Addon Help")
	print("/la show  - unhide/show the addon window")
	print("/la clear - delete/clear all roll sessions")
	print("/la reset - resets the addon window position and size")
	print("/la new   - force a new roll session to begin")
	print("/la prev  - change the window view to the next older/previous roll session")
	print("/la next  - change the window view to the next newer/next roll session")
	print("/la last  - change the window view to the last/newest roll session")
end

function LootAngel_Default()
	if LootAngelFrame:IsShown() then
		LootAngel_Help()
	else
		LootAngelFrame:Show()
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