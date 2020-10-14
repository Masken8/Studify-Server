local uv = require("uv")
local TableUtils = require("./TableUtils.lua")

local CryptoMath = {}

function CryptoMath.uvrandom(min, max)
	assert(min, 'expected lower bound')
	assert(max, 'expected upper bound')
	assert(max > min, 'expected max > min')
	local range = max - min
	
	local log256range = math.ceil(math.log(range, 256)) -- number of bytes required to store range

	local bytes = uv.random(log256range * 2) -- get double the bytes required so we can distribute evenly with modulo
	local random = 0

	for i = 1, #bytes do
		random = bit.lshift(random, 8) + bytes:byte(i, i)
	end
	
	return random % range + min
end

local charIgnoreList = {
    58,
    59,
    60,
    61,
    62,
    63,
    64,
    91,
    92,
    93,
    94,
    96,
    123,
    124,
    125
}

function CryptoMath.RandomString(length)
	local str = ""
	for i = 1, length do
		--local randomNum = cryptoMath.uvrandom(65,126)
		local randomNum
		repeat
			randomNum = CryptoMath.uvrandom(48,126)
		until not TableUtils.Find(charIgnoreList, randomNum)
		local randomChar = string.char(randomNum)
		str = str..randomChar
	end
	return str
end

return CryptoMath