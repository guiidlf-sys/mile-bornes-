local Theme = {}

Theme.Background = Color3.fromRGB(24, 28, 22)
Theme.Panel = Color3.fromRGB(34, 40, 32)
Theme.PanelLight = Color3.fromRGB(46, 54, 44)
Theme.Accent = Color3.fromRGB(210, 160, 30)
Theme.Good = Color3.fromRGB(78, 165, 90)
Theme.Bad = Color3.fromRGB(190, 70, 60)
Theme.Text = Color3.fromRGB(240, 240, 235)
Theme.SubText = Color3.fromRGB(180, 182, 175)
Theme.Font = Enum.Font.GothamMedium
Theme.FontBold = Enum.Font.GothamBold

function Theme.RoundCorner(instance: Instance, radius: number?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 10)
	corner.Parent = instance
	return corner
end

function Theme.Stroke(instance: Instance, color: Color3?, thickness: number?)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Color3.fromRGB(0, 0, 0)
	stroke.Thickness = thickness or 1.5
	stroke.Parent = instance
	return stroke
end

function Theme.Pad(instance: Instance, all: number)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, all)
	pad.PaddingBottom = UDim.new(0, all)
	pad.PaddingLeft = UDim.new(0, all)
	pad.PaddingRight = UDim.new(0, all)
	pad.Parent = instance
	return pad
end

return Theme
