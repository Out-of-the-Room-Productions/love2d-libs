Funcs = Funcs or {}
---@diagnostic disable-next-line: lowercase-global
vmath = {}

table.unpack = unpack


---@class math.MappingData
---@field map fun(nin:number):number

---@param min any
---@param max any
---@return math.MappingData
function Funcs.premap(min, max, fromA, fromB)
	local data = {}

	fromA = fromA or -1.0
	fromB = fromB or  1.0
	local toA = min
	local toB = max

	local deltaA = fromB - fromA
	local deltaB = toB - toA

	local scale  = deltaB / deltaA
	local negA   = -1 * fromA
	local offset = (negA * scale) + toA

	data[1] = scale
	data[2] = offset
	data.map = function (nin)
		return (nin * data[1]) + data[2]
	end
	return data
end

---@param x number
---@param y number
---@return number
function Funcs.hash_xy(x, y)
	return (x * 0x1f1f1f1f) ^ y
end

---@param ... any
---@return number
function Funcs.hash(...)
	local ph = ""
	for _, value in pairs{...} do
		ph = ph..tostring(value)
	end
	return Funcs.hashstr(ph)
end

---@param str string
---@return number
function Funcs.hashstr(str)
	local h = 5381
	for c in str:gmatch(".") do
		h = (bit.lshift(h, 5) + h) + string.byte(c)
	end
	return h
end

function Funcs.jump_consistent_hash(key, num_buckets)
    local b = -1
    local j = 0
    while j < num_buckets do
        b = j
        key = key * 2862933555777941757 + 1
        j = math.floor((b+1) * (bit.lshift(1, 31)) / (bit.rshift(key, 33) + 1))
    end
    return b
end

-- Function to calculate perpendicular distance
local function perpendicularDistance(point, lineStart, lineEnd)
    local x = point.x
    local y = point.y
    local x1 = lineStart.x
    local y1 = lineStart.y
    local x2 = lineEnd.x
    local y2 = lineEnd.y

    local A = x - x1
    local B = y - y1
    local C = x2 - x1
    local D = y2 - y1

    local dot = A * C + B * D
    local len_sq = C * C + D * D
    local param = -1

    if len_sq ~= 0 then
        param = dot / len_sq
    end

    local xx, yy

    if param < 0 then
        xx = x1
        yy = y1
    elseif param > 1 then
        xx = x2
        yy = y2
    else
        xx = x1 + param * C
        yy = y1 + param * D
    end

    local dx = x - xx
    local dy = y - yy

    return math.sqrt(dx * dx + dy * dy)
end

-- Function to simplify a polyline using Douglas-Peucker algorithm
function Funcs.douglasPeucker(PointList, epsilon)
    local endIdx = #PointList
    local dmax = 0
    local index = 0

    for i = 2, endIdx - 1 do
        local d = perpendicularDistance(PointList[i], PointList[1], PointList[endIdx])
        if d > dmax then
            index = i
            dmax = d
        end
    end

    local ResultList = {}

    if dmax > epsilon then
        local recResults1 = Funcs.douglasPeucker({unpack(PointList, 1, index)}, epsilon)
        local recResults2 = Funcs.douglasPeucker({unpack(PointList, index, endIdx)}, epsilon)

        for i = 1, #recResults1 - 1 do
            table.insert(ResultList, recResults1[i])
        end

        for i = 1, #recResults2 do
            table.insert(ResultList, recResults2[i])
        end
    else
        table.insert(ResultList, PointList[1])
        table.insert(ResultList, PointList[endIdx])
    end

    return ResultList
end


-- Function to convert a table of numbers into a table of point tables
function Funcs.tableToPoints(NumberTable)
    local PointTable = {}
    for i = 1, #NumberTable, 2 do
        table.insert(PointTable, {x = NumberTable[i], y = NumberTable[i + 1]})
    end
    return PointTable
end

-- Function to convert a table of point tables into a table of numbers
function Funcs.pointsToTable(PointTable)
    local NumberTable = {}
    for i, point in ipairs(PointTable) do
        table.insert(NumberTable, point.x)
        table.insert(NumberTable, point.y)
    end
    return NumberTable
end

