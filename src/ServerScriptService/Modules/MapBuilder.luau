-- MapBuilder.luau
-- Procedurally builds the 3D world: grass baseplate, a central plaza with the
-- card "table", a Mille Bornes arch/sign, a spawn point, and decorative
-- roadside "bornes kilométriques" (the milestone markers the game is named
-- after). Pure decoration/atmosphere — actual gameplay happens through the UI.

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local MapBuilder = {}

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = props.CanCollide ~= false
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.Color = props.Color or Color3.fromRGB(255, 255, 255)
	p.Size = props.Size
	p.CFrame = props.CFrame or CFrame.new(props.Position or Vector3.zero)
	p.Shape = props.Shape or Enum.PartType.Block
	p.Name = props.Name or "Part"
	p.Parent = props.Parent
	return p
end

-- A classic French "borne kilométrique": white pillar with a red-domed top.
local function buildBorne(parent: Instance, position: Vector3, label: string?)
	local model = Instance.new("Model")
	model.Name = "Borne"
	model.Parent = parent

	local base = part({
		Name = "Base",
		Parent = model,
		Size = Vector3.new(1.4, 2.2, 1.4),
		Position = position + Vector3.new(0, 1.1, 0),
		Material = Enum.Material.Concrete,
		Color = Color3.fromRGB(240, 240, 235),
	})

	part({
		Name = "Cap",
		Parent = model,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.7, 1.5, 1.5),
		CFrame = CFrame.new(position + Vector3.new(0, 2.55, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(190, 40, 35),
	})

	if label then
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.LightInfluence = 0
		gui.Parent = base
		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.Text = label
		text.TextColor3 = Color3.fromRGB(20, 20, 20)
		text.Font = Enum.Font.GothamBold
		text.TextScaled = true
		text.Parent = gui
	end

	model.PrimaryPart = base
	return model
end

-- A simple stylised tree: brown trunk + a round green canopy.
local function buildTree(parent: Instance, position: Vector3)
	local model = Instance.new("Model")
	model.Name = "Tree"
	model.Parent = parent

	local trunk = part({
		Name = "Trunk",
		Parent = model,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(6, 1.3, 1.3),
		CFrame = CFrame.new(position + Vector3.new(0, 3, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Material = Enum.Material.Wood,
		Color = Color3.fromRGB(84, 58, 36),
	})

	part({
		Name = "Canopy",
		Parent = model,
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(7.5, 7.5, 7.5),
		Position = position + Vector3.new(0, 8.5, 0),
		Material = Enum.Material.Grass,
		Color = Color3.fromRGB(56, 110, 48),
		CanCollide = false,
	})

	model.PrimaryPart = trunk
	return model
end

local function setupLighting()
	Lighting.ClockTime = 14
	Lighting.Brightness = 3
	Lighting.Ambient = Color3.fromRGB(95, 95, 100)
	Lighting.OutdoorAmbient = Color3.fromRGB(145, 145, 155)
	Lighting.GlobalShadows = true
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "MilleBornesBloom"
	bloom.Intensity = 0.4
	bloom.Size = 24
	bloom.Threshold = 1.6
	bloom.Parent = Lighting

	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Name = "MilleBornesColor"
	colorCorrection.Saturation = 0.15
	colorCorrection.Contrast = 0.05
	colorCorrection.TintColor = Color3.fromRGB(255, 248, 235)
	colorCorrection.Parent = Lighting
end

function MapBuilder.Build()
	if Workspace:FindFirstChild("MilleBornesMap") then
		return
	end

	setupLighting()

	local mapFolder = Instance.new("Folder")
	mapFolder.Name = "MilleBornesMap"
	mapFolder.Parent = Workspace

	-- Grass baseplate
	part({
		Name = "Baseplate",
		Parent = mapFolder,
		Size = Vector3.new(320, 4, 320),
		Position = Vector3.new(0, -2, 0),
		Material = Enum.Material.Grass,
		Color = Color3.fromRGB(74, 128, 62),
	})

	-- Central plaza (concrete)
	part({
		Name = "Plaza",
		Parent = mapFolder,
		Size = Vector3.new(90, 1, 90),
		Position = Vector3.new(0, 0.5, 0),
		Material = Enum.Material.Concrete,
		Color = Color3.fromRGB(150, 150, 145),
	})

	-- Road leading into the plaza, with dashed centre line
	part({
		Name = "Road",
		Parent = mapFolder,
		Size = Vector3.new(16, 0.6, 140),
		Position = Vector3.new(0, 0.3, -160),
		Material = Enum.Material.Asphalt,
		Color = Color3.fromRGB(45, 45, 48),
	})
	for i = 0, 12 do
		part({
			Name = "RoadLine",
			Parent = mapFolder,
			CanCollide = false,
			Size = Vector3.new(0.6, 0.65, 4),
			Position = Vector3.new(0, 0.62, -100 - i * 8),
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(230, 220, 90),
		})
	end

	-- Card table in the middle of the plaza
	part({
		Name = "TableBase",
		Parent = mapFolder,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2, 22, 22),
		CFrame = CFrame.new(Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Material = Enum.Material.Wood,
		Color = Color3.fromRGB(96, 61, 32),
	})
	part({
		Name = "TableTop",
		Parent = mapFolder,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, 24, 24),
		CFrame = CFrame.new(Vector3.new(0, 2.3, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Material = Enum.Material.Fabric,
		Color = Color3.fromRGB(45, 95, 60),
	})

	-- Four player pedestals around the table
	local pedestalColors = {
		Color3.fromRGB(200, 60, 60),
		Color3.fromRGB(60, 110, 200),
		Color3.fromRGB(210, 180, 40),
		Color3.fromRGB(90, 170, 90),
	}
	for i = 1, 4 do
		local angle = math.rad((i - 1) * 90)
		local radius = 16
		local pos = Vector3.new(math.sin(angle) * radius, 1.2, math.cos(angle) * radius)
		part({
			Name = "PlayerPedestal" .. i,
			Parent = mapFolder,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.4, 3, 3),
			CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)),
			Material = Enum.Material.Neon,
			Color = pedestalColors[i],
			CanCollide = false,
		})
	end

	-- Entrance arch with the game's name
	part({
		Name = "ArchLeft",
		Parent = mapFolder,
		Size = Vector3.new(3, 24, 3),
		Position = Vector3.new(-14, 12, -60),
		Material = Enum.Material.Concrete,
		Color = Color3.fromRGB(230, 230, 225),
	})
	part({
		Name = "ArchRight",
		Parent = mapFolder,
		Size = Vector3.new(3, 24, 3),
		Position = Vector3.new(14, 12, -60),
		Material = Enum.Material.Concrete,
		Color = Color3.fromRGB(230, 230, 225),
	})
	local archBeam = part({
		Name = "ArchBeam",
		Parent = mapFolder,
		Size = Vector3.new(34, 4, 3),
		Position = Vector3.new(0, 25, -60),
		Material = Enum.Material.Concrete,
		Color = Color3.fromRGB(230, 230, 225),
	})

	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.LightInfluence = 0
	signGui.PixelsPerStud = 40
	signGui.Parent = archBeam
	local signLabel = Instance.new("TextLabel")
	signLabel.Size = UDim2.fromScale(1, 1)
	signLabel.BackgroundTransparency = 1
	signLabel.Text = "MILLE BORNES"
	signLabel.TextColor3 = Color3.fromRGB(210, 160, 30)
	signLabel.Font = Enum.Font.GothamBlack
	signLabel.TextScaled = true
	signLabel.Parent = signGui

	local signGuiBack = signGui:Clone()
	signGuiBack.Face = Enum.NormalId.Back
	signGuiBack.Parent = archBeam

	-- Decorative "bornes" milestone markers lining the road and plaza edge
	for i = 0, 8 do
		buildBorne(mapFolder, Vector3.new(-11, 0, -100 + i * 15))
		buildBorne(mapFolder, Vector3.new(11, 0, -100 + i * 15))
	end
	buildBorne(mapFolder, Vector3.new(-40, 0, 20), "1000")
	buildBorne(mapFolder, Vector3.new(40, 0, 20), "1000")

	-- Trees scattered around the plaza, leaving the road corridor clear
	local treeAngles = { 0, 30, 60, 90, 120, 230, 260, 290, 320, 350 }
	for _, angleDeg in ipairs(treeAngles) do
		local angle = math.rad(angleDeg)
		local radius = 105 + (angleDeg % 47)
		buildTree(mapFolder, Vector3.new(math.sin(angle) * radius, 0, math.cos(angle) * radius))
	end

	-- Spawn point at the edge of the plaza, facing the table
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = CFrame.new(Vector3.new(0, 1, 30), Vector3.new(0, 1, 0))
	spawn.Material = Enum.Material.Concrete
	spawn.Color = Color3.fromRGB(150, 150, 145)
	spawn.Duration = 0
	spawn.Name = "SpawnLocation"
	spawn.Parent = mapFolder

	Workspace.FallenPartsDestroyHeight = -250
end

return MapBuilder
