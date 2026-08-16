--!strict
-- Card catalog and deck construction for Mille Bornes.
-- Card kinds: "Distance" | "Hazard" | "Remedy" | "Safety"

export type CardKind = "Distance" | "Hazard" | "Remedy" | "Safety"

export type HazardType = "Accident" | "OutOfGas" | "FlatTire" | "SpeedLimit" | "Stop"
export type RemedyType = "Repairs" | "Gasoline" | "SpareTire" | "EndOfLimit" | "Go"
export type SafetyType = "DrivingAce" | "ExtraTank" | "PunctureProof" | "RightOfWay"

export type Card = {
	id: string,
	key: string,
	kind: CardKind,
	value: number?,
	hazardType: HazardType?,
	remedyType: RemedyType?,
	safetyType: SafetyType?,
	name: string,
	color: Color3,
}

local CardData = {}

-- Remedy -> Hazard it fixes
local RemedyFixes: { [RemedyType]: HazardType } = {
	Repairs = "Accident",
	Gasoline = "OutOfGas",
	SpareTire = "FlatTire",
	EndOfLimit = "SpeedLimit",
	Go = "Stop",
}
CardData.RemedyFixes = RemedyFixes

-- Safety -> Hazard it grants immunity to
local SafetyProtects: { [SafetyType]: HazardType } = {
	DrivingAce = "Accident",
	ExtraTank = "OutOfGas",
	PunctureProof = "FlatTire",
	RightOfWay = "Stop", -- RightOfWay also protects against SpeedLimit, handled specially
}
CardData.SafetyProtects = SafetyProtects

local DISTANCE_COLOR = Color3.fromRGB(58, 125, 68)
local HAZARD_COLOR = Color3.fromRGB(170, 45, 45)
local REMEDY_COLOR = Color3.fromRGB(45, 95, 170)
local SAFETY_COLOR = Color3.fromRGB(210, 160, 30)

type CatalogEntry = {
	kind: CardKind,
	count: number,
	value: number?,
	hazardType: HazardType?,
	remedyType: RemedyType?,
	safetyType: SafetyType?,
	name: string,
	color: Color3,
}

-- Catalog mirrors the classic 106-card Mille Bornes deck.
local Catalog: { [string]: CatalogEntry } = {
	Distance25 = { kind = "Distance", count = 10, value = 25, name = "25 km", color = DISTANCE_COLOR },
	Distance50 = { kind = "Distance", count = 10, value = 50, name = "50 km", color = DISTANCE_COLOR },
	Distance75 = { kind = "Distance", count = 10, value = 75, name = "75 km", color = DISTANCE_COLOR },
	Distance100 = { kind = "Distance", count = 12, value = 100, name = "100 km", color = DISTANCE_COLOR },
	Distance200 = { kind = "Distance", count = 4, value = 200, name = "200 km", color = DISTANCE_COLOR },

	HazardAccident = { kind = "Hazard", count = 3, hazardType = "Accident", name = "Accident", color = HAZARD_COLOR },
	HazardOutOfGas = { kind = "Hazard", count = 3, hazardType = "OutOfGas", name = "Panne d'essence", color = HAZARD_COLOR },
	HazardFlatTire = { kind = "Hazard", count = 3, hazardType = "FlatTire", name = "Crevaison", color = HAZARD_COLOR },
	HazardSpeedLimit = { kind = "Hazard", count = 4, hazardType = "SpeedLimit", name = "Limite de vitesse", color = HAZARD_COLOR },
	HazardStop = { kind = "Hazard", count = 5, hazardType = "Stop", name = "Stop", color = HAZARD_COLOR },

	RemedyRepairs = { kind = "Remedy", count = 6, remedyType = "Repairs", name = "Réparations", color = REMEDY_COLOR },
	RemedyGasoline = { kind = "Remedy", count = 6, remedyType = "Gasoline", name = "Essence", color = REMEDY_COLOR },
	RemedySpareTire = { kind = "Remedy", count = 6, remedyType = "SpareTire", name = "Roue de secours", color = REMEDY_COLOR },
	RemedyEndOfLimit = { kind = "Remedy", count = 6, remedyType = "EndOfLimit", name = "Fin de limite", color = REMEDY_COLOR },
	RemedyGo = { kind = "Remedy", count = 14, remedyType = "Go", name = "Bornes / Roulez", color = REMEDY_COLOR },

	SafetyDrivingAce = { kind = "Safety", count = 1, safetyType = "DrivingAce", name = "As du volant", color = SAFETY_COLOR },
	SafetyExtraTank = { kind = "Safety", count = 1, safetyType = "ExtraTank", name = "Increvable... réservoir", color = SAFETY_COLOR },
	SafetyPunctureProof = { kind = "Safety", count = 1, safetyType = "PunctureProof", name = "Increvable", color = SAFETY_COLOR },
	SafetyRightOfWay = { kind = "Safety", count = 1, safetyType = "RightOfWay", name = "Priorité", color = SAFETY_COLOR },
}
CardData.Catalog = Catalog

function CardData.BuildDeck(): { Card }
	local deck: { Card } = {}
	for key, entry in pairs(Catalog) do
		for i = 1, entry.count do
			local card: Card = {
				id = string.format("%s_%d", key, i),
				key = key,
				kind = entry.kind,
				value = entry.value,
				hazardType = entry.hazardType,
				remedyType = entry.remedyType,
				safetyType = entry.safetyType,
				name = entry.name,
				color = entry.color,
			}
			table.insert(deck, card)
		end
	end
	return deck
end

return CardData
