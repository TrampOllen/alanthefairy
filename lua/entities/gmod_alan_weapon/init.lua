AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

function ENT:Initialize()
	self:SetPos( self.owner:GetPos() + self.position_offset )
	self:SetAngles( self.owner:GetAngles() + self.angle_offset )
	self:SetModel( self.model )
	self:PhysicsInit( SOLID_NONE )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self.dt.visible = false
	self:SetNoDraw(true)
	self:SetOwner(self.owner)
	self.curtime = CurTime()
	self:SetParent(self.owner)
end

function ENT:FireWeapon()
	if self.curtime + self.delay <= CurTime() then
		
		self.curtime = CurTime()
		self:EmitSound(self.sound)
		
		if self.custom then
			self.custom(self, self:GetAttachment(1))
		return end
		
		local bullet = {}
		local attachment = self:GetAttachment(1)
		bullet.Num = 1
		bullet.Src = attachment and attachment.Pos or self:GetPos()
		bullet.Dir = attachment and attachment.Ang:Forward() or self:GetAngles():Forward()
		bullet.Force = 1
		bullet.Attacker = self.owner
		bullet.Damage = self.damage
		self:FireBullets(bullet)
	end
end

function ENT:OnRemove()
	local weapon = ents.Create(self.name)
	if weapon then
		weapon:SetPos(self:GetPos())
		weapon:SetAngles(self:GetAngles())
		weapon:Spawn()
	end
end