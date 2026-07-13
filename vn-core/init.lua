local fPath = (...).."."
local require_o = require
require = function (p)
	return require_o(fPath..p)
end

local ret = {
	chara = require "chara",
	story = require "story"
}
ret.story.decision = require "story.decision"
ret.story.funcs = require "story.funcs"
ret.story.part = require "story.part"

require = require_o
return ret