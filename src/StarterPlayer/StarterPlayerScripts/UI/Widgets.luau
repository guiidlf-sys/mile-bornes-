local Theme = require(script.Parent:WaitForChild("Theme"))

local Widgets = {}

local KIND_LABEL = {
	Distance = "BORNES",
	Hazard = "DANGER",
	Remedy = "SECOURS",
	Safety = "SÉCURITÉ",
}

function Widgets.MakeButton(text: string, size: UDim2)
	local button = Instance.new("TextButton")
	button.Size = size
	button.BackgroundColor3 = Theme.PanelLight
	button.Text = text
	button.TextColor3 = Theme.Text
	button.Font = Theme.FontBold
	button.TextSize = 16
	button.AutoButtonColor = true
	Theme.RoundCorner(button, 8)
	return button
end

-- Builds a visual card widget. `card` is the shared Card table.
function Widgets.MakeCard(card, size: UDim2?)
	local frame = Instance.new("TextButton")
	frame.Size = size or UDim2.fromOffset(96, 132)
	frame.BackgroundColor3 = Color3.fromRGB(250, 248, 240)
	frame.AutoButtonColor = false
	frame.Text = ""
	Theme.RoundCorner(frame, 10)
	Theme.Stroke(frame, Color3.fromRGB(20, 20, 20), 1)

	local kindTag = Instance.new("TextLabel")
	kindTag.Size = UDim2.new(1, 0, 0, 18)
	kindTag.Position = UDim2.new(0, 0, 0, 6)
	kindTag.BackgroundTransparency = 1
	kindTag.Text = KIND_LABEL[card.kind] or ""
	kindTag.Font = Theme.FontBold
	kindTag.TextSize = 11
	kindTag.TextColor3 = card.color
	kindTag.Parent = frame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -8, 0, 0)
	title.AutomaticSize = Enum.AutomaticSize.Y
	title.Position = UDim2.new(0, 4, 0.32, 0)
	title.BackgroundTransparency = 1
	title.TextWrapped = true
	title.Font = Theme.FontBold
	title.TextColor3 = Color3.fromRGB(30, 30, 30)
	if card.kind == "Distance" then
		title.Text = tostring(card.value)
		title.TextSize = 30
	else
		title.Text = card.name
		title.TextSize = 14
	end
	title.Parent = frame

	local swatch = Instance.new("Frame")
	swatch.Size = UDim2.new(1, 0, 0, 6)
	swatch.Position = UDim2.new(0, 0, 1, -6)
	swatch.BackgroundColor3 = card.color
	swatch.BorderSizePixel = 0
	Theme.RoundCorner(swatch, 3)
	swatch.Parent = frame

	kindTag.Parent = frame
	return frame
end

function Widgets.MakeCardBack(size: UDim2?)
	local frame = Instance.new("Frame")
	frame.Size = size or UDim2.fromOffset(50, 70)
	frame.BackgroundColor3 = Color3.fromRGB(60, 70, 110)
	Theme.RoundCorner(frame, 8)
	Theme.Stroke(frame, Color3.fromRGB(20, 20, 20), 1)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "MB"
	label.Font = Theme.FontBold
	label.TextColor3 = Color3.fromRGB(220, 220, 235)
	label.TextSize = 16
	label.Parent = frame
	return frame
end

function Widgets.MakeLabel(text: string, size: UDim2, textSize: number?, bold: boolean?)
	local label = Instance.new("TextLabel")
	label.Size = size
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Theme.Text
	label.Font = bold and Theme.FontBold or Theme.Font
	label.TextSize = textSize or 16
	label.TextXAlignment = Enum.TextXAlignment.Left
	return label
end

return Widgets
