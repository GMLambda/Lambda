AddCSLuaFile()

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}

MAPSCRIPT.DefaultLoadout =
{
    Weapons =
    {
    },
    Ammo =
    {
    },
    Health = 47,
    Armor = 0,
    HEV = true,
}

MAPSCRIPT.InputFilters =
{
}

MAPSCRIPT.EntityFilterByClass =
{
}

MAPSCRIPT.EntityFilterByName =
{
}

MAPSCRIPT.Scenes = {
	"lcs_ep1_intro_01",
	"lcs_ep1_intro_02",
	"lcs_ep1_intro_03",
	"lcs_ep1_intro_03b",
	"lcs_ep1_intro_04b",
	"lcs_ep1_intro_05",
	"lcs_ep1_intro_07",
	"lcs_ep1_intro_06",
	"lcs_ep1_intro_04",
	"lcs_ep1_intro_08",
	"lcs_al_vanride_end02",
	"lcs_al_vanride_end01"
}

function MAPSCRIPT:Init()

    DbgPrint("MapScript EP1")

end

local VAN_SEATS =
{
    [1] = {
        ["A"] = Angle(1.767, 2.006, -1.416),
        ["P"] = Vector(-34.445328, -34.126759, -7.685587),
    },
    [2] = {
        ["A"] = Angle(1.313, 2.214, -2.800),
        ["P"] = Vector(-56.387981, -34.222366, -7.115709),
    },
    [3] = {
        ["A"] = Angle(3.018, 0.042, -0.567),
        ["P"] = Vector(-78.517288, -32.879601, -6.470951),
    },
    [4] = {
        ["A"] = Angle(3.997, 0.407, -2.491),
        ["P"] = Vector(-100.596458, -31.679190, -5.465893),
    },
    [5] = {
        ["A"] = Angle(-2.268, 90.148, -2.797),
        ["P"] = Vector(7.820162, -26.099751, -12.334793),
    },
    [6] = {
        ["A"] = Angle(-3.504, 90.459, -6.783),
        ["P"] = Vector(9.263323, -3.344811, -11.339058),
    },
    [7] = {
        ["A"] = Angle(-3.057, 91.212, -4.457),
        ["P"] = Vector(8.092402, 19.312775, -9.515255),
    },
    [8] = {
        ["A"] = Angle(-0.879, -179.249, -13.311),
        ["P"] = Vector(-63.267052, 27.428225, -2.239295),
    },
    [9] = {
        ["A"] = Angle(-0.161, 179.544, -14.089),
        ["P"] = Vector(-38.638702, 28.568981, -2.696731),
    },
}

local function CreateVanSeat(van, data, seats)

    local pos = van:LocalToWorld(data.P)
    local ang = van:LocalToWorldAngles(data.A)

    local seat = ents.Create("prop_vehicle_prisoner_pod")
    seat:SetPos(pos)
    seat:SetAngles(ang)
    seat:SetCollisionGroup(COLLISION_GROUP_NONE)
    seat:SetModel("models/nova/airboat_seat.mdl")
    seat:SetParent(van)
    --seat:SetNotSolid(true)
    seat:Spawn()
    --seat:Activate()
    seat:SetName("VanSeat")

    seat:Fire("AddOutput", "PlayerOn !self,Lock,,0.0")
    seat:Fire("AddOutput", "PlayerOn van_seat_ounter,Add,1,0.0,-1")

    return seat

end

function MAPSCRIPT:OnEnteredVehicle(ply, vehicle, role)

    if vehicle == self.Van then
        -- This vehicle has the wrong position for players.
        ply:SetLocalPos(Vector(40, -30, -5))
    end

end

