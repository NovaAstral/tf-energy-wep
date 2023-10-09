local SWEP = {Primary = {}, Secondary = {}}

SWEP.Author = "Nova Astral"
SWEP.PrintName = "Energy Gun"
SWEP.Purpose = "shoot the gun"
SWEP.Instructions = "LMB - Fire Energy Ball \nRMB - Fire Big Energy Ball"
SWEP.DrawCrosshair = true
SWEP.SlotPos = 10
SWEP.Slot = 3
SWEP.Spawnable = true
SWEP.Weight = 1
SWEP.HoldType = "normal"
SWEP.Primary.Ammo = "HelicopterGun" --This stops it from giving pistol ammo when you get the swep
SWEP.Primary.Automatic = true
SWEP.Primary.DefaultClip = 100
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Automatic = true
SWEP.DrawAmmo = false
SWEP.WorldModel = "models/weapons/w_toolgun.mdl"
SWEP.ViewModel = "models/weapons/v_toolgun.mdl"

SWEP.Category = "Transformers Tools"

function SWEP:CanPrimaryAttack() return false end
function SWEP:CanSecondaryAttack() return false end
function SWEP:Holster() return true end
function SWEP:ShouldDropOnDie() return false end

function SWEP:Initialize()
    if SERVER then util.AddNetworkString("EWepSecNet") end

    if(self.SetHoldType) then
        self:SetHoldType("pistol")
    end

    self:DrawShadow(false)

    self.ReloadDelay = CurTime()+1
    self.SecAtk = false
end

function SWEP:Effects() -- Muzzle Effect
    --self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    -- Muzzle
    local fx = EffectData()
    fx:SetScale(0)
    fx:SetOrigin(self.Owner:GetShootPos())
    fx:SetEntity(self.Owner)
    fx:SetAngles(Angle(255, 50, 50))
    fx:SetRadius(64)
    fx:SetMagnitude(2)
    util.Effect("tf_engmuzzle_effect",fx,true)
    
    return true
end

if(SERVER) then
    function SWEP:PrimaryAttack() --shoot ball
        if(self:GetNextPrimaryFire() > CurTime() or self:Ammo1() <= 0) then return end

        self:SetNextPrimaryFire(CurTime()+1)
        self:SetNextSecondaryFire(CurTime()+1)

        local ply = self.Owner

        self:TakePrimaryAmmo(1)

        self:Effects()

        local p = self.Owner
        local multiply = 3 -- Default inaccuracy multiplier
        local aimvector = p:GetAimVector()
        local shootpos = p:GetShootPos()
        local vel = p:GetVelocity()
        local filter = {self.Owner, self.Weapon}
    
        -- Add inaccuracy for players!
        if (p:IsPlayer()) then
            local right = aimvector:Angle():Right()
            local up = aimvector:Angle():Up()
            -- Check, how far we can go to right (avoids exploding shots on the wall right next to you)
            local max = util.QuickTrace(shootpos, right * 100, filter).Fraction * 100 - 10
            local trans = right:DotProduct(vel) * right / 25
    
            if (p:Crouching()) then
                multiply = 0.3 -- We are in crouch - Make it really accurate!
                -- We need to adjust shootpos or it will look strange
                shootpos = shootpos + math.Clamp(15, -10, max) * right - 4 * up + trans
            else
                -- He stands
                shootpos = shootpos + math.Clamp(23, -10, max) * right - 15 * up + trans
            end
    
            multiply = multiply * math.Clamp(vel:Length() / 500, 0.3, 3) -- We are moving - Make it inaccurate depending on the velocity
        else -- It's an NPC
            multiply = 0
        end
    
        -- Now, we need to correct the velocity depending on the changed shootpos above.
        local trace = util.QuickTrace(p:GetShootPos(), 16 * 1024 * aimvector, filter)
    
        if (trace.Hit) then
            aimvector = (trace.HitPos - shootpos):GetNormalized()
        end
    
        local e = ents.Create("tf_energy_ball")
        e:SetPos(shootpos)
        e:PrepareBullet(aimvector,multiply,8000,1)
        e:SetOwner(p)
        e.Owner = p
        e.Damage = 100
        e:Spawn()
        e:Activate()
        e:SetColor(Color(119, 176, 255, 215))
        p:EmitSound(Sound("tfweapons/tf_energy_fire.wav"), 90, math.random(97, 103))
        -- Take one Ammo
        if (self.Owner:IsPlayer()) then
            self:TakePrimaryAmmo(1)
        end
    end

    function SWEP:SecondaryAttack() --shoot laser
        if(self:GetNextSecondaryFire() > CurTime() or self:Ammo1() <= 5) then return end

        self:SetNextPrimaryFire(CurTime()+10)
        self:SetNextSecondaryFire(CurTime()+10)
    end
end

if CLIENT then
    surface.CreateFont("AmmoFont",{
        font = "Arial",
        size = 50,
        weight = 500
    })

    function SWEP:DrawHUD() -- Display uses
        if(self:Ammo1() == 0) then
            TxtColor = Color(255,0,0,220)
        else
            TxtColor = Color(255,220,0,220)
        end

        draw.WordBox(8,ScrW() - 200,ScrH() - 140,self:Ammo1(),"AmmoFont",Color(0,0,0,80),TxtColor)
    end
end

timer.Simple(0.1, function() weapons.Register(SWEP,"tf_energy_wep", true) end) --Putting this in a timer stops bugs from happening if the weapon is given while the game is paused