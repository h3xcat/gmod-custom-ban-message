CBM = CBM or {} -- Global table
-- ----------------------------------------------------------
-- ----------------------- START_CONFIG --------------------- 
-- ----------------------------------------------------------
--[[
===== Ban Message Variables =====
ban_admin       The admin who banned the user. ex. "Admin Name(STEAM_0:0:0)".
ban_name        The name of when the user was banned, not the current one.".
ban_reason      The reason of the ban.
ban_time        The time the user was banned at.
ban_unban       The time the user going to be unbanned.
ban_timeleft    The remaining time till unban.
ban_duration    The duration of ban was given.
user_name       The current user name.
user_steamid    The current user steamid.
user_ip         The IP of the user.
]]

CBM.msgBan = 
[[================================
      BANNED FROM SERVER
================================
Time Remaining:
    {{ ban_timeleft }}
Admin Name:
    {{ ban_admin }}
Reason:
    {{ ban_reason }}
]]

--[[
===== WrongPass Message Variables =====
user_pass     The pass that the user has entered.
user_name     The current user name.
user_steamid  The current user steamid.
user_ip       The IP of the user.
]]
CBM.msgWrongPass = [[Password is incorrect!]]

--[[
===== WhiteList Message Variables =====
user_name      The current user name.
user_steamid   The current user steamid.
user_ip        The IP of the user.
]]
CBM.msgWhitelist = [[You're not in the whitelist.]]



-- WhiteList Stuff
CBM.whitelistEnabled = true
CBM.whitelist = {
	"STEAM_0:0:0",
	"STEAM_0:0:0",
}
-- ----------------------------------------------------------
-- ----------------------- END_CONFIG ----------------------- 
-- ----------------------------------------------------------

-- Helper Functions
local function SecondsFormat(X)
    if X < 0 then return "" end
    local date = os.date("!*t", X)
    local outPattern = "%d year(s) %d day(s) %.2d:%.2d:%.2d"
    
    date.yday = (date.yday - 1)
    
    date.year = date.year - 1970
    return string.format(outPattern, date.year, date.yday, date.hour, date.min, date.sec)
end
local function tosteamid(cid)
  local steam64=tonumber(cid:sub(2))
  local a = steam64 % 2 == 0 and 0 or 1
  local b = math.abs(6561197960265728 - steam64 - a) / 2
  local sid = "STEAM_0:" .. a .. ":" .. (a == 1 and b -1 or b)
  return sid
end

-- CheckPassword Hook (the main proccess of this addon)
hook.Add("CheckPassword", "CBM_Check", function( steamID64, ipAddress, svPass, clPass, name )
	local msg, params = "", {}
	local steamID = tosteamid(steamID64)
	if ULib and ULib.bans[ steamID ] then -- Check if user is banned by ULX.
		local banData = ULib.bans[ steamID ]
		local banDataUnban = tonumber(banData.unban)
		local banDataTime = tonumber(banData.time)
		
		msg = CBM.msgBan
		
		params["ban_time"] = banDataTime and (banDataTime > 0 and os.date('%c', banDataTime)) or "Undefined"
		params["ban_unban"] = banDataUnban and (banDataUnban > 0 and os.date('%c', banDataUnban) or "Permanent") or "Undefined"
		params["ban_timeleft"] = banDataUnban and ( banDataUnban > 0 and SecondsFormat( banDataUnban - os.time() ) or "Permanent" ) or "Undefined"
		params["ban_duration"] = banDataUnban and banDataTime and ( banDataUnban > 0 and ( SecondsFormat( banDataUnban - banDataTime ) ) or "Permanent" ) or "Undefined"
		params["user_steamid"] = steamID or "Undefined"
		params["user_ip"] = ipAddress or "Undefined"
		params["ban_reason"] = banData.reason or "Unspecified"
		params["ban_admin"] = banData.admin or "(Console)"
		params["ban_name"] = banData.name or name or "Undefined"
		params["user_name"] = name or "Undefined"
	elseif #svPass > 0 and clPass ~= svPass then -- Check if user has entered correct password when sv_password is set.
		msg = CBM.msgWrongPass
		
		params["user_pass"] = clPass or ""
		params["user_steamid"] = steamID or "Undefined"
		params["user_ip"] = ipAddress or "Undefined"
		params["user_name"] = name or "Undefined"
	elseif CBM.whitelistEnabled and not table.HasValue(CBM.whitelist, steamID) then -- Check if user in whitelist when whitelist is enabled.
		msg = CBM.msgWhitelist
		
		params["user_steamid"] = steamID or "Undefined"
		params["user_ip"] = ipAddress or "Undefined"
		params["user_name"] = name or "Undefined"
	else -- Since user has passed all checks, allow user to enter the server.
		return true
	end
	
	for k,v in pairs(params) do
		msg = string.Replace(msg, "{{ "..k.." }}", v)
	end
	return false, msg
end)
