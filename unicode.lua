local bit32 = require('bit')
unicode = {}

function unicode.utf32_to_utf8_char(utf32chr)
	assert(type(utf32chr) == 'number')
	if utf32chr < 0 or 0x10ffff < utf32chr then
		return nil
	end
	if utf32chr < 128 then
		return string.char(utf32chr)
	elseif utf32chr < 2048 then
		local c1 = bit32.bor(0xc0, bit32.rshift(utf32chr, 6))
		local c2 = bit32.bor(0x80, bit32.band(utf32chr, 0x3f))
		return string.char(c1, c2)
	elseif utf32chr < 65536 then
		local c1 = bit32.bor(0xe0, bit32.rshift(utf32chr, 12))
		local c2 = bit32.bor(0x80, bit32.band(bit32.rshift(utf32chr, 6), 0x3f))
		local c3 = bit32.bor(0x80, bit32.band(utf32chr, 0x3f))
		return string.char(c1, c2, c3)
	else
		local c1 = bit32.bor(0xf0, bit32.rshift(utf32chr, 18))
		local c2 = bit32.bor(0x80, bit32.band(bit32.rshift(utf32chr, 12), 0x3f))
		local c3 = bit32.bor(0x80, bit32.band(bit32.rshift(utf32chr, 6), 0x3f))
		local c4 = bit32.bor(0x80, bit32.band(utf32chr, 0x3f))
		return string.char(c1, c2, c3)
	end
end

function unicode.utf32_to_utf8(utf32str)
	assert(type(utf32str) == 'table')
	local result = ""
	local i
	for i = 1, #utf32str do
		local c = utf32str[i]
		result = result .. unicode.utf32_to_utf8_char(c)
	end
	return result
end

local function get_utf8_byte_count(ch)
	assert(type(ch)=="number")
	if 0 <= ch and ch < 0x80 then
		return 1
	elseif 0xc2 <= ch and ch < 0xE0 then
		return 2
	elseif 0xe0 <= ch and ch < 0xf0 then
		return 3
	elseif 0xf0 <= ch and ch < 0xf8 then
		return 4
	else
		return 0
	end
end

local function is_utf8_layer_byte(ch)
	assert(type(ch)=="number")
	return 0x80 <= ch and ch < 0xc0
end

function unicode.utf8_to_utf32(str)
	assert(type(str)=='string')
	local result = {};
	local i = 1
	while i <= #str do
		local c1 = string.byte(str, i, i)
		local num_byte = get_utf8_byte_count(c1)
		if num_byte == 0 then
			return nil
		end
		if num_byte == 1 then
			table.insert(result, c1)
			i = i + 1
		elseif num_byte == 2 then
			local c2 = string.byte(str, i+1, i+1)
			if (not is_utf8_layer_byte(c2)) or bit32.band(c1, 0x1e) == 0 then
				return nil
			end
			local cp = bit32.lshift(bit32.band(c1, 0x1f), 6)
			cp = bit32.bor(c2, cp)
			table.insert(result, cp)
			i = i + 2
		elseif num_byte == 3 then
			local c2 = string.byte(str, i+1, i+1)
			local c3 = string.byte(str, i+2, i+2)
			if (not is_utf8_layer_byte(c2)) or (not is_utf8_layer_byte(c3)) then
				return nil
			end
			if bit32.band(c1, 0x0f) == 0 and bit32.band(c2, 0x20) == 0 then
				return nil
			end
			local cp = bit32.lshift(bit32.band(c1, 0x0f), 12)
			cp = bit32.bor(cp, bit32.lshift(bit32.band(c2, 0x3f), 6))
			cp = bit32.bor(cp, bit32.band(c3, 0x3f))
			table.insert(result, cp)
			i = i + 3
		elseif num_byte == 4 then
			local c2 = string.byte(str, i+1, i+1)
			local c3 = string.byte(str, i+2, i+2)
			local c4 = string.byte(str, i+3, i+3)
			local cp = bit32.lshift(bit32.band(c1, 0x07), 18)
			if (not is_utf8_layer_byte(c2)) or (not is_utf8_layer_byte(c3)) or (not is_utf8_layer_byte(c4)) then
				return nil
			end
			if bit32.band(c1, 0x07) == 0 and bit32.band(c2, 0x30) == 0 then
				return nil
			end
			cp = bit32.bor(cp, bit32.lshift(bit32.band(c2, 0x3f), 12))
			cp = bit32.bor(cp, bit32.lshift(bit32.band(c3, 0x3f), 6))
			cp = bit32.bor(cp, bit32.band(c4, 0x3f))
			table.insert(result, cp)
			i = i + 4
		else
			return nil
		end
	end
	return result
end

function unicode.utf32_to_utf16(str)
	assert(type(str)=='table')
	local result = {}
	local i
	for i = 1, #str do
		local u32 = str[i]
		if u32 < 0 or u32 > 0x10ffff then
			return nil
		end
		if u32 < 0x10000 then
			table.insert(result, u32)
		else
			local c1 = math.floor((u32 - 0x10000) / 0x400) + 0xd800
			local c2 = (u32 - 0x10000) % 0x400 + 0xdc00
			table.insert(result, c1)
			table.insert(result, c2)
		end
	end
	return result
end

local function is_utf16_high_surrogate(utf16chr)
	assert(type(utf16chr) == 'number')
	return 0xd800 <= utf16chr and utf16chr < 0xdc00
end

local function is_utf16_low_surrogate(utf16chr)
	assert(type(utf16chr) == 'number')
	return 0xdc00 <= utf16chr and utf16chr < 0xe000
end

function unicode.utf16_to_utf32(utf16str)
	assert(type(utf16str)=='table')
	local result = {}
	local i = 1
	while i <= #utf16str do
		local utf16chr1 = utf16str[i]
		if is_utf16_high_surrogate(utf16chr1) then
			local utf16chr2 = utf16str[i+1]
			i = i + 2
			if (is_utf16_low_surrogate(utf16chr2)) then
				local c = 0x10000 + (utf16chr1 - 0xd800) * 0x400 + (utf16chr2 - 0xdc00)
				table.insert(result, c)
			elseif utf16chr2 == 0 then
				table.insert(result, utf16chr1)
			else
				return nil
			end
		elseif is_utf16_low_surrogate(utf16chr1) then
			i = i + 1
			if utf16chr2 == 0 then
				table.insert(result, utf16chr1)
			else
				return nil
			end
		else
			i = i + 1
			table.insert(result, utf16chr1)
		end
	end
	return result
end

function unicode.utf8_to_utf16(utf8str)
	assert(type(utf8str) == 'string')
	local utf32str = unicode.utf8_to_utf32(utf8str)
	if utf32str == nil then
		return nil
	else
		return unicode.utf32_to_utf16(utf32str)
	end
end

function unicode.utf16_to_utf8(utf16str)
	assert(type(utf16str) == 'table')
	local utf32str = unicode.utf16_to_utf32(utf16str)
	if utf32str == nil then
		return nil
	else
		return unicode.utf32_to_utf8(utf32str)
	end
end

