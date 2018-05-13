local isvoting = false
local currentvote = false
local votepanel = false

local outpadding = 14
local padding = 5
local maxw = 30
local maxh = outpadding

function GM:StartVote()
	isvoting = true

	self:CreateVote()
end

function GM:EndVote()
	isvoting = false
	currentvote = false

	self:DeleteVote()
end

net.Receive("LambdaStartVote",function()
	currentvote = {}
	currentvote.name = net.ReadString()
	currentvote.ply = net.ReadString()
	currentvote.options = net.ReadTable()
	currentvote.myvote = 0

	GAMEMODE:StartVote()
end)

net.Receive("LambdaEndVote",function() GAMEMODE:EndVote() end)


function GM:DeleteVote()
	if votepanel and votepanel:IsValid() then
		votepanel:Remove()
		votepanel = false
	end
end

function GM:CreateVote()
	self:DeleteVote()

	local w, h
	local textinfo = {}
	local lasty = 10

	for k, v in pairs({currentvote.name, "Vote called by " .. currentvote.ply, "Press the corresponding number to vote.", unpack(currentvote.options)}) do
		if k >= 4 then
			v = tostring(k - 3) .. ". " .. v
			w, h = surface.GetTextSize(v)
		else
			w, h = surface.GetTextSize(v)
		end
		textinfo[k] = {}
		textinfo[k].text = v
		textinfo[k].w = w
		textinfo[k].h = h
		textinfo[k].y = lasty

		lasty = lasty + h + padding
		if k == 2 then lasty = lasty + 7 end
		maxw = math.max(maxw, w)
	end
	maxh = lasty + padding + outpadding

	votepanel = vgui.Create("DFrame")
	votepanel:SetSize(maxw, maxh)
	votepanel:SetPos(padding, ScrH() * 0.25)
	votepanel:SetTitle("")
	votepanel:SetDeleteOnClose(false)
	votepanel:ShowCloseButton(false)
	votepanel:SetDraggable(false)
	votepanel:SetVisible(true)

	function votepanel:Paint(w, h)
		surface.SetDrawColor(0, 0, 0, 230)
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(255, 147, 30, 230)
		surface.DrawRect(0, 0, 5, h)

		for k, v in pairs(textinfo) do
			surface.SetFont("lambda_sb_def_sm")
			if k == 2 or k == 3 then
				surface.SetTextColor(255, 255, 255, 75)
			else
				if k == currentvote.myvote + 3 then
					surface.SetTextColor(255, 147, 30, 230)
				else
					surface.SetTextColor(255, 255, 255, 255)
				end
			end

			if k == 2 then
				local str1, str2
				str1 = string.sub(v.text, 1, 15)
				str2 = string.sub(v.text, 15)
				surface.SetTextPos(outpadding, v.y)
				surface.DrawText(str1)
				local w2, h2 = surface.GetTextSize(str1)
				surface.SetTextColor(255,255,255,75)
				surface.SetTextPos(outpadding + w2,v.y)
				surface.DrawText(str2)

				surface.SetDrawColor(255, 255, 255, 155)
				surface.DrawLine(outpadding, v.y + h2 + 5, w - outpadding, v.y + h2 + 5)
			else
				surface.SetTextPos(outpadding, v.y)
				surface.DrawText(v.text)
			end
		end
	end
	maxw, maxh = 50, outpadding
end

hook.Add("PlayerBindPress", "LambdaVote", function(ply,bind,pressed)
	if isvoting and currentvote.myvote == 0 and string.match(bind, "slot%d+") then
		local num = string.gsub(bind, "slot", "")
		num = tonumber(num)
		surface.PlaySound("buttons/blip1.wav")

		if num >= 1 and num <= #currentvote.options then
			currentvote.myvote = num
			net.Start("LambdaVote")
			net.WriteUInt(num, 4)
			net.SendToServer()
			return true
		end
	end
end)

