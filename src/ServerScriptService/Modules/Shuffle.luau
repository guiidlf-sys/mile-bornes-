--!strict
-- Fisher-Yates shuffle, mutates and returns the given array.

local Shuffle = {}

function Shuffle.ShuffleInPlace<T>(list: { T }): { T }
	local rng = Random.new()
	for i = #list, 2, -1 do
		local j = rng:NextInteger(1, i)
		list[i], list[j] = list[j], list[i]
	end
	return list
end

return Shuffle
