if SERVER then
	AddCSLuaFile()
	util.AddNetworkString("LambdaPlayerToken")
end

if SERVER then

	local TOKEN_TABLE = { "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "!", "%", "~", "*", "+", "/" }
	local TOKEN_LEN = 24

	local function GenerateToken()
		local tokens = {}
		local seed = math.Round(os.time() + system.UpTime() + SysTime() + CurTime() + math.random())
		math.randomseed(seed)
		local tokenTableLen = #TOKEN_TABLE
		for i = 1, TOKEN_LEN do
			local choice = math.random(1, tokenTableLen)
			table.insert(tokens, TOKEN_TABLE[choice])
		end
		return table.concat(tokens)
	end

	function GM:AssignPlayerAuthToken(ply)

		ply.LambdaAuthToken = GenerateToken()

		net.Start("LambdaPlayerToken")
		net.WriteString(ply.LambdaAuthToken)
		net.Send(ply)

	end

else

	net.Receive("LambdaPlayerToken", function(len)

		local ply = LocalPlayer()
		local token = net.ReadString()

		ply.LambdaAuthToken = token

		DbgPrint("Received Auth Token: " .. token)

	end)

end
