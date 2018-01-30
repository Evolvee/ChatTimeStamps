-- ChatTimestamps by Varstahl
--

local CTS_MainFrame;
local CTS_Hook_FCF_OTW;
local CTS_Frames = {};

function ChatTimestamps_Print(msg)
    if (DEFAULT_CHAT_FRAME) then
      DEFAULT_CHAT_FRAME:AddMessage(msg, 1.0, 1.0, 0);
    else
      UIErrorsFrame:AddMessage(msg, 1.0, 1.0, 0, 1.0, UIERRORS_HOLD_TIME);
    end
end

function ChatTimestamps_StripZero(hour)
	if ("0" == string.sub(hour,1,1)) then hour = string.sub(hour, 2); end;
	return hour;
end

function ChatTimestamps_AddZero(hm)
	return string.sub("0"..hm,-2);
end

function ChatTimestamps_ServerOffset()
	local st, lt = GetGameTime();
	lt = tonumber(date("%H"));

	local offset = st-lt;

	if (-12 > offset) then
		offset = st-lt+24;
	elseif (12 < offset) then
		offset = st-lt-24;
	end

	return offset * 3600;
end

function ChatTimestamps_AddTimeStamp(msg)
	if not (msg == nil) then
		local locFormat = ChatTimestampsSettings.Format;
		local sh, sm = GetGameTime();
		local offset = time() + ChatTimestampsSettings.Offset;

		if (nil ~= string.find(locFormat,"#H")) then
			locFormat = string.gsub(locFormat, "#H", ChatTimestamps_StripZero(date("%H", offset)));
		end
		if (nil ~= string.find(locFormat,"#I")) then
			locFormat = string.gsub(locFormat, "#I", ChatTimestamps_StripZero(date("%I", offset)));
		end
		if (nil ~= string.find(locFormat,"@H")) then
			locFormat = string.gsub(locFormat, "@H", ChatTimestamps_AddZero(sh));
		end
		if (nil ~= string.find(locFormat,"$H")) then
			locFormat = string.gsub(locFormat, "$H", sh);
		end
		if ((nil ~= string.find(locFormat,"@I")) or (nil ~= string.find(locFormat,"$I"))) then
			local ish = sh;
			if (11 < ish) then ish = ish - 12; end
			if (0 == ish) then ish = 12; end
			locFormat = string.gsub(locFormat, "@I", ChatTimestamps_AddZero(ish));
			locFormat = string.gsub(locFormat, "$I", ish);
		end
		if (nil ~= string.find(locFormat,"@M")) then
			locFormat = string.gsub(locFormat, "@M", ChatTimestamps_AddZero(sm));
		end
		if ((nil ~= string.find(locFormat,"@p")) or (nil ~= string.find(locFormat,"@P"))) then
			local ampm; if (12 > sh) then ampm = "AM"; else ampm = "PM"; end
			locFormat = string.gsub(locFormat, "@p", ampm);
			locFormat = string.gsub(locFormat, "@P", string.lower(ampm));
		end
		if (nil ~= string.find(locFormat,"%P")) then
			locFormat = string.gsub(locFormat, "%%P", string.lower(date("%p", offset)));
		end
		local _, ms = math.modf(GetTime());
ms = string.sub(ms, 3, 5);
msg = date(locFormat, offset)..":" .. ms .. " " ..msg;  -- TimeStamp Format
		-- date(locFormat, time() + ChatTimestampsSettings.Offset)
	end
	return msg;
end

function ChatTimestamps_ChatFrame_AddMessage(frame, msg, ...)
  if CTS_Frames and not CTS_Frames[frame] then return end
  CTS_Frames[frame](frame, ChatTimestamps_AddTimeStamp(msg), ...);
--  CTS_Frames[frame].AddMessage(frame, , ...);
end

function ChatTimestamps_OnEvent()
	if not (ChatTimestampsSettings) then
		-- Default Settings
		ChatTimestampsSettings               = { };
		ChatTimestampsSettings.Format        = "[%H:%M:%S]";
		ChatTimestampsSettings.Offset        = 0;
	end

	if (nil == ChatTimestampsSettings.Offset) then
		ChatTimestampsSettings.Offset = 0;
	end

	ChatTimestamps_HookAllChatFrames();
end

