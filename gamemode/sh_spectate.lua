AddCSLuaFile()

local PLAYER_META = FindMetaTable("Player")

if SERVER then

	function GM:GetSpectatorTargets()
	    return team.GetPlayers( LAMBDA_TEAM_ALIVE )
	end

	function PLAYER_META:SetSpectator()

		local ent = table.Random( GAMEMODE:GetSpectatorTargets() )

		self:SetNW2Bool("Spectator", true)
		self:SetNW2Entity("SpectateEntity", ent)

	    self:StripWeapons()
		if self:Alive() then
	    	self:KillSilent()
		end
	    self:Spectate( 5 )
		if IsValid(ent) then
			self:SpectateEntity(ent)
		end

	end

	function PLAYER_META:EndSpectator()

	    self:SetNW2Bool("Spectator", false)
	    self:UnSpectate()

	end

	function PLAYER_META:GetSpectateMode()
	    return self:GetObserverMode()
	end

	function PLAYER_META:GetSpectateTarget()
	    return self:GetObserverTarget()
	end

	function PLAYER_META:ChangeSpectateMode()

	    local target = self:GetObserverTarget()

	    if self:GetSpectateMode() == 5 then
	        self:SetObserverMode( 4 )
	        self:SetupHands( target )
	    elseif self:GetSpectateMode() == 4 then
	        self:SetObserverMode( 5 )
	        self:SetupHands( nil )
	    end
	end

	hook.Add( "KeyPress", "ChangeObserverMode", function( ply, key )

	    if !ply:IsSpectator() then return end

	    if key == IN_JUMP then
	        ply:ChangeSpectateMode()
	    end

	    if key == IN_ATTACK then
	        ply:NextSpectateTarget()
	    end

	    if key == IN_ATTACK2 then
	        ply:PrevSpectateTarget()
	    end

	end)

	function GM:GetNextSpectateTarget( ply, ent )

	    local targets = GAMEMODE:GetSpectatorTargets()
	    return table.FindNext( targets, ent)

	end

	function GM:GetPrevSpectateTarget( ply, ent )

	    local targets = GAMEMODE:GetSpectatorTargets()
	    return table.FindPrev( targets, ent )

	end

	local function IsValidTarget( ply, ent )

	    if !IsValid( ent ) then return false end
	    if ent == ply then return false end
	    if !ent:Alive() then return false end

	    return true

	end

	function PLAYER_META:NextSpectateTarget()

	    local target = self:GetObserverTarget()

	    target = GAMEMODE:GetNextSpectateTarget( self, target )

	    if IsValidTarget( self, target ) then
	        self:SpectateEntity( target )
	        if self:GetSpectateMode() == 4 then
	            self:SetupHands( target )
	        end
	    else
			return
	    end

	end

	function PLAYER_META:PrevSpectateTarget()

	    local target = self:GetObserverTarget()

	    target = GAMEMODE:GetPrevSpectateTarget( self, target )

	    if IsValidTarget( self, target ) then
	        self:SpectateEntity( target )
	        if self:GetSpectateMode() == 4 then
	            self:SetupHands( target )
	        end
	    else
			return
	    end

	end

end -- SERVER

function PLAYER_META:IsSpectator()
    return self:GetNW2Bool("Spectator", false)
end
