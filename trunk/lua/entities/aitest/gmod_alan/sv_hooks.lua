function ENT:InitializeHooks()
	
	hook.Add("EntityTakeDamage", "Alan", function(entity, inflictor, attacker, amount, damageinfo )
		if entity == self then
			self:SelectRandomWeapon()
			self:Kill(attacker, function(self) 
				self:SelectWeapon("none")
				self:Follow(table.Random(player.GetAll()))
			end)
			self:Drop()
		end
	end)

	hook.Add("PhysgunPickup", "Alan", function(ply, entity)
		if entity:GetClass() == "gmod_alan" then
			entity:SetPickedup(true)
		end
	end)

	hook.Add("PhysgunDrop", "Alan", function(ply, entity)
		if entity:GetClass() == "gmod_alan" then
			entity:SetPickedup(false)
		end
	end)

	hook.Add("GravGunOnPickedUp", "Alan", function(ply, entity)
		if entity:GetClass() == "gmod_alan" then
			entity:SetPickedup(true)
		end
	end)

	hook.Add("GravGunOnDropped", "Alan", function(ply, entity)
		if entity:GetClass() == "gmod_alan" then
			entity:SetPickedup(false)
		end
	end)

	hook.Add("GravGunPunt", "Alan", function(ply, entity)
		if entity:GetClass() == "gmod_alan" then
			entity:Bonk(2)
		end
	end)

	hook.Add("PlayerSpawnedProp", "test", function(ply, mdl, entity)
		lastent = entity
	end)

	hook.Add("PlayerSay", "Alan", function(ply, text)
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