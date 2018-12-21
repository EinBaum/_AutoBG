
local name = "_AutoBG"
local version = "1.0.1"

local settings = {
	join = "Auto-join battlegrounds when they start",
	leave = "Instantly leave finished BGs",
	queue = "Queue BGs when talking to battlemasters",
	rezz = "Release spirit when dying in BGs"
}

local defaults = {
	join = false,
	leave = true,
	queue = true,
	rezz = true,
}

--------------------------------------------------------------------------------

local function print(text)
	DEFAULT_CHAT_FRAME:AddMessage(
		string.format("[%s] %s", name, text), 0.7, 1, 0.8)
end
local function onoff(value, on, off)
	return value and "|cFF00FF00" .. on .. "|r" or "|cFFFF0000" .. off .. "|r"
end

local function initialize()
	if not _autobg_settings then
		_autobg_settings = {}
	end
	for k, v in settings do
		if _autobg_settings[k] == nil then
			_autobg_settings[k] = defaults[k]
		end
	end
	print(string.format("%s loaded. Options: /abg", version))
end

--------------------------------------------------------------------------------

local function join()
	for i = 1, MAX_BATTLEFIELD_QUEUES do
		if GetBattlefieldStatus(i) == "confirm" then
			AcceptBattlefieldPort(i, 1)
			StaticPopup_Hide("CONFIRM_BATTLEFIELD_ENTRY")
		end
	end
end

local function leave()
	local winner = GetBattlefieldWinner()
	if winner ~= nil then
		LeaveBattlefield()
	end
end

local function queue_gossip()
	local _, gossip = GetGossipOptions()
	if gossip == "battlemaster" then
		SelectGossipOption(1)
	end
end

local function queue_join()
	local grp = IsPartyLeader() and (GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0)
	JoinBattlefield(0, grp)
end

local function rezz()
	if GetBattlefieldStatus(1) == "active" and not HasSoulstone() then
		RepopMe()
	end
end

--------------------------------------------------------------------------------

local f1 = CreateFrame("frame")
f1:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
f1:RegisterEvent("GOSSIP_SHOW")
f1:RegisterEvent("BATTLEFIELDS_SHOW")
f1:RegisterEvent("PLAYER_DEAD")
f1:RegisterEvent("ADDON_LOADED")
f1:SetScript("OnEvent", function()
	if event == "UPDATE_BATTLEFIELD_STATUS" then
		if _autobg_settings.join then join() end
		if _autobg_settings.leave then leave() end
	elseif event == "GOSSIP_SHOW" then
		if _autobg_settings.queue then queue_gossip() end
	elseif event == "BATTLEFIELDS_SHOW" then
		if _autobg_settings.queue then queue_join() end
	elseif event == "PLAYER_DEAD" then
		if _autobg_settings.rezz then rezz() end
	elseif event == "ADDON_LOADED" and string.lower(arg1) == string.lower(name) then
		initialize()
		f1:UnregisterEvent("ADDON_LOADED")
	end
end)

--------------------------------------------------------------------------------

SLASH_AUTOBG1 = "/abg"
SLASH_AUTOBG2 = "/autobg"
SlashCmdList["AUTOBG"] = function(msg)
	if _autobg_settings[msg] ~= nil then
		local newval = not _autobg_settings[msg]
		_autobg_settings[msg] = newval
		print(string.format("%s %s.", msg, onoff(newval, "enabled", "disabled")))
	else
		for k, v in _autobg_settings do
			print(string.format("%s: %s (%s)", k, onoff(v, "[ON]", "[OFF]"), settings[k]))
		end
	end
end
