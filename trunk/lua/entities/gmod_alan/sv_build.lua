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