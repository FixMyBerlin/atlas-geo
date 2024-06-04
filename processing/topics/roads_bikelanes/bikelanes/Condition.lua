package.path = package.path .. ";/processing/topics/helper/?.lua"
require("Set")

--- @class Condition
--- this class represents a condition which can either be atomic or a composition of several conditions
Condition = {}
Condition.__index = Condition

function Condition:new(condition)
  local p = {condition = condition}
  setmetatable(p, self)
  self.__index = self
  return p
end

function Condition:eval(x)
  return self.condition(x)
end

function Condition.__add(c1, c2)
  return Condition:new(function(x) return c1:eval(x) or c2:eval(x) end)
end

function Condition.__mul(c1, c2)
  return Condition:new(function(x) return c1:eval(x) and c2:eval(x) end)
end

function Condition:negated()
  return Condition:new(function(x) return not self:eval(x) end)
end

--- @class Predicate is an atomic condition
Predicate = Condition:new()
Predicate.count = 0
function Predicate:new()
  local p = {id = self.count}
  self.count = self.count + 1
  setmetatable(p, self)
  self.__index = self
  return p
end

--- @class TagPredicate is a Predicate evaluated on `tag`
TagPredicate = Predicate:new()
function TagPredicate:new(tag, sanitizer)
  local tp = Predicate:new()
  tp.sanitizer = sanitizer or function (x) return x end
  tp.tag = tag
  setmetatable(tp, self)
  self.__index = self
  return tp
end

function TagPredicate:eval(x)
  return x[self.tag] ~= nil and self.condition(self.sanitizer(x[self.tag]))
end

EqualsPredicate = TagPredicate:new()

function EqualsPredicate:new(tag, val, sanitizer)
  local ip = TagPredicate:new(tag, sanitizer)
  ip.condition = function(x) return x == val end
  setmetatable(ip, self)
  self.__index = self
  return ip
end

ContainsPredicate = TagPredicate:new()

function ContainsPredicate:new(tag, val, sanitizer)
  local cp = TagPredicate:new(tag, sanitizer)
  cp.condition = function(x) return string.find(x, val, 1, true) ~= nil end
  setmetatable(cp, self)
  self.__index = self
  return cp
end

PrefixPredicate = TagPredicate:new()

function PrefixPredicate:new(tag, prefix, sanitzer)
  local pp = TagPredicate:new(tag, sanitzer)
  pp.condition = function(x) return string.find(x, prefix, 1, true) == 1 end
  setmetatable(pp, self)
  self.__index = self
  return pp
end

OneOfPredicate = TagPredicate:new()

function OneOfPredicate:new(tag, values, sanitzer)
  local pp = TagPredicate:new(tag, sanitzer)
  pp.condition = function(x) return Set(values)[x] end
  setmetatable(pp, self)
  self.__index = self
  return pp
end
