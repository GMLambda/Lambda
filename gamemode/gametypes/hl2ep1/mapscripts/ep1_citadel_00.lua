AddCSLuaFile()

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}

MAPSCRIPT.PlayersLocked = false
MAPSCRIPT.DefaultLoadout =
{
    Weapons =
    {
    },
    Ammo =
    {
    },
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


        -- Prevent scenes to stop when somebody dies
        for _, scenes in pairs(self.Scenes) do
        	ents.WaitForEntityByName(scenes, function(ent)
        		ent:SetKeyValue("onplayerdeath", "0")
        	end)
        end

        ents.WaitForEntityByName("counter_alyx_van", function(ent)
            -- Increase from 3 to 4 so we can have our trigger have the final say.
            ent:SetKeyValue("max", "4")
        end)

        -- Unlock van seats after the sequence not only the van.
        ents.WaitForEntityByName("SS_Van_ThrowGate", function(ent)
            ent:Fire("AddOutput", "OnEndSequence VanSeat,Unlock,,0.0,-1")
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
            DbgPrint("All players on board")
            TriggerOutputs({
                {"counter_alyx_van", "Add", 0.0, "1"},
            })
        end

        -- -6709.447266 5710.125000 -102.160347 cp1
        local checkpoint1 = GAMEMODE:CreateCheckpoint(Vector(-6709.447266, 5710.125000, -102.160347), Angle(0, 45, 0))
        local checkpointTrigger1 = ents.Create("trigger_once")
        checkpointTrigger1:SetupTrigger(
            Vector(-6709.447266, 5710.125000, -102.160347),
            Angle(0, 0, 0),
            Vector(-100, -250, 0),
            Vector(100, 250, 100)
        )
        checkpointTrigger1.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(checkpoint1, activator)
        end

        -- 4649.159180 3903.150635 -6343.968750
        local checkpoint2 = GAMEMODE:CreateCheckpoint(Vector(4649.159180, 3903.150635, -6343.968750), Angle(0, 45, 0))
        local checkpointTrigger2 = ents.Create("trigger_once")
        checkpointTrigger2:SetupTrigger(
            Vector(4649.159180, 3903.150635, -6343.968750),
            Angle(0, 0, 0),
            Vector(-100, -250, 0),
            Vector(100, 250, 100)
        )
        checkpointTrigger2.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(checkpoint2, activator)
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

end

return MAPSCRIPT
