

local UseSQL = true



local function LogArrest( officer, convict, reason )
	if ( !UseSQL ) then
		if ( !file.Exists("[zk]ar_sys/log", "DATA") ) then
			file.CreateDir("[zk]ar_sys/log")
		end

		if ( !file.Exists("[zk]ar_sys/log/arrestlog.txt", "DATA") ) then
			file.Write("[zk]ar_sys/log/arrestlog.txt")
		end

		local Timestamp = os.time()
		local TimeString = os.date( "[%d/%m/%Y / %H:%M:%S] - " , Timestamp )
		local data = TimeString..officer:Nick().."["..officer:SteamID().."]".." Arrested "..convict:Nick().."["..convict:SteamID().."]".." for "..reason
		file.Append("[zk]ar_sys/log/arrestlog.txt", data )
		file.Append("[zk]ar_sys/log/arrestlog.txt", "\n" )
	else
		if ( !sql.TableExists( "zk_ar_sys_log" ) ) then
			sql.Query("CREATE TABLE zk_ar_sys_log(OfficerSteamID TEXT, ConvictSteamID TEXT, Reason TEXT)")
		end

		sql.Query("INSERT INTO zk_ar_sys_log(OfficerSteamID, ConvictSteamID, Reason) VALUES('"..officer:SteamID().."', '"..convict:SteamID().."', '"..reason.."')")
	end

    MsgC( Color( 255, 170, 80, 255 ), "\n[Zaktak's AR System]: Added convict to Database - ", Color( 255, 80, 50, 255 ) ,convict:Nick().."("..convict:SteamID()..")\n")
end




local function GetStatsWasArrested(ply)
	if ( !UseSQL ) then
		if ( !file.Exists("[zk]ar_sys/log", "DATA") or !file.Exists("[zk]ar_sys/log/arrestlog.txt", "DATA") ) then
			return {"No Info."}
		end

		local file = file.Open( "[zk]ar_sys/log/arrestlog.txt", "r", "DATA" )
		local reasons = {}

		local line = nil
		while ( line ~= "" or line ~= nil ) do
			local line = file:ReadLine()
			if ( line == nil or line == "" ) then break end

			if ( string.find( line, ply:SteamID() ) ) then
				local start, finish = string.find( line, "for" )
				local reason = string.sub( line, finish + 2 )
				reason = string.Trim( reason )

				if ( reasons[reason] == nil ) then
					reasons[reason] = 0
				end

				reasons[reason] = reasons[reason] + 1
			end
		end
		return reasons
	else
		local logs = sql.Query("SELECT * FROM zk_ar_sys_log ")
		local reasons = {}
		for k, v in pairs( logs ) do
			local convictID = v["ConvictSteamID"]
			local reason = v["Reason"]
			if ( convictID == ply:SteamID() ) then
				reasons[reason] = reasons[reason] or 0
				reasons[reason] = reasons[reason] + 1
			end
		end

		return reasons
	end
end


--[[-------------------------------------------------------------------------
Title: plywasarrested( Player calling_ply, Player target_ply )
Desc: Get how many times a player has been in jail.
---------------------------------------------------------------------------]]
local function plywasarrested( calling_ply, target_ply )
	if ( !IsValid(target_ply) ) then return end
	local stats = GetStatsWasArrested(target_ply)
	if ( stats == nil ) then return end

    calling_ply:ChatPrint( "==================================" )

    local c = 0
	for k, v in pairs(stats) do

        if isnumber(v) then
            c = c + v

            local st = " times."
	        if ( v == 1 ) then st = " time." end
	        calling_ply:ChatPrint( target_ply:Nick().." was arrested for "..k.." - "..v..st )
        else
            calling_ply:ChatPrint( v )
        end
    end

    local st = "time"
    if ( c > 1 or c == 0 ) then
        st = "times"
    end

    timer.Simple( 0.2, function() 
        calling_ply:ChatPrint( "==================================" )
        calling_ply:ChatPrint( target_ply:Nick().." was arrested "..c.." "..st.." in total." )
    end)
end



hook.Add( "PlayerSay", "ZK_AR_SYS_OnSay", function(ply, text)
	local AllowedToArrestReport = { TEAM_SCENLISTED, TEAM_SCNCO, TEAM_SCCOM, TEAM_SCEXO, TEAM_SCCMDR, TEAM_SCSPEC01, TEAM_SCSPEC02, TEAM_GADMIRAL, TEAM_ADMIRAL, TEAM_VADMIRAL, TEAM_RADMIRAL, TEAM_RCOMMO }

    if ( string.find( string.lower(text), "/ar " ) ) then
		if ( string.find( string.lower( engine.ActiveGamemode() ), "starwars" ) ) then
			print("[Zaktak AR System] DarkRP Gamemode - True")
			if ( !table.HasValue( AllowedToArrestReport, ply:Team() ) ) then return end
			print("[Zaktak AR System] DarkRP - Allowed")
		end
		
        local start, end_cmd = string.find( string.lower(text), "/ar" )

        local string_given = string.lower( string.sub( text, end_cmd + 2 ) )
        
        local args = string.Explode( " ", string_given )
        local name = args[1]
        local reason = args[2]

		for i = 3, #args do
			if args[i] ~= nil then
				reason = reason .. " " .. args[i] 
			end
		end

        local ply_exists = false
        local convict = nil
        for k, ply in ipairs( player.GetAll() ) do
            if string.find( string.lower(ply:Nick()), name ) then
                ply_exists = true
                convict = ply
            end
        end

        if not ply_exists then ply:ChatPrint("Player not found.") return "" end

        PrintMessage( HUD_PRINTTALK, "[AR]: "..tostring(convict:Nick()).." was arrested for "..reason )
        LogArrest( ply, convict, reason )
        return ""
    elseif ( string.find( string.lower(text), "/arshow " ) ) then
        local start, end_cmd = string.find( string.lower(text), "/arshow" )

        local string_given = string.lower( string.sub( text, end_cmd + 2 ) )
        local args = string.Explode( " ", string_given )
        local name = args[1]

        local ply_exists = false
        local convict = nil
        for k, ply in ipairs( player.GetAll() ) do
            if string.find( string.lower(ply:Nick()), name ) then
                ply_exists = true
                convict = ply
            end
        end

        if not ply_exists then ply:ChatPrint("Player not found.") return "" end
        plywasarrested( ply, convict )
        return ""
    elseif ( string.find( string.lower(text), "/arhelp" ) ) then
        timer.Simple( 0.2, function() 
			ply:ChatPrint( "Zaktak's Arrest Report System Help: " )
			ply:ChatPrint( "/ar <player> <reason> - Arrest Report a player." )
			ply:ChatPrint( "/arshow <player> - Show arrest list of a player." )
		end)
        return ""
    end
end)
