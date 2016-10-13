if SERVER then

	AddCSLuaFile()

	util.AddNetworkString("LambdaHudHint")

	function GM:AddHintText(data)

		local tab
		if isstring(data) then
			tab = { data }
		elseif istable(data) then
			tab = data
		else
			Error("AddHintText: Invalid argument passed, can be string or table of strings")
		end

		local count = table.Count(tab)

		net.Start("LambdaHudHint")
		net.WriteUInt(count, 8)
		for _,v in pairs(tab) do
			net.WriteString(v)
		end
		net.Broadcast()

	end

else -- CLIENT

	-- TODO: Implement rendering those things.

end
