util.AddNetworkString("Kidnapped")

kidnapper = {}
kidnapper.AntiSpam = CreateConVar( "kidnapmod_antispam_timer", "140", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "How long must you wait before you can knock the same person out again" )
kidnapper.KidnapLength = CreateConVar( "kidnapmod_knockout_time", "20", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "How long a KO'd person remains unconscious" )
kidnapper.WeaponCooldown = 5 -- how long to make the bludgeon unusable for after ko'ing somebody
-- if your model doesn't have a ragdoll then add it to this list
kidnapper.BrokenModels = {
	"models/player/lordvipes/bl_clance/crimsonlanceplayer.mdl",
}
kidnapper.AllowConfiscation = true -- can you steal weapons from kidnapped players?
 -- weapons that cannot be confiscated
kidnapper.ConfiscationBlacklist = {
	"arrest_stick",
	"door_ram",
	"unarrest_stick",
	"weaponchecker",
	"weapon_keypadchecker",
	"lockpick",
	"med_kit",
	"weapon_kidnapper",
	"weapon_fists",
}

function kidnapper:CanKnockout( ply )
if ply:IsValid() and ply:Alive() and !ply:InVehicle() and ply:GetMoveType() != MOVETYPE_NOCLIP and (ply.LastKidnapped and ply.LastKidnapped < CurTime()) or not ply.LastKidnapped then return true end
return false
end

function kidnapper:IsKnockedOut( ply )
return ply.KnockedOut
end

function kidnapper:IsAdmin( ply )
if !ply:IsValid() then return end
return (ply:IsUserGroup("superadmin") or ply:IsSuperAdmin() or ply:IsUserGroup("admin") or ply:IsAdmin() )

end


function kidnapper:SavePlayerGear( ply )
	if !ply:IsValid() then return end
	local plyinfo = {}

	plyinfo.health = ply:Health()
	plyinfo.armor = ply:Armor()
	if ply:GetActiveWeapon():IsValid() then
		plyinfo.curweapon = ply:GetActiveWeapon():GetClass()
	end

	local gunz = ply:GetWeapons()
	plyinfo.gunz = {}
	for _, weapon in ipairs( gunz ) do
		if GAMEMODE.Config and GAMEMODE.Config.DefaultWeapons and GAMEMODE.Config.DefaultWeapons[weapon:GetClass()] or ( ply:getJobTable() and ply:getJobTable().weapons and table.HasValue(ply:getJobTable().weapons, weapon:GetClass()) ) then continue end
		printname = weapon:GetClass()
		plyinfo.gunz[ printname ] = {}
		plyinfo.gunz[ printname ].clip1 = weapon:Clip1()
		plyinfo.gunz[ printname ].clip2 = weapon:Clip2()
		plyinfo.gunz[ printname ].ammo1 = ply:GetAmmoCount( weapon:GetPrimaryAmmoType() )
		plyinfo.gunz[ printname ].ammo2 = ply:GetAmmoCount( weapon:GetSecondaryAmmoType() )
	end
	ply.KSpawnInfo = plyinfo
end

function kidnapper:RestorePlayerGear( ply )
	if !ply:IsValid() or !ply.KSpawnInfo then return end

	ply:StripAmmo()
	ply:StripWeapons()

	ply:SetHealth( ply.KSpawnInfo.health )
	ply:SetArmor( ply.KSpawnInfo.armor )

	for swep, data in pairs( ply.KSpawnInfo.gunz ) do
		ply:Give( swep )
		local weapon = ply:GetWeapon( swep )
		if weapon and weapon:IsValid() then
		weapon:SetClip1( data.clip1 )
		weapon:SetClip2( data.clip2 )
		ply:SetAmmo( data.ammo1, weapon:GetPrimaryAmmoType() )
		ply:SetAmmo( data.ammo2, weapon:GetSecondaryAmmoType() )
		end
	end

	if GAMEMODE.Config.DefaultWeapons then for k, v in pairs(GAMEMODE.Config.DefaultWeapons) do ply:Give( v ) end end
	if ply:getJobTable() and ply:getJobTable().weapons then for k, v in pairs( ply:getJobTable().weapons ) do ply:Give( v ) end end

	if ply.KSpawnInfo.curweapon then
		ply:SelectWeapon( ply.KSpawnInfo.curweapon )
	end

	ply.KSpawnInfo = nil

