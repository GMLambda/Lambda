EFFECT.Mat1 = Material( "lambda/ring1.png" )
EFFECT.Mat2 = Material( "lambda/ring2.png" )
EFFECT.Mat3 = Material( "lambda/ring3.png" )
EFFECT.Mat4 = Material( "lambda/run_point.vmt" )

function EFFECT:Init( data )

	local size = 64
	local ply = data:GetEntity()

	if ply.LastPointer and IsValid(ply.LastPointer) then
		ply.LastPointer:Remove()
	end
	ply.LastPointer = self

	self:SetCollisionBounds( Vector( -size,-size,-size ), Vector( size,size,size ) )
	self:SetAngles( data:GetNormal():Angle() + Angle( 0.01, 0.01, 0.01 ) )

	self.Pos = data:GetOrigin()
	self.Normal = data:GetNormal()
	self.Alpha = 1

	self.Direction = data:GetScale()
	self.Size = data:GetRadius()
	self.Axis = data:GetOrigin()
	self.Dist = 0

	self:SetPos( data:GetOrigin() )
	self:SetRenderMode(RENDERMODE_GLOW)

end

function EFFECT:Think( )

	local speed = FrameTime()

	self.Alpha = self.Alpha - speed * 0.16
	self.Dist = math.sin(CurTime() * 5) * 5

	if (self.Alpha < 0 ) then return false end

	return true

end

function EFFECT:Render( )

	if  (self.Alpha < 0 ) then return end

	local normal = self.Normal * self.Direction
	normal:Normalize()

	local dir = normal:Angle()
	local ply = LocalPlayer()
	local ang = ply:GetPos() - self:GetPos()
	local dist = ply:GetPos():Distance(self:GetPos())

	render.SetMaterial( self.Mat1 )
	render.DrawQuadEasy( self:GetPos() + normal,
						 normal,
						 self.Size, self.Size,
						 Color( 255, 255, 255, (self.Alpha ^ 1.1) * 255 ),
						 -(self.Alpha * 400) )

	render.SetMaterial( self.Mat2 )
	render.DrawQuadEasy( self:GetPos() + normal,
						 normal,
						 self.Size, self.Size,
						 Color( 255, 255, 255, (self.Alpha ^ 1.1) * 255 ),
						 self.Alpha * 500)

	render.SetMaterial( self.Mat3 )
	render.DrawQuadEasy( self:GetPos() + normal,
						 normal,
						 self.Size, self.Size,
						 Color( 255, 255, 255, (self.Alpha ^ 1.1) * 255 ),
						 -(self.Alpha * 800) )

	local signsize = math.Clamp(dist / 20, self.Size / 2, self.Size * 5)
	local offset_z = math.Clamp(dist / 20, 50, 200)

	render.SetMaterial( self.Mat4 )
	render.DrawQuadEasy( self:GetPos() + (dir:Forward() * (offset_z + self.Dist)) ,
						 ang,
						 signsize, signsize,
						 Color( 255, 255, 255, (self.Alpha ^ 1.1) * 255 ),
						 180)

end