function MAPSCRIPT:PostInit()

    if SERVER then

        self.Van = nil

        -- Freeze player also.
        ents.WaitForEntityByName("viewcontrol_black", function(ent)
            ent:SetKeyValue("spawnflags", "396")
        end)

        ents.WaitForEntityByName("point_viewcontrol_01", function(ent)
            ent:SetKeyValue("spawnflags", "412")
        end)

        ents.WaitForEntityByName("viewcontrol_final", function(ent)
            ent:SetKeyValue("spawnflags", "398")
        end)

        ents.WaitForEntityByName("pvc_intro_start", function(ent)
            ent:SetKeyValue("spawnflags", "412")
        end)

        ents.WaitForEntityByName("pvc_intro", function(ent)
            ent:SetKeyValue("spawnflags", "412")
        end)

        -- Prevent scenes to stop when somebody dies
        for _, scenes in pairs(self.Scenes) do
        	ents.WaitForEntityByName(scenes, function(ent)
        		ent:SetKeyValue("onplayerdeath", "0")
        	end)
        end

        -- Let alyx hug everyone.
        ents.WaitForEntityByName("vehicle_blackout", function(ent)

            for i = 1, game.MaxPlayers() do
                local vehicle = ents.Create("prop_vehicle_choreo_generic")
                vehicle:SetKeyValue("vehiclescript", "scripts/vehicles/choreo_vehicle_ep1_dogintro.txt")
                vehicle:SetKeyValue("VehicleLocked", "1")
                vehicle:SetName("vehicle_blackout_" .. tostring(i))
                vehicle:SetModel(ent:GetModel())
                vehicle:SetPos(ent:GetPos())
                vehicle:SetAngles(ent:GetAngles())
                vehicle:SetParent(ent)
                vehicle:Fire("AddOutput", "PlayerOff ghostanim_DogIntro,Kill,,0.0,-1")
                vehicle:Fire("AddOutput", "PlayerOff !self,Kill,,1.0,-1")
                vehicle:Fire("AddOutput", "PlayerOn !activator,DisableDraw,,0.0,-1")
                vehicle:Fire("AddOutput", "PlayerOff !activator,EnableDraw,,0.0,-1")
                vehicle:Spawn()
            end

        end)

        -- Let everyone exit.
        local exitTP = ents.Create("point_teleport")
        exitTP:SetPos(Vector(-9017.534180, 5761.911133, -142.968750))
        exitTP:SetAngles(Angle(0, 50, 0))
        exitTP:SetKeyValue("target", "!players")
        exitTP:SetName("vehicle_blackoutexit_tp")
        exitTP:Spawn()

        ents.WaitForEntityByName("ss_DogIntro", function(ent)
            ent:Fire("AddOutput", "OnScriptEvent01 vehicle_blackout*,Unlock,,0.0,-1")
            ent:Fire("AddOutput", "OnScriptEvent01 vehicle_blackout*,ExitVehicle,,0.01,-1")
            ent:Fire("AddOutput", "OnScriptEvent01 vehicle_blackoutexit_tp,Teleport,,0.05,-1")
            ent:Fire("AddOutput", "OnScriptEvent01 maker_template_gravgun,SetParent,!player,0.1,-1")
        end)

        local function GetNextVehicle()
            local vehicles = ents.FindByName("vehicle_blackout_*")
            for _,v in pairs(vehicles) do
                local driver = v:GetInternalVariable("m_hPlayer")
                if IsValid(driver) == false then
                    return v
                end
            end
        end


        local checkpoint1 = GAMEMODE:CreateCheckpoint(Vector(-8778.361328, 5711.103516, -146.155045), Angle(0, 0, 0))

        GAMEMODE:WaitForInput("vehicle_blackout", "EnterVehicle", function(ent)
            for k,v in pairs(player.GetAll()) do
                if v:Alive() == false then
                   continue
                end
                local vehicle = GetNextVehicle()
                if IsValid(vehicle) then
                    v:EnterVehicle(vehicle)
                end
            end
            GAMEMODE:SetPlayerCheckpoint(checkpoint1)
            return false -- Suppress this.
        end)

        -- Give gravity gun by default once picked up
        GAMEMODE:WaitForInput("maker_template_gravgun", "ForceSpawn", function(ent)
            local loadout = GAMEMODE:GetMapScript().DefaultLoadout
            table.insert(loadout.Weapons, "weapon_physcannon")
        end)

        -- Make sure no player is left behind.
        for _,v in pairs(ents.FindByPos(Vector(-7920, 5444, 84), "trigger_once")) do
            v:Remove()
        end

        local triggerDogEscape = ents.Create("trigger_multiple")
        triggerDogEscape:SetupTrigger(
            Vector(-8560.031250, 5826.152832, -63.710419),
            Angle(0, 0, 0),
            Vector(-600, -350, -100),
            Vector(800, 400, 500)
        )
        triggerDogEscape:Fire("AddOutput", "OnEndTouchAll ss_dog_gunship_down,BeginSequence,,0.0,-1")
        triggerDogEscape:Fire("AddOutput", "OnEndTouchAll pclip_gunship_2,Enable,,0.0,-1")

        ents.WaitForEntityByName("counter_alyx_van", function(ent)
            -- Increase from 3 to 4 so we can have our trigger have the final say.
            ent:SetKeyValue("max", "4")
        end)

        -- Let the vehicle fall once everyone is out of there.
        ents.WaitForEntityByName("counter_vanride_end01_resume", function(ent)
            -- Increase by one.
            ent:SetKeyValue("max", "3")
        end)

        local fallTrigger = ents.Create("trigger_once")
        fallTrigger:SetupTrigger(
            Vector(4799.591309, 4057.289551, -6326.972656),
            Angle(0, 0, 0),
            Vector(-1350, -1940, -70),
            Vector(670, 440, 220)
        )
        fallTrigger:SetKeyValue("spawnflags", "513")
        fallTrigger:SetKeyValue("teamwait", "1")
        fallTrigger:SetKeyValue("showwait", "0")
        fallTrigger:Fire("AddOutput", "OnTrigger counter_vanride_end01_resume,Add,1,0.0,-1")
        fallTrigger:SetName("lambda_falltrigger")

        -- Unlock van seats after the sequence not only the van.
        ents.WaitForEntityByName("relay_vanride_endcrash_1", function(ent)
            -- Unlock after.
            ent:Fire("AddOutput", "OnTrigger VanSeat,Unlock,,0.01,-1")
        end)

        ents.WaitForEntityByName("Van", function(ent)

            local van = ent

            self.Van = van

            if ent.VanSeats ~= nil then
                return
            end

            local seats = {}
            for _,v in pairs(VAN_SEATS) do
                local seat = CreateVanSeat(van, v, seats)
                table.insert(seats, seat)
            end

            van.VanSeats = seats

        end)

        -- -6431.318848 6006.155273 -33.239578
        local carTrigger = ents.Create("trigger_once")
        carTrigger:SetupTrigger(
            Vector(-6431.318848, 6006.155273, -100.239578),
            Angle(0, 0, 0),
            Vector(-150, -150, 0),
            Vector(150, 150, 200)
        )
        carTrigger:SetKeyValue("spawnflags", tostring(SF_TRIGGER_ALLOW_CLIENTS + SF_TRIGGER_ONLY_CLIENTS_IN_VEHICLES))
        carTrigger:SetKeyValue("teamwait", "1")
        carTrigger.OnTrigger = function(trigger)
            self.PlacePlayerInVan = true
            TriggerOutputs({
                {"counter_alyx_van", "Add", 0.0, "1"},
            })
        end

        local checkpoint2 = GAMEMODE:CreateCheckpoint(Vector(-7916.693359, 5424.519531, -95.968750), Angle(0, 0, 0))
        local checkpointTrigger2 = ents.Create("trigger_once")
        checkpointTrigger2:SetupTrigger(
            Vector(-7916.693359, 5424.519531, -95.968750),
            Angle(0, 0, 0),
            Vector(-150, -50, 0),
            Vector(200, 50, 100)
        )
        checkpointTrigger2.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(checkpoint2, activator)
        end

        -- 4649.159180 3903.150635 -6343.968750
        local checkpoint3 = GAMEMODE:CreateCheckpoint(Vector(4649.159180, 3903.150635, -6343.968750), Angle(0, 45, 0))
        local checkpointTrigger3 = ents.Create("trigger_once")
        checkpointTrigger3:SetupTrigger(
            Vector(4649.159180, 3903.150635, -6343.968750),
            Angle(0, 0, 0),
            Vector(-100, -250, 0),
            Vector(100, 250, 100)
        )
        checkpointTrigger3.OnTrigger = function(_, activator)
            self.PlacePlayerInVan = false
            GAMEMODE:SetPlayerCheckpoint(checkpoint3, activator)
        end

    end

end

function MAPSCRIPT:FindUseEntity(ply, engineEnt)

    local van = self.Van
    if engineEnt == van and IsValid(van) then
        local saveTable = van:GetSaveTable()
        local driver = saveTable.m_hPlayer
        if not IsValid(driver) then
            return nil
        end
        for _,v in pairs(van.VanSeats) do
            if not IsValid(v:GetDriver()) then
                DbgPrint("Giving different seat: " .. tostring(v))
                return v
            end
        end
    end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

    if self.PlacePlayerInVan == true then
        for _,v in pairs(ents.FindByName("VanSeat")) do
            if not IsValid(v:GetDriver()) then
                ply:EnterVehicle(v)
                break
            end
        end
    end

end

return MAPSCRIPT
