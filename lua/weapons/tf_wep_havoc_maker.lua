AddCSLuaFile()

local SWEP = {Primary = {}, Secondary = {}}

SWEP.Author = "Nova Astral"
SWEP.PrintName = "Havoc Maker"
SWEP.Purpose = "shoot the gun"
SWEP.Instructions = "LMB - Fire Energy Shot"
SWEP.DrawCrosshair = true
SWEP.SlotPos = 10
SWEP.Slot = 3
SWEP.Spawnable = true
SWEP.Weight = 1
SWEP.HoldType = "normal"
SWEP.Primary.Ammo = "HelicopterGun"
SWEP.Primary.Automatic = true
SWEP.Primary.DefaultClip = 100
SWEP.Primary.ClipSize = -1
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Automatic = true
SWEP.DrawAmmo = true
SWEP.WorldModel = "models/megarexfoc/w_mafoc_x32.mdl"
SWEP.ViewModel = "models/megarexfoc/viewmodels/c_mafoc_x32.mdl"

SWEP.Category = "Transformers Weapons"

SWEP.Base = "foc_arm_base"
SWEP.FOCEquip = Sound("cybertronian/tfx18equip.wav")
SWEP.FOCHolster = Sound("cybertronian/tfx18holster.wav")

function SWEP:CanPrimaryAttack() return false end
function SWEP:CanSecondaryAttack() return false end
function SWEP:Holster() return true end
function SWEP:ShouldDropOnDie() return false end

function SWEP:Initialize()
    if(self.SetHoldType) then
        self:SetHoldType("pistol")
    end

    self:DrawShadow(false)

    self.ShotColor = Color(231,209,0,215)
end

function SWEP:Effects()
    self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)

    local fx = EffectData()
    fx:SetScale(0)
    fx:SetOrigin(self.Owner:GetShootPos())
    fx:SetEntity(self.Owner)
    fx:SetAngles(Angle(255, 50, 50))
    fx:SetRadius(32)
    fx:SetMagnitude(2)
    fx:SetColor(231,209,0)
    util.Effect("tf_engmuzzle_effect",fx,true)
    
    return true
end

if(SERVER) then
    function SWEP:DoShooty()
        local ply = self.Owner

        self:Effects()

        local multiply = 200 -- Default inaccuracy multiplier
        local aimvector = ply:GetAimVector()
        local shootpos = ply:GetShootPos()
        local vel = ply:GetVelocity()
        local filter = {self.Owner, self.Weapon}
    
        if(ply:IsPlayer()) then --inaccuracy
            local right = aimvector:Angle():Right()
            local up = aimvector:Angle():Up()
   
            local max = util.QuickTrace(shootpos, right * 100, filter).Fraction * 100 - 10
            local trans = right:DotProduct(vel) * right / 25
    
            if (ply:Crouching()) then
                multiply = 0.3
                shootpos = shootpos + math.Clamp(15, -10, max) * right - 4 * up + trans
            else
                shootpos = shootpos + math.Clamp(23, -10, max) * right - 15 * up + trans
            end
    
            multiply = multiply * math.Clamp(vel:Length() / 500, 0.3, 3)
        else -- It's an NPC, no inaccuracy
            multiply = 0
        end
    
        local trace = util.QuickTrace(ply:GetShootPos(), 16 * 1024 * aimvector, filter)
    
        if (trace.Hit) then
            aimvector = (trace.HitPos - shootpos):GetNormalized()
        end
    
        local e = ents.Create("tf_energy_shot")
        e:SetPos(shootpos)
        e:PrepareBullet(aimvector,multiply,8000,1)
        e:SetOwner(ply)
        e.Owner = ply
        e.Damage = 100
        e:Spawn()
        e:Activate()
        e:SetColor(self.ShotColor)
        ply:EmitSound(Sound("cybertronian/tfx18shoot.wav"), 90, math.random(97, 103))
    end

    function SWEP:PrimaryAttack() --shoot
        if(self:GetNextPrimaryFire() > CurTime() or self:Ammo1() <= 0) then return end

        self:SetNextPrimaryFire(CurTime()+0.05)
        self:SetNextSecondaryFire(CurTime()+1)

        self:DoShooty()

        if (self.Owner:IsPlayer()) then
            self:TakePrimaryAmmo(1)
        end
    end

    function SWEP:SecondaryAttack() --SPEED SHOOT :)
        if(self:GetNextSecondaryFire() > CurTime() or self:Ammo1() <= 0) then return end
        
        if(self.Owner:KeyDown(IN_RELOAD)) then
            self:SetNextPrimaryFire(CurTime()+1)
            self:SetNextSecondaryFire(CurTime()+0.01)

            self:DoShooty()

            if(self.Owner:IsPlayer()) then
                self:TakePrimaryAmmo(1)
            end
        end
    end
end

timer.Simple(0.1, function() weapons.Register(SWEP,"tf_wep_havoc_maker", true) end) --Putting this in a timer stops bugs from happening if the weapon is given while the game is paused