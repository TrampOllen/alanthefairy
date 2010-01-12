function ENT:InitializeHooks(ai)
	
	hook.Add("EntityTakeDamage", "Alan"..self:EntIndex(), function(entity, inflictor, attacker, amount, damageinfo)
		if entity == self.Entity then
			ai:OnEvent("TakeDamage", {entity = entity, inflictor = inflictor, attacker = attacker, amount = amount, damageinfo = damageinfo})
		end
		ai:OnEvent("EntityTakeDamage", {entity = entity, inflictor = inflictor, attacker = attacker, amount = amount, damageinfo = damageinfo})
	end)
	
	hook.Add("PhysgunPickup", "Alan"..self:EntIndex(), function(ply, entity)
		if entity == self.Entity then
			entity:SetPickedup(true)
		end
	end)

	hook.Add("PhysgunDrop", "Alan"..self:EntIndex(), function(ply, entity)
		if entity == self.Entity then
			entity:SetPickedup(false)
		end
	end)

	hook.Add("GravGunOnPickedUp", "Alan"..self:EntIndex(), function(ply, entity)
		if entity == self.Entity then
			entity:SetPickedup(true)
		end
	end)

	hook.Add("GravGunOnDropped", "Alan"..self:EntIndex(), function(ply, entity)
		if entity == self.Entity then
			entity:SetPickedup(false)
		end
	end)

	hook.Add("GravGunPunt", "Alan"..self:EntIndex(), function(ply, entity)
		if entity == self.Entity then
			entity:Bonk(2)
		end
	end)

	hook.Add("PlayerSpawnedProp", "Alan"..self:EntIndex(), function(ply, mdl, entity)
		lastent = entity
	end)

	hook.Add("PlayerSay", "Alan"..self:EntIndex(), function(ply, text)
		if not self:IsValid() then return end
		local name = string.lower(GetConVar("alan_name"):GetString())
		if string.find(text, "!lua") then return end

		
		if string.find(string.lower(text), "come here "..name) or string.find(string.lower(text), "follow me "..name) then
			self:Respond(ply, text)
			self:Follow(ply)
			return
		end
		
		if string.find(string.lower(text), name) then
			self:Respond(ply, text)
			if ply:GetPos():Distance(self:GetPos()) > 500 then return end
			self:Follow(ply)
			return
		end
		
		if ply:GetAimVector():DotProduct( ( self:GetPos() - ply:GetPos() ):Normalize() ) > 0.8 then
			self:Respond(ply, text)
		end
	end)
	
end

local meta = FindMetaTable( "Player" )

local GodEnable = meta.GodEnable
local GodDisable = meta.GodDisable

function meta:GodEnable()
	self.alan_god = true
	GodEnable( self )
end

function meta:GodDisable()
	self.alan_god = false
	GodDisable( self )
end