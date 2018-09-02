local Color_Icon = Color( 230, 230, 230, 130 )
local NPC_Color = Color(250, 50, 50, 255)
local times_color = Color(255, 255, 255, 255)

surface.CreateFont("KillFont", {font = "Tahoma", size = 16, weight = 800, antialias = true, additive = false})
surface.CreateFont("Killico", {font = "HL2MP", size = 46, weight = 100, antialias = true, additive = false})

local font = "KillFont"

--killicon.AddFont( "prop_physics",		"Killico",	"9",	Color_Icon )
--killicon.AddFont( "func_physbox",		"Killico",	"9",	Color_Icon )

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

killicon.Add("prop_physics","killicons/func_physbox_killicon",	Color_Icon )
killicon.Add("func_physbox","killicons/func_physbox_killicon",	Color_Icon )
killicon.Add("func_physbox_multiplayer","killicons/func_physbox_killicon",	Color_Icon )
killicon.Add("env_fire", "killicons/env_fire_killicon", Color_Icon)
killicon.Add("entityflame", "killicons/env_fire_killicon", Color_Icon)
killicon.Add("env_explosion", "killicons/env_explosion_killicon", Color_Icon)
killicon.Add("env_physexplosion", "killicons/env_explosion_killicon", Color_Icon)
killicon.Add("point_hurt", "killicons/point_hurt_killicon", Color_Icon)
killicon.Add("trigger_hurt", "killicons/point_hurt_killicon", Color_Icon)
killicon.Add("radiation","killicons/radiation_killicon", Color_Icon)
killicon.Add("func_door", "killicons/func_door_killicon", Color_Icon)
killicon.Add("func_door_rotating", "killicons/func_door_killicon", Color_Icon)
killicon.Add("prop_door_rotating", "killicons/func_door_killicon", Color_Icon)
killicon.Add("npc_barnacle", "killicons/npc_barnacle_killicon", Color_Icon)
killicon.Add("npc_manhack", "killicons/npc_manhack_killicon", Color_Icon)
killicon.Add("fall", "killicons/worldspawn_killicon", Color_Icon)
killicon.Add("combine_mine", "killicons/combine_mine_killicon", Color_Icon)

local Deaths = {}

local function RecieveDeathEvent()

	local data = net.ReadTable()
	GAMEMODE:AddDeathNotice(data)

end
net.Receive("LambdaDeathEvent",RecieveDeathEvent)

--[[---------------------------------------------------------
   Name: gamemode:AddDeathNotice( Attacker, team1, Inflictor, Victim, team2 )
   Desc: Adds an death notice entry
-----------------------------------------------------------]]
function GM:AddDeathNotice(data)

	local death = {}
	death.time = CurTime()
	death.times = 1

	PrintTable(data)
	local dmgType = data.dmgType

	local inflictor = data.inflictor
	if inflictor ~= nil then 
		death.icon = inflictor.class 
		if bit.band(dmgType, DMG_BLAST) ~= 0 and 
			(inflictor.class ~= "grenade_ar2" and 
			inflictor.class ~= "combine_mine") then 
			death.icon = "env_explosion"
		end
	end

	local attacker = data.attacker
	if attacker ~= nil then 
		if attacker.isPlayer then 
			death.left = Entity(attacker.entIndex):Name()
		else
			death.left = "#" .. attacker.class 
		end 
		if attacker.class == "trigger_hurt" then
			death.left = nil
		elseif attacker.class == "combine_mine" then 
			death.icon = "combine_mine"
		end
	end

	local victim = data.victim 
	if victim ~= nil then 
		if victim.isPlayer then 
			death.right = Entity(victim.entIndex):Name()
		else
			death.right = "#" .. victim.class 
		end 
	end

	if death.left == death.right then
		death.left = nil
	end

	if death.left == nil then  
		if bit.band(dmgType, DMG_ALWAYSGIB) ~= 0 then 
			print("GIB ME")
		end 

		if bit.band(dmgType, DMG_BLAST) ~= 0 then 
			death.left = "EXPLOSION"
		elseif bit.band(dmgType, DMG_CRUSH) ~= 0 then 
			death.left = "CRUSHED"
		elseif bit.band(dmgType, DMG_POISON) ~= 0 then 
			death.left = "POISON"
		elseif bit.band(dmgType, DMG_RADIATION) ~= 0 then 
			death.left = "RADIATION"
			death.icon = "radiation"
		elseif bit.band(dmgType, DMG_DROWN) ~= 0 then 
			death.left = "DROWNED"
		elseif bit.band(dmgType, DMG_FALL) ~= 0 then 
			death.left = "FELL"
			death.icon = "fall"
		elseif bit.band(dmgType, DMG_SHOCK) ~= 0 then 
			death.left = "SHOCK"
		elseif bit.band(dmgType, DMG_ENERGYBEAM) ~= 0 then 
			death.left = "BEAM"
		end
	end
	

	for k, v in pairs(Deaths) do
		if Deaths[k].left == death.left and Deaths[k].icon == death.icon and Deaths[k].right == death.right then
			death.times = Deaths[k].times + 1
			table.remove(Deaths, k)
		end
	end

	if attacker == nil or attacker.team == nil then
		death.color1 = table.Copy(NPC_Color)
	else 
		death.color1 = table.Copy(team.GetColor(attacker.team)) 
	end

	if victim == nil or victim.team == nil then
		death.color2 = table.Copy(NPC_Color)
	else 
		death.color2 = table.Copy(team.GetColor(victim.team)) 
	end
	
	table.insert(Deaths, death)
end

local function DrawDeath(x, y, death, deathnotice_time)
	
	local fadeout = (death.time + deathnotice_time) - CurTime()
	
	local alpha = math.Clamp(fadeout * 255, 0, 255)
	death.color1.a = alpha
	death.color2.a = alpha
	times_color.a = alpha
	
	if death.icon == nil then 
		death.icon = "default"
	end 

	local w, h = killicon.GetSize(death.icon)
	if !w and !h then return end

	killicon.Draw(x, y, death.icon, alpha)

	-- Draw KILLER
	if ( death.left ) then
		draw.SimpleText(death.left, font, x - (w / 2) - 16, y, death.color1, TEXT_ALIGN_RIGHT)
	end
	
	-- Draw VICTIM
	local _x, _y = draw.SimpleText(death.right,	font, x + (w / 2) + 16, y, death.color2, TEXT_ALIGN_LEFT)
	
	if death.times > 1 then
		local txt = "x" .. death.times
		draw.SimpleText(txt, font, x + (w / 2) + _x + 25, y, times_color, TEXT_ALIGN_LEFT)
	end

	return y + h * 0.70

end


function GM:DrawDeathNotice( x, y )

	if GetConVarNumber("cl_drawhud") == 0 then return end

	local deathnotice_time = lambda_deathnotice_time:GetFloat()
	local curTime = CurTime()
	
	x = x * ScrW() + 100
	y = y * ScrH()
	
	-- Draw
	for k, Death in pairs(Deaths) do

		if Death.time + deathnotice_time > curTime then
	
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
		if Death.time + deathnotice_time > curTime then
			return
		end
	end
	
	Deaths = {}

end