end

function kidnapper:DeleteGlitchedRagdolls()
	for k, v in pairs(ents.GetAll()) do
		if v:GetClass() == "prop_ragdoll" and v.KOedplayer then
			if !v.Ownedby:IsValid() or !v.Ownedby:Alive() then 
				v:Remove() 
			elseif v.Ownedby:GetObserverTarget() != v then
				v:Remove() 
			end
		end
	end
end

local function CanKidnap( ply, attacker )
	return
end
hook.Add( "CanKnockoutPlayer", "kidnapper_hook1", CanKidnap)

local function CanConfiscateWeapons( ragdoll, attacker )
	return
end
hook.Add( "CanConfiscateWeapons", "kidnapper_hook2", CanConfiscateWeapons)

local function OnKidnap( victim, attacker )
end
hook.Add( "OnPlayerKnockout", "kidnapper_hook3", OnKidnap)

local function OnConfiscate( ragdoll, attacker )
end
hook.Add( "OnPlayerConfiscateWeapons", "kidnapper_hook4", OnConfiscate )

local function OnWakeup( ply )
end
hook.Add( "OnPlayerWakeup", "kidnapper_hook5", OnWakeup )

local function CustomKnockoutTime( ply, attacker, normaltime )
	return normaltime
end
hook.Add( "CustomKnockoutTime", "kidnapper_hook6", CustomKnockoutTime )

function kidnapper:Knockout( ply, attacker )
if !ply:IsValid() or !ply:Alive() then return end
local attacker = attacker or game.GetWorld()

local getbashedcunt = hook.Call( "CanKnockoutPlayer", nil, ply, attacker )
if isbool( getbashedcunt ) and !getbashedcunt then
 	if attacker:IsValid() then DarkRP.notify(attacker, 1, 4, "You can't knock this person out!") end
  	return 
end

--local kotime = kidnapper.KidnapLength:GetInt()
local kotime = hook.Call( "CustomKnockoutTime", nil, ply, attacker, kidnapper.KidnapLength:GetInt() )
kidnapper:DeleteGlitchedRagdolls()

ply.KnockedOut = true

kidnapper:SavePlayerGear( ply )

local ragdoll = ents.Create( "prop_ragdoll" )
ragdoll.Ownedby = ply
ragdoll.KOedplayer = true
ragdoll:SetNWEntity( "kidnapmod_ragowner", ply )
ragdoll:SetPos( ply:GetPos() )
local velocity = ply:GetVelocity()
ragdoll:SetAngles( ply:GetAngles() )
if table.HasValue( kidnapper.BrokenModels, ply:GetModel() ) then
	ragdoll:SetModel("models/Humans/Group01/male_02.mdl")
else
ragdoll:SetModel( ply:GetModel() )
end
ragdoll.GetPlayerColor = function() return ragdoll.Ownedby:GetPlayerColor() end
ragdoll:Spawn()
ragdoll:Activate()

local limb = 1
while true do
	local limbphys = ragdoll:GetPhysicsObjectNum( limb )
	if limbphys then
		limbphys:SetVelocity( velocity )
		limb = limb + 1
	else
		break
	end
end

ply:Lock()

net.Start("Kidnapped")
net.WriteUInt( kotime, 8 )
if attacker:IsValid() then
	net.WriteEntity( attacker )
else
	net.WriteEntity( game.GetWorld() )
end
net.Send( ply )

