AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")


function ENT:Initialize()
	self.Entity:SetModel( "models/props_c17/SuitCase_Passenger_Physics.mdl" )
 	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
 	self.Entity:SetColor( Color(255, 255, 255, 255) )
	self.Entity:SetUseType( SIMPLE_USE )
	
	local PhysAwake = self.Entity:GetPhysicsObject()
	if ( PhysAwake:IsValid() ) then
		PhysAwake:Wake()
	end 
	self.Fag = CurTime() + 1
end

function ENT:Use( activator, caller )
	if self.Fag > CurTime() then return end
	local ply = activator
	for swep, data in pairs( self.Contents ) do
		ply:Give( swep )
		local weapon = ply:GetWeapon( swep )
		if weapon and weapon:IsValid() then
		weapon:SetClip1( data.clip1 )
		weapon:SetClip2( data.clip2 )
		ply:GiveAmmo( data.ammo1, weapon:GetPrimaryAmmoType() )
		ply:GiveAmmo( data.ammo2, weapon:GetSecondaryAmmoType() )
		end
	end

	self:Remove()
end