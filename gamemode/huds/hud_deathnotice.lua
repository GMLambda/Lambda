local Color_Icon = Color( 230, 230, 230, 130 )
local NPC_Color = Color( 250, 50, 50, 255 )

surface.CreateFont("KillFont", {font = "Tahoma", size = 16, weight = 800, antialias = true, additive = false})
surface.CreateFont("Killico", {font = "HL2MP", size = 46, weight = 100, antialias = true, additive = false})

local font = "KillFont"

killicon.AddFont( "prop_physics",		"Killico",	"9",	Color_Icon )
killicon.AddFont( "weapon_smg1",		"Killico",	"/",	Color_Icon )
killicon.AddFont( "weapon_357",			"Killico",	".",	Color_Icon )
killicon.AddFont( "weapon_ar2",			"Killico",	"2",	Color_Icon )
killicon.AddFont( "crossbow_bolt",		"Killico",	"1",	Color_Icon )
killicon.AddFont( "weapon_shotgun",		"Killico",	"0",	Color_Icon )
killicon.AddFont( "rpg_missile",		"Killico",	"3",	Color_Icon )
killicon.AddFont( "npc_grenade_frag",	"Killico",	"4",	Color_Icon )
killicon.AddFont( "weapon_pistol",		"Killico",	"-",	Color_Icon )
killicon.AddFont( "prop_combine_ball",	"Killico",	"8",	Color_Icon )
killicon.AddFont( "grenade_ar2",		"Killico",	"7",	Color_Icon )
killicon.AddFont( "weapon_stunstick",	"Killico",	"!",	Color_Icon )
killicon.AddFont( "npc_satchel",		"Killico",	"*",	Color_Icon )
killicon.AddFont( "npc_tripmine",		"Killico",	"*",	Color_Icon )
killicon.AddFont( "weapon_crowbar",		"Killico",	"6",	Color_Icon )
killicon.AddFont( "weapon_physcannon",	"Killico",	",",	Color_Icon )
killicon.Add( "default", "HUD/killicons/default", Color_Icon )
killicon.AddAlias("suicide", "default")

local Deaths = {}

local function RecvPlayerKilledByPlayer()

	local victim	= net.ReadEntity()
	local inflictor	= net.ReadString()
	local attacker	= net.ReadEntity()

	if !IsValid( attacker ) then return end
	if !IsValid( victim ) then return end
	
	GAMEMODE:AddDeathNotice(attacker:Name(), attacker:Team(), inflictor, victim:Name(), victim:Team())

end
net.Receive("PlayerKilledByPlayer", RecvPlayerKilledByPlayer)

local function RecvPlayerKilledSelf()

	local victim = net.ReadEntity()
	if !IsValid( victim ) then return end
	GAMEMODE:AddDeathNotice(nil, 0, "suicide", victim:Name(), victim:Team())

end
net.Receive("PlayerKilledSelf", RecvPlayerKilledSelf)

local function RecvPlayerKilled()

	local victim	= net.ReadEntity()
	if !IsValid( victim ) then return end
	local inflictor	= net.ReadString()
	local attacker	= "#" .. net.ReadString()
	
	GAMEMODE:AddDeathNotice(attacker, -1, inflictor, victim:Name(), victim:Team())

end
net.Receive( "PlayerKilled", RecvPlayerKilled )

local function RecvPlayerKilledNPC()

	local victimtype = net.ReadString()
	local victim	= "#" .. victimtype
	local inflictor	= net.ReadString()
	local attacker	= net.ReadEntity()

	if !IsValid(attacker) then return end
	
	GAMEMODE:AddDeathNotice(attacker:Name(), attacker:Team(), inflictor, victim, -1)
	
end
net.Receive("PlayerKilledNPC", RecvPlayerKilledNPC)

local function RecvNPCKilledNPC()

	local victim	= "#" .. net.ReadString()
	local inflictor	= net.ReadString()
	local attacker	= "#" .. net.ReadString()

	GAMEMODE:AddDeathNotice(attacker, -1, inflictor, victim, -1)

end
net.Receive("NPCKilledNPC", RecvNPCKilledNPC)

--[[---------------------------------------------------------
   Name: gamemode:AddDeathNotice( Attacker, team1, Inflictor, Victim, team2 )
   Desc: Adds an death notice entry
-----------------------------------------------------------]]
function GM:AddDeathNotice(Attacker, team1, Inflictor, Victim, team2)

	local Death = {}
	Death.time		= CurTime()

	Death.left		= Attacker
	Death.right		= Victim
	Death.icon		= Inflictor
	Death.times 	= 1

	for k, v in pairs(Deaths) do
		if Deaths[k].left == Death.left and Deaths[k].icon == Death.icon then
			Death.times = Deaths[k].times + 1
			table.remove(Deaths, k)
		end
	end

	if (team1 == -1) then Death.color1 = table.Copy(NPC_Color)
	else Death.color1 = table.Copy(team.GetColor(team1)) end
	
	if (team2 == -1) then Death.color2 = table.Copy(NPC_Color)
	else Death.color2 = table.Copy(team.GetColor(team2)) end
	
	if (Death.left == Death.right) then
		Death.left = nil
		Death.icon = "suicide"
	end
	
	table.insert(Deaths, Death)
end

local function DrawDeath(x, y, death, deathnotice_time)

	local w, h = killicon.GetSize(death.icon)
	if !w and !h then return end
	
	local fadeout = (death.time + deathnotice_time) - CurTime()
	
	local alpha = math.Clamp(fadeout * 255, 0, 255)
	death.color1.a = alpha
	death.color2.a = alpha
	
	-- Draw Icon
	killicon.Draw(x, y, death.icon, alpha)
	
	-- Draw KILLER
	if ( death.left ) then
		draw.SimpleText(death.left, font, x - (w / 2) - 16, y, death.color1, TEXT_ALIGN_RIGHT)
	end
	
	-- Draw VICTIM
	local _x, _y = draw.SimpleText(death.right,	font, x + (w / 2) + 16, y, death.color2, TEXT_ALIGN_LEFT)
	
	if death.times > 1 then
		local txt = "x" .. death.times
		draw.SimpleText(txt, font, x + (w / 2) + _x + 25, y, Color(255,255,255,255), TEXT_ALIGN_LEFT)
	end

	return y + h * 0.70

end


function GM:DrawDeathNotice( x, y )

	if GetConVarNumber( "cl_drawhud" ) == 0 then return end

	local deathnotice_time = lambda_deathnotice_time:GetFloat()

	x = x * ScrW() + 100
	y = y * ScrH()
	
	-- Draw
	for k, Death in pairs(Deaths) do

		if Death.time + deathnotice_time > CurTime() then
	
			if Death.lerp then
				x = x * 0.3 + Death.lerp.x * 0.7
				y = y * 0.3 + Death.lerp.y * 0.7
			end
			
			Death.lerp = Death.lerp or {}
			Death.lerp.x = x
			Death.lerp.y = y
		
			y = DrawDeath(x, y, Death, deathnotice_time)
		
		end
		
	end
	
	-- We want to maintain the order of the table so instead of removing
	-- expired entries one by one we will just clear the entire table
	-- once everything is expired.
	for k, Death in pairs(Deaths) do
		if Death.time + deathnotice_time > CurTime() then
			return
		end
	end
	
	Deaths = {}

end