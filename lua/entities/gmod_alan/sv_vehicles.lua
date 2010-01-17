function ENT:EnterVehicle(vehicle)
	if ValidEntity(self.vehicle) then constraint.RemoveConstraints(self.vehicle, "Weld") end
	local posang = vehicle:GetAttachment(vehicle:LookupAttachment("vehicle_feet_passenger0"))
	if posang then
		self.vehicle = vehicle
		self:SetPos(posang.Pos)
		self:SetAngles(posang.Ang)
		constraint.Weld(vehicle, self)
	end
end