function ChatTimestamps_OnLoad()

        -- Register the slash command
        SlashCmdList["CHATTIMESTAMPS"] = function(msg)
          ChatTimestamps_SlashCommand(msg);
        end;
        SLASH_CHATTIMESTAMPS1 = "/chattimestamps";
        SLASH_CHATTIMESTAMPS2 = "/cts";

        CTS_MainFrame = CreateFrame("Frame", "ChatTimestampsFrame");
        CTS_MainFrame:SetScript("OnEvent", ChatTimestamps_OnEvent);
        CTS_MainFrame:RegisterEvent("VARIABLES_LOADED");

        ChatTimestamps_Print("ChatTimestamps 1.8 loaded");
end

function ChatTimestamps_ProcessFrame(frame)
  if not CTS_Frames[frame] then
    CTS_Frames[frame] = frame.AddMessage
    frame.AddMessage = ChatTimestamps_ChatFrame_AddMessage;
  end
  return frame
end

function ChatTimestamps_HookAllChatFrames()
  -- Add static windows
  for i=1,NUM_CHAT_WINDOWS do
    local frame = getglobal("ChatFrame"..i);
    CTS_Frames[frame] = frame.AddMessage
    frame.AddMessage = ChatTimestamps_ChatFrame_AddMessage;
  end

  -- Add dynamically created windows
  CTS_Hook_FCF_OTW = FCF_OpenTemporaryWindow
  FCF_OpenTemporaryWindow = function(...)
      local frame = CTS_Hook_FCF_OTW(...);
      return ChatTimestamps_ProcessFrame(frame)
  end
end

function ChatTimestamps_SlashCommand(msg)
	-- Check the command
	if (msg) then
		local command = string.trim(msg);
		local params = "";

		if (string.find(command," ") ~= nul) then
			command = string.sub(command,0,string.find(command," ")-1);
			params  = string.trim(string.sub(msg,string.find(msg,command)+string.len(command)));
			command = string.lower(command);
		end

		if ("format" == command) then
			if (0 == string.len(params)) then
				ChatTimestamps_Print("ChatTimestamps Format: "..ChatTimestampsSettings.Format);
			else
				params = string.gsub(params,"||","|");
				if (pcall(date, string.gsub(params, "%%P", "%p"))) then
					ChatTimestampsSettings.Format = params;
					ChatTimestamps_Print("ChatTimestamps Format set to: \""..params.."\"");
				else
					ChatTimestamps_Print("ChatTimestamps Format: \""..params.."\" is invalid");
				end
			end
		elseif ("serveroffset" == command) then
			ChatTimestamps_Print("The server offset is of approximately "..ChatTimestamps_ServerOffset().." seconds");
		elseif ("offset" == command) then
			if (string.len(params) > 0) then
				if ((nil ~= tonumber(params)) and (tonumber(params) == math.floor(params))) then
					local offset = tonumber(params);
					ChatTimestampsSettings.Offset = offset;
					if (0 < offset) then offset = "+" .. offset; end
					ChatTimestamps_Print("ChatTimestamps Offset now set to: "..offset);
				else
					ChatTimestamps_Print("ChatTimestamps Offset parameter must be an integer number of seconds, you defined: \""..params.."\"");
				end
			else
				if (0 == ChatTimestampsSettings.Offset) then
					ChatTimestamps_Print("ChatTimestamps Offset is not set");
				else
					ChatTimestamps_Print("ChatTimestamps Offset set to: "..ChatTimestampsSettings.Offset);
				end
			end
		else
			ChatTimestamps_Print("ChatTimestamps Options:");
			ChatTimestamps_Print("/cts format [timeformat] (default \"[%H:%M:%S]\") - show/set timestamp format");
			ChatTimestamps_Print("/cts offset [seconds] - show/set timestamp offset, expressed in seconds");
			ChatTimestamps_Print("/cts serveroffset - show the (approximated) offset between local time and server time");
		end
	end
end

ChatTimestamps_OnLoad();

--
local backup_strreplace = strreplace;
function strreplace(text, pattern, replacement, count)
  if(pattern == "$time") then
    local _, ms = math.modf(GetTime());
    ms = string.sub(ms, 3, 5);
    return backup_strreplace(text, pattern, replacement .. ":" .. ms, count);
  else
    return backup_strreplace(text, pattern, replacement, count);
  end
end