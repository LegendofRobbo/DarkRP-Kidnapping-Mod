include('shared.lua')

SWEP.PrintName			= "Bludgeon"
SWEP.Slot				= 0
SWEP.SlotPos			= 4
SWEP.DrawAmmo			= false

function SWEP:DrawHUD()
local tr = LocalPlayer():GetEyeTrace()
if !tr.Entity:IsValid() or tr.Entity:GetClass() != "prop_ragdoll" or LocalPlayer():GetPos():Distance( tr.Entity:GetPos() ) > 200 then return end
local ent = tr.Entity
local owner = ent:GetNWEntity( "kidnapmod_ragowner", game.GetWorld() )
if !owner:IsValid() then return end
 
local p = ent:LocalToWorld(ent:OBBCenter()):ToScreen()
draw.DrawText(owner:Nick(),"Trebuchet24",p.x,p.y,Color(255,255,255, 150),1)
draw.DrawText("RMB to move body","Trebuchet18",p.x,p.y + 20,Color(255,255,255, 150),1)
draw.DrawText("E + RMB to confiscate weapons","Trebuchet18",p.x,p.y + 35,Color(255,255,255, 150),1)
end