function ENT:InitializeWeapons()
	self:CreateGun{
		name = "weapon_357",
		model = "models/weapons/W_357.mdl",
		damage = 50,
		delay = 0.5,
		saftey_distance = 0,
		sound = "weapons/357/357_fire3.wav",
	}
	
	self:CreateGun{
		name = "weapon_pistol",
		model = "models/weapons/W_pistol.mdl",
		damage = 10,
		delay = 0.1,
		saftey_distance = 0,
		sound = "weapons/pistol/pistol_fire2.wav",
		offset = self:GetForward()*5,
		angle = Angle(0,180,0),
	}
	
	self:CreateGun{
		name = "weapon_tmp", 
		model = "models/weapons/w_smg_tmp.mdl",
		damage = 10,
		delay = 0.05,
		saftey_distance = 0,
		sound = "weapons/tmp/tmp-1.wav",	
	}
	
	self:CreateGun{
		name = "weapon_rpg",
		model = "models/weapons/w_rocket_launcher.mdl",
		damage = 0,
		delay = 1,
		saftey_distance = 500,
		sound = "weapons/rpg/rocketfire1.wav",
		offset = self:GetForward()*5,
		angle = Angle(0,180,0),
		custom = function(self, attachment)
			local rocket = ents.Create("rpg_missile")
			rocket:SetPos(attachment.Pos+self:GetUp()*30)
			rocket:SetAngles(attachment.Ang)
			rocket:Spawn()
			rocket:SetOwner(self)
			rocket:CallOnRemove("Explode", function() 
				util.BlastDamage( self, self, rocket:GetPos(), 100, 100 )
			end)
		end,
	}
end

function ENT:CreateGun(data)
	self.weapons = self.weapons or {}
	self.weapons[data.name] = ents.Create("gmod_alan_weapon")
	self.weapons[data.name].name = data.name or "weapon_pistol"
	self.weapons[data.name].sound = data.sound or Sound("weapons/pistol/pistol_fire2.wav")
	self.weapons[data.name].model = data.model or "models/weapons/W_pistol.mdl"
	self.weapons[data.name].damage = data.damage or 10
	self.weapons[data.name].position_offset = data.offset or Vector(0)
	self.weapons[data.name].angle_offset = data.angle or Angle(0)
	self.weapons[data.name].owner = self
	self.weapons[data.name].delay = data.delay or 0.1
	self.weapons[data.name].distance = data.distance or 10000
	self.weapons[data.name].min_distance = data.safety_distance or 0
	self.weapons[data.name].curtime = CurTime()
	self.weapons[data.name].custom = data.custom
	self.weapons[data.name]:Spawn()
end

function ENT:SelectWeapon(mode)
	self:EmitSound("physics/metal/weapon_impact_soft"..math.random(3)..".wav", 100, math.random(90,110))
	for key, weapon in pairs(self.weapons) do
		weapon:SetNoDraw(true)
		weapon.dt.visible = false
	end
	if mode == "tool" then
		self.activeweapon = self.tool
		self.tool:SetNoDraw(false)
		return
	else
		self.tool:SetNoDraw(true)
	end
	if mode == "none" then self.activeweapon = nil return end
	if not self.weapons[mode] then error("Unknown weapon type!") end
	self.weapons[mode]:SetNoDraw(false)
	self.weapons[mode].dt.visible = true
	self.activeweapon = self.weapons[mode]
end

function ENT:FireWeapon()
	self.activeweapon:FireWeapon()
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
		"Disable godmode!",
	}
	
	self:SayToPlayer(ply, table.Random(sentences))
end