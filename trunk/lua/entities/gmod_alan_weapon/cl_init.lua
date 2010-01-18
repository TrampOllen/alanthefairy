include("shared.lua")

function ENT:Initialize()
	self.position = 0
	self.velocity = 0
	self.target_position = 0
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:Think()
	if self.dt.visible then
		self.target_position = 100
	else
		self.target_position = 0
	end
	
	self.velocity = ( self.velocity + ( self.target_position - self.position ) * 4/100 ) * 95/100
	self.position = self.position + self.velocity
	
	self:SetModelScale(Vector()*math.max(self.position/100, 0))
	
	print(self.position, self.velocity, self.target_position, self.dt.visible)
	
	self:NextThink(CurTime())
return true end