---@param weights number[]
---@param items any[]
---@return any
function math.weighted(weights, items)
	local wVals = {}
	local total = 0.0

	for i, value in ipairs(weights) do
		wVals[i] = total + value
		total = total + value
	end

	local wRandom = math.random() * total

	for i, value in ipairs(wVals) do
		if wRandom < value then
			return items[i]
		end
	end

	Logger:error("math", ("weighted random hit end, itemCount: %d, weightCount: %d"):format(#weights, #items))
	error("shouldn't happen")
end

---@diagnostic disable-next-line: lowercase-global
wraptfunc = function(t, fun)
	return t, Funcs.wrap(t, fun)
end

function Funcs.wrap(t, fun)
	return function (...)
		return fun(t, ...)
	end
end

---@diagnostic disable-next-line: lowercase-global
local function tprint (tbl, height, indent)
	if not tbl then return end
	if not height then height = 0 end
	if not indent then indent = 0 end
	for k, v in pairs(tbl) do
		height = height+1
		local formatting = string.rep("  ", indent) .. k .. ": "
		if type(v) == "table" then
			print(formatting, indent*8, 16*height)
			tprint(v, height+1, indent+1)
		elseif type(v) == 'function' then
			print(formatting .. "function", indent*8, 16*height)
		elseif type(v) == 'boolean' then
			print(formatting .. tostring(v), indent*8, 16*height)
		else
			print(formatting .. v, indent*8, 16*height)
		end
	end
end

-- Print contents of `tbl`, with indentation.
-- `indent` sets the initial level of indentation.
function Funcs.tprint (tbl, indent)
    if not indent then indent = 0 end
    for k, v in pairs(tbl) do
---@diagnostic disable-next-line: lowercase-global
      formatting = string.rep("  ", indent) .. k .. ": "
      if type(v) == "table" then
        print(formatting)
        tprint(v, indent+1)
      elseif type(v) == 'boolean' then
        print(formatting .. tostring(v))      
	  elseif type(v) then
        print(formatting .. tostring(v))
      end
    end
end


function Funcs.newUuid()
	math.randomseed(os.time())
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

---@param time number
function Funcs.elapsed(time)
	return love.timer.getTime() - time
end

---@generic T
---@param t1 T[]
---@param t2 T[]
---@param copykey boolean
---@return T[]
function Funcs.combine(t1, t2, copykey)
	for key, value in pairs(t2) do
		if copykey then
			t1[key] = value
		else
			table.insert(t1, value)
		end
	end
	return t1
end

function Funcs.smoothstep(t)
	return (1 - math.cos(t * math.pi)) * 0.5
end

function Funcs.plateaumap(noise_value, threshold, plateau_height, plateau_width)
    local remapped_value = math.floor(noise_value / threshold) * threshold
    local smoothstep_t = (noise_value - remapped_value) / plateau_width
    local smoothstep_value = Funcs.smoothstep(smoothstep_t)

    -- Combine remapped_value with smoothstep_value
    local plateau_noise_value = remapped_value + smoothstep_value * plateau_height

    return plateau_noise_value
end

---@param x number
---@param y number
---@param noiseFunc fun(x:number, y:number):number
---@param stepSize? number
---@return number
---@return number
function Funcs.calculate_slope(x, y, noiseFunc, stepSize)
 -- Calculate the change in x and y for finite differences
	local dx = stepSize
	local dy = stepSize

	-- Calculate the height at the current point
	local centerHeight = noiseFunc(x, y)

	-- Calculate the heights at nearby points
	local heightRight = noiseFunc(x + dx, y)
	local heightUp = noiseFunc(x, y + dy)

	-- Calculate the slopes in the x and y directions
	local slopeX = (heightRight - centerHeight) / dx
	local slopeY = (heightUp - centerHeight) / dy

	-- Return the slopes
	return math.sqrt((slopeX ^ 2) + (slopeY ^ 2)), centerHeight -- slopeX, slopeY
end

---@param nx number
---@param ny number
---@param noisef fun(x:number, y:number):number
---@param h? number
---@return number
function Funcs.o_calculate_slope(nx, ny, noisef, h)
	h = h or 0.001
	local slope_x = (noisef(nx + h, ny) - noisef(nx - h, ny)) / (2 * h)
	local slope_y = (noisef(nx, ny + h) - noisef(nx, ny - h)) / (2 * h)
	return slope_x -- math.sqrt((slope_x ^ 2) + (slope_y ^ 2))
end

function math.wrapF(value, min, max)
	local range = (max - min)
    return min + (value - min) % range
end

function math.wrapI(value, min, max)
    local range = max - min + 1
    return ((value - min) % range) + min
end

local Flags = {
}
Funcs.flags = Flags

---@param v integer
---@param flag integer
---@return boolean
function Flags.hasFlag(v, flag)
	return bit.band(v, flag) ~= 0
end

function Flags.setFlag(v, flag)
	return bit.bor(v, flag)
end

function Flags:unsetFlag(v, flag)
	return bit.band(v, bit.bnot(flag))
end

function Flags.set(v, flag, val)
	if val then
		return Flags.setFlag(v, flag)
	else
		return Flags.unsetFlag(v, flag)
	end
end



function math.sign(x)
	return math.max(math.min(x * 1e200 * 1e200, 1), -1)
end

-- https://love2d.org/wiki/General_math
-- Returns 'n' rounded to the nearest 'deci'th (defaulting whole numbers).
function math.round(n, deci)
	deci = 10^(deci or 0)
	return math.floor(n*deci+.5)/deci
end

function table.getIndex(col, item)
	local fun = type(item) == "function"
	for index, value in ipairs(col) do
		if fun and item(value) or item == value then
			return index
		end
	end
	return 0
end

function table.removeItem(col, item)
    local i = table.getIndex(col, item)
    if i then
        table.remove(col, i)
    end
end

function table.clone(org)
	return {unpack(org)}
end

-- https://stackoverflow.com/a/1283608
function table.merge(t1, t2)
    for k, v in pairs(t2) do
        if type(v) == "table" then
            if type(t1[k] or false) == "table" then
                table.merge(t1[k] or {}, t2[k] or {})
            else
                t1[k] = v
            end
        else
            t1[k] = v
        end
    end
    return t1
end

function table.deepcopy(orig, copies)
    copies = copies or {}
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in next, orig, nil do
                copy[table.deepcopy(orig_key, copies)] = table.deepcopy(orig_value, copies)
            end
            setmetatable(copy, table.deepcopy(getmetatable(orig), copies))
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end


function math.isNaN(n)
    return tostring(n) == "nan"
end

--[[Imprecise method, which does not guarantee v = v1 when t = 1, due to floating-point arithmetic error. 
This method is monotonic. This form may be used when the hardware has a native fused multiply-add instruction.]]
---@param v0 number
---@param v1 number
---@param t number
---@return number
function math.lerp(v0, v1, t)
    return v0 + t * (v1 - v0);
end

--[[Precise method, which guarantees v = v1 when t = 1. This method is monotonic only when v0 * v1 < 0.
Lerping between same values might not produce the same value]]
---@param v0 any
---@param v1 any
---@param t any
---@return unknown
function math.lerpB(v0, v1, t)
    return (1 - t) * v0 + t * v1;
end

function math.clamp01(n)
    return math.clamp(n, 0, 1)
end

function math.clamp(n, min, max)
    return math.min(max, math.max(n, min))
end

---@param a number
---@param b number
---@param m? number margin (default: 0.00001)
function math.almostEqual(a, b, m)
	m = m or 0.00001
	return math.abs(a - b) < m
end

---@param n integer
---@param f fun():string
function Funcs.freqTest(n, f)
    local ress = {}
    for i = 1, n or 1, 1 do
        local r = f()
        ress[r] = (ress[r] or 0) + 1
    end
    tprint(ress)
end

---@param path string
---@return string[]
function Funcs.getRequirePaths(path)
	local paths = Funcs.getFilesRecursive(path)
	---@type string[]
	local res = {}
	for _, value in ipairs(paths) do
		local sub, _ = value:gsub("/", ".")
		table.insert(res, sub)
	end
	return res
end

---@param path string
---@return string[]
function Funcs.getFilesRecursive(path)
	---@type string[]
	local paths = {}
	local res = {}
	local gi = love.filesystem.getDirectoryItems

	for _, p in ipairs(gi(path)) do
		table.insert(paths, path.."/"..p)
	end

	while #paths > 0 do
		local cur = paths[#paths]
		table.remove(paths)
		if cur:find(".lua") then
			local sub, _ = cur:gsub(".lua", "")
			table.insert(res, sub)
			goto continue
		else
			for _, p in ipairs(gi(cur)) do
				table.insert(paths, cur.."/"..p)
			end
		end
	    ::continue::
	end

	return res
end

---@overload fun(v1:table, v2:table):number
---@param v1 number|table
---@param v2 number|table
---@param xb number
---@param yb number
---@return number
function vmath.distance(v1, v2, xb, yb)
	local dx
	local dy
	if type(v1) == "table" then
		dx = v2.x - v1.x
    	dy = v2.y - v1.y
	else
		dx = xb - v1
		dy = yb - v2
	end
    return math.sqrt(dx*dx + dy*dy)
end

---@param x number
---@param y number
---@return number
---@return number
function vmath.normalize(x, y)
    local magnitude = math.sqrt(x ^ 2 + y ^ 2)
    if magnitude > 0 then
      return x / magnitude, y / magnitude
    else
      return 0, 0
    end
end

function vmath.magnitude(x, y)
    local m = x*x + y*y
    if m then
        return math.sqrt(m)
    end
    return 0
end

---@diagnostic disable-next-line: lowercase-global
function md5(input_string)

	local bit = require("bit")
---@diagnostic disable-next-line: undefined-field
	local tobit, tohex, bnot = bit.tobit or bit.cast, bit.tohex, bit.bnot
	local bor, band, bxor = bit.bor, bit.band, bit.bxor
	local lshift, rshift, rol, bswap = bit.lshift, bit.rshift, bit.rol, bit.bswap
	local byte, char, sub, rep = string.byte, string.char, string.sub, string.rep

	if not rol then -- Replacement function if rotates are missing.
	  local bor, shl, shr = bit.bor, bit.lshift, bit.rshift
	  function rol(a, b) return bor(shl(a, b), shr(a, 32-b)) end
	end

	if not bswap then -- Replacement function if bswap is missing.
	  local bor, band, shl, shr = bit.bor, bit.band, bit.lshift, bit.rshift
	  function bswap(a)
		 return bor(shr(a, 24), band(shr(a, 8), 0xff00),
				 shl(band(a, 0xff00), 8), shl(a, 24));
	  end
	end

	if not tohex then -- (Unreliable) replacement function if tohex is missing.
	  function tohex(a)
		 return string.sub(string.format("%08x", a), -8)
	  end
	end

	local function tr_f(a, b, c, d, x, s)
	  return rol(bxor(d, band(b, bxor(c, d))) + a + x, s) + b
	end

	local function tr_g(a, b, c, d, x, s)
	  return rol(bxor(c, band(d, bxor(b, c))) + a + x, s) + b
	end

	local function tr_h(a, b, c, d, x, s)
	  return rol(bxor(b, c, d) + a + x, s) + b
	end

	local function tr_i(a, b, c, d, x, s)
	  return rol(bxor(c, bor(b, bnot(d))) + a + x, s) + b
	end

	local function transform(x, a1, b1, c1, d1)
	  local a, b, c, d = a1, b1, c1, d1

	  a = tr_f(a, b, c, d, x[ 1] + 0xd76aa478,  7)
	  d = tr_f(d, a, b, c, x[ 2] + 0xe8c7b756, 12)
	  c = tr_f(c, d, a, b, x[ 3] + 0x242070db, 17)
	  b = tr_f(b, c, d, a, x[ 4] + 0xc1bdceee, 22)
	  a = tr_f(a, b, c, d, x[ 5] + 0xf57c0faf,  7)
	  d = tr_f(d, a, b, c, x[ 6] + 0x4787c62a, 12)
	  c = tr_f(c, d, a, b, x[ 7] + 0xa8304613, 17)
	  b = tr_f(b, c, d, a, x[ 8] + 0xfd469501, 22)
	  a = tr_f(a, b, c, d, x[ 9] + 0x698098d8,  7)
	  d = tr_f(d, a, b, c, x[10] + 0x8b44f7af, 12)
	  c = tr_f(c, d, a, b, x[11] + 0xffff5bb1, 17)
	  b = tr_f(b, c, d, a, x[12] + 0x895cd7be, 22)
	  a = tr_f(a, b, c, d, x[13] + 0x6b901122,  7)
	  d = tr_f(d, a, b, c, x[14] + 0xfd987193, 12)
	  c = tr_f(c, d, a, b, x[15] + 0xa679438e, 17)
	  b = tr_f(b, c, d, a, x[16] + 0x49b40821, 22)

	  a = tr_g(a, b, c, d, x[ 2] + 0xf61e2562,  5)
	  d = tr_g(d, a, b, c, x[ 7] + 0xc040b340,  9)
	  c = tr_g(c, d, a, b, x[12] + 0x265e5a51, 14)
	  b = tr_g(b, c, d, a, x[ 1] + 0xe9b6c7aa, 20)
	  a = tr_g(a, b, c, d, x[ 6] + 0xd62f105d,  5)
	  d = tr_g(d, a, b, c, x[11] + 0x02441453,  9)
	  c = tr_g(c, d, a, b, x[16] + 0xd8a1e681, 14)
	  b = tr_g(b, c, d, a, x[ 5] + 0xe7d3fbc8, 20)
	  a = tr_g(a, b, c, d, x[10] + 0x21e1cde6,  5)
	  d = tr_g(d, a, b, c, x[15] + 0xc33707d6,  9)
	  c = tr_g(c, d, a, b, x[ 4] + 0xf4d50d87, 14)
	  b = tr_g(b, c, d, a, x[ 9] + 0x455a14ed, 20)
	  a = tr_g(a, b, c, d, x[14] + 0xa9e3e905,  5)
	  d = tr_g(d, a, b, c, x[ 3] + 0xfcefa3f8,  9)
	  c = tr_g(c, d, a, b, x[ 8] + 0x676f02d9, 14)
	  b = tr_g(b, c, d, a, x[13] + 0x8d2a4c8a, 20)

	  a = tr_h(a, b, c, d, x[ 6] + 0xfffa3942,  4)
	  d = tr_h(d, a, b, c, x[ 9] + 0x8771f681, 11)
	  c = tr_h(c, d, a, b, x[12] + 0x6d9d6122, 16)
	  b = tr_h(b, c, d, a, x[15] + 0xfde5380c, 23)
	  a = tr_h(a, b, c, d, x[ 2] + 0xa4beea44,  4)
	  d = tr_h(d, a, b, c, x[ 5] + 0x4bdecfa9, 11)
	  c = tr_h(c, d, a, b, x[ 8] + 0xf6bb4b60, 16)
	  b = tr_h(b, c, d, a, x[11] + 0xbebfbc70, 23)
	  a = tr_h(a, b, c, d, x[14] + 0x289b7ec6,  4)
	  d = tr_h(d, a, b, c, x[ 1] + 0xeaa127fa, 11)
	  c = tr_h(c, d, a, b, x[ 4] + 0xd4ef3085, 16)
	  b = tr_h(b, c, d, a, x[ 7] + 0x04881d05, 23)
	  a = tr_h(a, b, c, d, x[10] + 0xd9d4d039,  4)
	  d = tr_h(d, a, b, c, x[13] + 0xe6db99e5, 11)
	  c = tr_h(c, d, a, b, x[16] + 0x1fa27cf8, 16)
	  b = tr_h(b, c, d, a, x[ 3] + 0xc4ac5665, 23)

	  a = tr_i(a, b, c, d, x[ 1] + 0xf4292244,  6)
	  d = tr_i(d, a, b, c, x[ 8] + 0x432aff97, 10)
	  c = tr_i(c, d, a, b, x[15] + 0xab9423a7, 15)
	  b = tr_i(b, c, d, a, x[ 6] + 0xfc93a039, 21)
	  a = tr_i(a, b, c, d, x[13] + 0x655b59c3,  6)
	  d = tr_i(d, a, b, c, x[ 4] + 0x8f0ccc92, 10)
	  c = tr_i(c, d, a, b, x[11] + 0xffeff47d, 15)
	  b = tr_i(b, c, d, a, x[ 2] + 0x85845dd1, 21)
	  a = tr_i(a, b, c, d, x[ 9] + 0x6fa87e4f,  6)
	  d = tr_i(d, a, b, c, x[16] + 0xfe2ce6e0, 10)
	  c = tr_i(c, d, a, b, x[ 7] + 0xa3014314, 15)
	  b = tr_i(b, c, d, a, x[14] + 0x4e0811a1, 21)
	  a = tr_i(a, b, c, d, x[ 5] + 0xf7537e82,  6)
	  d = tr_i(d, a, b, c, x[12] + 0xbd3af235, 10)
	  c = tr_i(c, d, a, b, x[ 3] + 0x2ad7d2bb, 15)
	  b = tr_i(b, c, d, a, x[10] + 0xeb86d391, 21)

	  return tobit(a+a1), tobit(b+b1), tobit(c+c1), tobit(d+d1)
	end

	-- Note: this is copying the original string and NOT particularly fast.
	-- A library for struct unpacking would make this task much easier.
	local function md5(msg)
	  local len = #msg
	  msg = msg.."\128"..rep("\0", 63 - band(len + 8, 63))
			..char(band(lshift(len, 3), 255), band(rshift(len, 5), 255),
			  band(rshift(len, 13), 255), band(rshift(len, 21), 255))
			.."\0\0\0\0"
	  local a, b, c, d = 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476
	  local x, k = {}, 1
	  for i=1,#msg,4 do
		 local m0, m1, m2, m3 = byte(msg, i, i+3)
		 x[k] = bor(m0, lshift(m1, 8), lshift(m2, 16), lshift(m3, 24))
		 if k == 16 then
			a, b, c, d = transform(x, a, b, c, d)
			k = 1
		 else
			k = k + 1
		 end
	  end
	  return tohex(bswap(a))..tohex(bswap(b))..tohex(bswap(c))..tohex(bswap(d))
	end

  	return md5(input_string);

end

return Funcs