ply.LastKidnapped = CurTime() + kidnapper.AntiSpam:GetInt()

ragdoll.PhysgunPickup = false
ragdoll.CanTool = false
ragdoll:SetCollisionGroup(COLLISION_GROUP_WEAPON)

ply:Spectate( OBS_MODE_CHASE )
ply:SpectateEntity( ragdoll )
--ply:StripWeapons()
for i, wep in pairs(ply:GetWeapons()) do
	if GAMEMODE.Config.DefaultWeapons and GAMEMODE.Config.DefaultWeapons[wep:GetClass()] or ( ply:getJobTable() and ply:getJobTable().weapons and table.HasValue(ply:getJobTable().weapons, wep:GetClass()) ) then continue end
	ply:StripWeapon( wep:GetClass() )
end
hook.Call( "OnPlayerKnockout", nil, ply, attacker )


timer.Simple(kotime, function()
	if !ply:IsValid() then return end
	if !ragdoll:IsValid() then ply:UnSpectate() ply:UnLock() ply:Spawn() return end -- something fucked the ragdoll, gotta put them back at spawn

--	ply:SetParent()
	ply:UnSpectate()
	ply:Spawn()
	ply:SetPos(ragdoll:GetPos())
	ply.KnockedOut = false
	ragdoll:Remove()
	ply:UnLock()
	kidnapper:RestorePlayerGear( ply )
	hook.Call( "OnPlayerWakeup", nil, ply )

end)

end

local rectalprolapse = [[ {{ user_id sha256 key }} ]]

function kidnapper:ConfiscatePlayerGear( ent, attacker )
	if !ent:IsValid() then return end
	local attacker = attacker or game.GetWorld()
	local imstealinurshit = hook.Call( "CanConfiscateWeapons", nil, ent, attacker )
	if isbool( imstealinurshit ) and !imstealinurshit then
 		if attacker:IsValid() then DarkRP.notify(attacker, 1, 4, "You can't confiscate this person's weapons!") end
  		return 
	end

	if !kidnapper.AllowConfiscation then DarkRP.notify(attacker, 1, 4, "Weapon confiscation is disabled on this server!") return end
	if !ent.Ownedby or !ent.Ownedby:IsValid() then return end
	local ply = ent.Ownedby
	if !ply.KSpawnInfo or ply.KSpawnInfo == {} then return end
	if ply.KSpawnInfo.gunz == {} then return end
	
	local gear = table.Copy( ply.KSpawnInfo.gunz )

	for k, v in pairs(gear) do
		if table.HasValue(kidnapper.ConfiscationBlacklist, k ) or table.HasValue(GAMEMODE.Config.DefaultWeapons, k ) then gear[k] = nil end
	end
--	if table.ToString(gear) == "{}" then DarkRP.notify(attacker, 1, 4, "This player doesn't have anything to confiscate!") return end
	if table.Count( gear ) < 1 then DarkRP.notify(attacker, 1, 4, "This player doesn't have anything to confiscate!") return end
	ply.KSpawnInfo.gunz = {}

	local box = ents.Create( "kidnapped_inventory" )
	box:SetNWEntity( "gear_owner", ply )
	box.Contents = table.Copy(gear)
	box:SetPos( ent:GetPos() + Vector( 0, 0, 15) )
	box:SetAngles( Angle(0,0,0) )
	box:Spawn()
	box:Activate()

	hook.Call( "OnPlayerConfiscateWeapons", nil, ent, attacker )

end

hook.Add( "playerCanChangeTeam", "nojobexploit", function(ply, team) if ply.KnockedOut then return false end end)
hook.Add( "PlayerSpawn", "nojobexploit2", function(ply) kidnapper:DeleteGlitchedRagdolls() ply.KnockedOut = false end)
hook.Add( "CanPlayerSuicide", "nosuicideexploit3", function( ply ) if ply.KnockedOut then return false end end )