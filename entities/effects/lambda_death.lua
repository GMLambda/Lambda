EFFECT.Mat1 = Material( "lambda/death_point.png" )

function EFFECT:Init( data )

	local size = 64
	local ply = data:GetEntity()
	if not IsValid(ply) then
		self:Remove()
	end

	self:SetCollisionBounds( Vector( -size,-size,-size ), Vector( size,size,size ) )
	self:SetAngles( data:GetNormal():Angle() + Angle( 0.01, 0.01, 0.01 ) )

	self.Pos = data:GetOrigin()
	self.Normal = data:GetNormal()
	self.Alpha = 1
	self.Player = ply

	self.Direction = data:GetScale()
	self.Size = data:GetRadius()
	self.Axis = data:GetOrigin()
	self.Dist = 0

	self:SetPos( data:GetOrigin() )
	self.PlayerName = ply:Nick()

end

function EFFECT:Think( )

	local speed = FrameTime()

	if not IsValid(self.Player) then
		return false
	end

	if self.Player:Alive() then
		return false
	end

	self.Alpha = self.Alpha - speed * 0.08
	self.Dist = math.sin(CurTime() * 5) * 5

	if (self.Alpha < 0 ) then return false end

	return true

end

function EFFECT:Render( )

	if  (self.Alpha < 0 ) then return end

	render.SuppressEngineLighting(true)

	local Normal = self.Normal
	local eyePos = EyePos()
	local dir = Normal:Angle()
	local ang = eyePos - self:GetPos()
	local dist = eyePos:Distance(self:GetPos())

	local signsize = math.Clamp(dist / 20, self.Size / 2, self.Size * 5)
	local offset_z = math.Clamp(dist / 20, 50, 200)

	cam.IgnoreZ(true)

	render.SetMaterial( self.Mat1 )
	render.DrawQuadEasy( self:GetPos() + (dir:Forward() * (offset_z + self.Dist)) ,
						 ang,
						 signsize, signsize,
						 Color( 255, 255, 255, (self.Alpha ^ 1.1) * 255 ),
						 180)

	cam.IgnoreZ(false)

	render.SuppressEngineLighting(false)

end
