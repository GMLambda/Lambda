AddCSLuaFile()

_DEBUG = true

--function print() error() end
USED_LOG_GROUPS = USED_LOG_GROUPS or {}

function GetLogging(group, color)

	USED_LOG_GROUPS[group] = true

	if _DEBUG == false then
		return function(...) end
	end

	local group = group
	local color = color or Color(255, 255, 255)

	return function(...)
		LogGroup(group, color, ...)
	end

end

if _DEBUG then

	local LOG_GROUPS = {}
	local LOG_GROUPS_STR = ""
	local lambda_log = GetConVar("lambda_log") or CreateConVar("lambda_log", "none", FCVAR_REPLICATED + FCVAR_ARCHIVE + FCVAR_NOTIFY, "Enable logging groups seperated by comma")

	local function ProcessLogGroups()

		local val = lambda_log:GetString()
		if val == LOG_GROUPS_STR then
			return
		end

		--print("Log group changed: " .. val)
		LOG_GROUPS = {}
		LOG_GROUPS_STR = val
		local groupList = string.Explode(",", val)
		for _,v in pairs(groupList) do
			local groupVal = string.Trim(v)
			groupVal = string.lower(groupVal)
			--print("Group: " .. groupVal)
			if groupVal == "" then
				continue
			elseif groupVal:lower() == "all" then
				print("Using all groups")
				LOG_GROUPS = {}
				for k,_ in pairs(USED_LOG_GROUPS) do
					LOG_GROUPS[k:lower()] = true
				end
				--PrintTable(LOG_GROUPS)
				return true
			end

			LOG_GROUPS[groupVal] = true
		end
		--PrintTable(LOG_GROUPS)

	end

	local function IsGroupLogActive(group)

		--print("IsGroupLogActive: " .. group)
		ProcessLogGroups()

		group = string.lower(group)

		return LOG_GROUPS[group] == true

	end

	-- Fallback to old method.
	function DbgPrint(...)
		LogGeneric(Color(255, 255, 255), ...)
	end

	function LogGroup(group, color, ...)

		if IsGroupLogActive(group) == false then
			return
		end

		local printResult = ""
		for i,v in ipairs( {...} ) do
			printResult = printResult .. tostring(v) .. "\t"
		end
		printResult = printResult

		local timestamp = string.format("(%.02f)", CurTime())

		if SERVER then
			print(timestamp .. "[SV:" .. group .. "] " .. printResult)
		else
			if epoe and epoe.Print then
				epoe.Print(timestamp .. "[CL:" .. group .. "] " .. printResult)
			else
				print(timestamp .. "[CL:" .. group .. "] " .. printResult)
			end
		end

	end

	function LogGeneric(color, ...)

		local printResult = ""
		for i,v in ipairs( {...} ) do
			printResult = printResult .. tostring(v) .. "\t"
		end
		printResult = printResult

		local timestamp = string.format("(%.02f)", CurTime())

		if SERVER then
			print(timestamp .. "[SV] " .. printResult)
		else
			if epoe and epoe.Print then
				epoe.Print(timestamp .. "[CL] " .. printResult)
			else
				print(timestamp .. "[CL] " .. printResult)
			end
		end

	end

	function DbgError(...)

		local printResult = ""
		for i,v in ipairs( {...} ) do
			printResult = printResult .. tostring(v) .. "\t"
        end

		if SERVER then
			MsgC(Color(0, 179, 255), "[SV] " .. printResult .. "\n")
		else
			if epoe and epoe.Print then
				epoe.Print(printResult)
			else
				print(printResult)
			end
		end

		error(printResult)

	end

	local lastDebugOutput = ""

	function DbgUniquePrint(...)

		-- I know I know this isnt exactly efficient but who gives a fuck, debugging purpose!
		local t = {...}
		local output = table.ToString(t)

		if output ~= lastDebugOutput then
			lastDebugOutput = output
			DbgPrint(unpack(t))
		end

	end

	concommand.Add( "lambda_log_groups", function( ply, cmd, args )
		ProcessLogGroups()
		local activeGroups = {}
		for k,_ in pairs(LOG_GROUPS) do
			table.insert(activeGroups, k)
		end
		print("current = " .. table.concat(activeGroups,","))
		print("All")
		for k,_ in pairs(USED_LOG_GROUPS) do
			print(k)
		end
	end )

else

	function DbgPrint(...) end
	function DbgUniquePrint(...) end

end
