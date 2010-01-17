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
			entity:Bonk(2, true)
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
			self:ShouldLaugh(text, true)
			self:Respond(ply, text)
			if ply:GetPos():Distance(self:GetPos()) > 500 then return end
			self:Follow(ply)
			return
		end
		
		if ply:GetAimVector():DotProduct( ( self:GetPos() - ply:GetPos() ):Normalize() ) > 0.8 then
			self:Respond(ply, text)
			self:ShouldLaugh(text, true)
		end
	end)
			
	hook.Add("AlanChat", "Actions based on chat", function(entity, response, id)
		if string.find(response, "How do you like my new look?") then
			local color = HSVToColor(math.random(360), 0.3, 1)
			entity:SetColor(color.r,color.g,color.b,255)
			entity.dt.size = math.Rand(0.2, 1)
		end
		if CS then
			CS.PlayerSay(alan, response)
		end
	end)
	
	hook.Add("PlayerInitialSpawn", "Alan"..self:EntIndex(), function(spawned_player)
		hook.Add("KeyPress", "Alan"..self:EntIndex()..spawned_player:EntIndex(), function(ply, key)
			if ValidEntity(self) and ValidEntity(spawned_player) and ply == spawned_player then
				self:Greet(spawned_player)
				hook.Remove("KeyPress", "Alan"..self:EntIndex()..spawned_player:EntIndex())
			end
		end)
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

function CreateAlan(position)
	local entity = ents.Create("gmod_alan")
	entity:SetPos(position or Vector(0))
	entity:Spawn()
	entity:Activate()
	entity:PhysWake()
end