if CLIENT then
local function MaterialFromVMT(name, VMT)
    if (type(VMT) ~= "string" or type(name) ~= "string") then return Material(" ") end -- Return a dummy Material
    local t = util.KeyValuesToTable("\"material\"{" .. VMT .. "}")

    for shader, params in pairs(t) do
        return CreateMaterial(name, shader, params)
    end
end
EFFECT.Glow = MaterialFromVMT(
	"MuzzleSprite",
	[["UnLitGeneric"
	{
		"$basetexture" "sprites/light_glow01"
		"$nocull" 1
		"$additive" 1
		"$vertexalpha" 1
		"$vertexcolor" 1
	}]]
);
EFFECT.Size = 64
EFFECT.Color = Color(65,250,230)

function EFFECT:Init(data)
	self.Parent = data:GetEntity()
	if(not IsValid(self.Parent)) then return end
	self.Entity:SetParent(self.Parent)
	local radius = tonumber(data:GetRadius()) or 1
	if(radius > 1) then
		self.Size = radius
	end
	self.Entity:SetRenderBounds(Vector(1,1,1)*self.Size*(-2),Vector(1,1,1)*self.Size*2)
	local color = data:GetAngles()
	if(color ~= Angle(0,0,0)) then
		self.Color = self:GetColor()
	end

	local e = self.Parent
	local class = e:GetClass()
	local dynlight = DynamicLight(0)
	dynlight.Pos = data:GetOrigin()
	dynlight.Size = 300
	dynlight.Decay = 300
	dynlight.R = self.Color.r
	dynlight.G = self.Color.g
	dynlight.B = self.Color.b
	dynlight.DieTime = CurTime()+1
	self.Draw = true
end

function EFFECT:Render()
	if(not IsValid(self.Parent)) then return end
	local start = self.Parent:GetPos()
	if(self.Parent.GetShootPos) then
		start =self.Parent:GetShootPos()
	end
	local viewmodel
	if(self.Parent == LocalPlayer()) then
		viewmodel = self.Parent:GetViewModel()
	else
		if(self.Parent.GetActiveWeapon) then
			viewmodel = self.Parent:GetActiveWeapon()
		end
	end
	if(not IsValid(viewmodel)) then return end
	local attach = viewmodel:GetAttachment(1)
	if(not attach) then return end
	start = attach.Pos
	render.SetMaterial(self.Glow)
	render.DrawSprite(
		start,
		self.Size,
		self.Size,
		self.Color
	);
end

function EFFECT:Think()
	self.Size = math.Clamp(self.Size-150*FrameTime(),0,1337)
	return (self.Size > 0 and self.Draw);
end
end