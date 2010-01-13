local props = {
	"models/props_borealis/bluebarrel001.mdl",
	"models/props_borealis/borealis_door001a.mdl",
	"models/combine_helicopter/helicopter_bomb01.mdl",
	"models/props_c17/concrete_barrier001a.mdl",
	"models/props_c17/furniturecouch002a.mdl",
	"models/props_c17/furniturefridge001a.mdl",
	"models/props_c17/furniturestove001a.mdl",
	"models/props_c17/furniturewashingmachine001a.mdl",
	"models/props_c17/oildrum001.mdl",
	"models/props_c17/gravestone003a.mdl",
	"models/props_debris/metal_panel02a.mdl",
	"models/props_interiors/vendingmachinesoda01a.mdl",
	"models/props_junk/trashbin01a.mdl",
	"models/props_junk/trashdumpster01a.mdl",
	"models/props_lab/blastdoor001b.mdl"
}

function ENT:CreateWeldTask(tbl, callback, index)
	if index >= table.Count(tbl) then callback(self) return end
	index = index or 0	
	self:ToolWeld(tbl[index+1], tbl[index+2], function(self) 
		index = index + 1
		self:CreateWeldTask(tbl, callback, index)
	end)
end

function ENT:CreateEasyWeldTask(tbl, callback, index)
	if index >= table.Count(tbl) then callback(self) return end
	index = index or 0	
	self:ToolEasyWeld(tbl[index+1], tbl[index+2], function(self) 
		index = index + 1
		self:CreateEasyWeldTask(tbl, callback, index)
	end)
end

function ENT:CreateTool()
	self.tool = ents.Create("prop_physics")
	self.tool:SetModel("models/weapons/w_toolgun.mdl")
	self.tool:SetPos(self:GetPos())
	self.tool:SetAngles(self:GetAngles())
	self.tool:Spawn()
	self.tool:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	self.tool:SetOwner(self)
	self.tool:SetParent(self)
	self.tool:SetNoDraw(true)
end

function ENT:ToolWeld(entity1, entity2, callback)
	if not self.activeweaponl then self:SelectWeapon("tool") end
	self:SetRandomMovement(false)
	timer.Simple(0.1, function()
		self:LookAt(entity1, nil, 1, true, function(self, weldentity1) 
			self:ToolEffect()
			timer.Simple(0.1, function()
				self:LookAt(entity2, nil, 1, true, function(self, weldentity2)
					constraint.Weld( weldentity1, weldentity2, 0, 0, 0, false)
					self:ToolEffect()
					callback(self, weldentity1, weldentity2)
				end)
			end)
		end)
	end)
end

function ENT:ToolEasyWeld(entity1, entity2, callback)
	if not self.activeweaponl then self:SelectWeapon("tool") end
	self:SetRandomMovement(false)
	timer.Simple(0.1, function()
		self:LookAt(entity1, nil, 1, true, function(self, weldentity1) 
			local position = self:GetWeaponTrace().HitPos - weldentity1:GetPos()
			self:ToolEffect()
			timer.Simple(0.1, function()
				self:LookAt(entity2, nil, 1, true, function(self, weldentity2)
					weldentity1:SetPos(weldentity2:GetPos()+position)
					constraint.Weld( weldentity1, weldentity2, 0, 0, 0, false)
					callback(self, weldentity1, weldentity2)
					self:ToolEffect()
				end)
			end)
		end)
	end)
end

function ENT:ToolRemove(entity, callback)
	if not self.activeweaponl then self:SelectWeapon("tool") end
	self:SetRandomMovement(false)
	timer.Simple(0.1, function()
		self:LookAt(entity, nil, 1, true, function(self) 
			timer.Simple(0.1, function()
				self:ToolEffect()
				self:Follow(table.Random(player.GetAll()))
				entity:Remove()
			end)
		end)
	end)	
end

function ENT:ToolEffect()
	self:EmitSound("Airboat.FireGunRevDown")
	local attachment = self.activeweapon:GetAttachment(1)
	local tracer = EffectData()
	tracer:SetStart(attachment.Pos)
	tracer:SetEntity(self.activeweapon)
	tracer:SetAttachment(1)
	tracer:SetOrigin(self:GetWeaponTrace().HitPos)
	util.Effect("tooltracer", tracer)
end

function ENT:Pickup(entity, nocollide, callback)
	self.pickup = true
	hook.Add("Think", "Alan Pickup "..self:EntIndex(), function()
		self:Goto(entity:GetPos(), entity:BoundingRadius()/2)
		if self.entitytouched == entity then
			constraint.Weld(self, self.entitytouched, 0, 0, false)
			entity:SetOwner(self)
			
			if nocollide then
				self.entitytouched:SetCollisionGroup(COLLISION_GROUP_WORLD)
			end
			
			self.weldedto = self.entitytouched
			self.entitytouched = nil
			self.pickup = false
			if callback then timer.Simple(0.2, function() callback(self, entity)  end) end
			hook.Remove("Think", "Alan Pickup "..self:EntIndex())
		end
	end)
end

function ENT:CancelPickup()
	hook.Remove("Think", "Alan Pickup "..self:EntIndex())
	self.position = nil
end

function ENT:Drop()
	constraint.RemoveConstraints(self, "Weld")
end

function ENT:FreezeHeldEntities()
	for key, entity in pairs(constraint.GetAllConstrainedEntities( self )) do
		if entity ~= self then
			entity:GetPhysicsObject():EnableMotion(false)
		end
	end
	self:Drop()
end

function ENT:PickRandomEntity(nocollide, alternate, callback)
	local tbl = {}
	for k, v in pairs(ents.GetAll()) do
		if v:GetPhysicsObject():IsValid() and v != GetWorldEntity() and not v:IsPlayer() and not v:IsNPC() and v ~= self and not constraint.HasConstraints(v) and not table.HasValue(self.weapons, v) and self.tool ~= v and not string.find(v:GetClass(), "constraint") then
			print(v, v:GetPos())
			tbl[k] = v
		end
	end
	self:Pickup(table.Random(alternate or tbl), nocollide, callback)
end

function ENT:StartTouch(entity)
	if self.pickup then
		self.entitytouched = entity
	end
end