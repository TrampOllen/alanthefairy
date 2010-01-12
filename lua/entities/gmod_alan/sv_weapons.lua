function ENT:InitializeWeapons()
	self.weapons = self.weapons or {}
	self:CreateGun("weapon_357", "models/weapons/W_357.mdl", 50, 0.5, 100, "weapons/357/357_fire3.wav")
	self:CreateGun("weapon_pistol", "models/weapons/W_pistol.mdl", 10, 0.1, 100, "weapons/pistol/pistol_fire2.wav", self:GetForward()*5, Angle(0,180,0))
	self:CreateGun("weapon_tmp", "models/weapons/w_smg_tmp.mdl", 10, 0.05, 100, "weapons/tmp/tmp-1.wav")
	self:CreateGun("weapon_rpg", "models/weapons/w_rocket_launcher.mdl", 0, 1, 400, "weapons/rpg/rocketfire1.wav", self:GetForward()*5, Angle(0,180,0), function(self, attachment)
		local rocket = ents.Create("rpg_missile")
		rocket:SetPos(attachment.Pos+self:GetUp()*30)
		rocket:SetAngles(attachment.Ang)
		rocket:Spawn()
		rocket:SetOwner(self)
		rocket:CallOnRemove("Explode", function() 
			util.BlastDamage( self, self, rocket:GetPos(), 100, 100 )
		end)
	end)
end

function ENT:CreateGun(name, model, damage, delay, distance, sound, offset, angles, custom)
	offset = offset or Vector(0)
	angles = angles or Angle(0)
	self.weapons[name] = ents.Create("prop_physics")
	self.weapons[name]:SetModel(model)
	self.weapons[name]:SetPos(self:GetPos()+offset)
	self.weapons[name]:SetAngles(self:GetAngles()+angles)
	self.weapons[name]:SetOwner(self)
	self.weapons[name]:SetParent(self)
	self.weapons[name]:SetNoDraw(true)
	self.weapons[name]:Spawn()
	self.weapons[name]:SetSolid(false)
	self.weapons[name].data = {}
	self.weapons[name].data.sound = sound
	self.weapons[name].data.damage = damage
	self.weapons[name].data.delay = delay
	self.weapons[name].data.name = name
	self.weapons[name].data.distance = distance
	self.weapons[name].curtime = CurTime()
	self.weapons[name].custom = custom
end

function ENT:SelectWeapon(mode)
	for key, weapon in pairs(self.weapons) do
		weapon:SetNoDraw(true)
	end
	if mode == "none" then self.activeweapon = nil return end
	if mode == "tool" then self.activeweapon = self.tool self.tool:SetNoDraw(false) return end
	if not self.weapons[mode] then error("Unknown weapon type!") end
	self.weapons[mode]:SetNoDraw(false)
	self:EmitSound("physics/meta/weapon_impac_soft"..math.random(3), 100, math.random(90,110))
	self.activeweapon = self.weapons[mode]
end

function ENT:FireWeapon()
	if not self.activeweapon then return end
	if self.activeweapon.curtime + self.activeweapon.data.delay <= CurTime() then
		self.activeweapon.curtime = CurTime()
		self.activeweapon:EmitSound(self.activeweapon.data.sound)
		if self.activeweapon.custom then
			self.activeweapon.custom(self, self.activeweapon:GetAttachment(1))
			return
		end
		local bullet = {}
		local attachment = self.activeweapon:GetAttachment(1)
		bullet.Num = 1
		bullet.Src = attachment.Pos
		bullet.Dir = attachment.Ang:Forward()
		bullet.Force = 1
		bullet.Attacker = self 
		bullet.Damage = self.activeweapon.data.damage
		self.activeweapon:FireBullets(bullet)
	end
end

function ENT:CreateWeaponOnRemove()
	if not self.activeweapon then return end
	
	if self.activeweapon == self.tool then 
		local weapon = ents.Create("gmod_tool")
		if weapon then
			weapon:SetPos(self.activeweapon:GetPos())
			weapon:SetAngles(self.activeweapon:GetAngles())
			weapon:Spawn()
		end	
	return end
	
	local weapon = ents.Create(self.activeweapon.data.name or "")
	if weapon then
		weapon:SetPos(self.activeweapon:GetPos())
		weapon:SetAngles(self.activeweapon:GetAngles())
		weapon:Spawn()
	end
end

function ENT:SelectRandomWeapon()
	local rk = math.random( 1, table.Count( self.weapons ) )
	local i = 1
	for k, v in pairs(self.weapons) do
		if ( i == rk ) then self:SelectWeapon(k) return end
		i = i + 1
	end
end

function ENT:Cheater(ply)
	local sentences = {
		"You lousy cheater!",
		"Cheater!",
		"Godmode whore!",
		"Disable Godmode!",
	}
	
	self:SayToPlayer(ply, table.Random(sentences))
end