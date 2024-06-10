package.path = package.path .. ";/processing/topics/helper/?.lua"
require("Set")

--- @class Condition
--- This class is an abstract class from which specific implementatios can inhert from.
--- It implements only the two function `__add` and `__mul`.
Condition = {}
Condition.__index = Condition

function Condition:new()
  local c = {}
  setmetatable(c, self)
  self.__index = self
  return c
end

--- @class Conjunction
--- This class implements the conjunction of two Conditions `A` and `B` such that it evaluates to `A:eval() and B:eval()`
Conjunction = Condition:new()
function Conjunction:new(A, B)
  local conj = {A = A, B = B}
  setmetatable(conj, self)
  self.__index = self
  return conj
end

function Conjunction:eval(x)
  return self.A:eval(x) and self.B:eval(x)
end

--- @class Disjunction
--- This class implements the disjunction of two Conditions `A` and `B` such that it evaluates to `A:eval() or B:eval()`
Disjunction = Condition:new()
function Disjunction:new(A, B)
  local disj = {A = A, B = B}
  setmetatable(disj, self)
  self.__index = self
  return disj
end

function Disjunction:eval(x)
  return self.A:eval(x) or self.B:eval(x)
end

function Condition.__add(c1, c2)
  return Disjunction:new(c1, c2)
end

function Condition.__mul(c1, c2)
  return Conjunction(c1, c2)
end

--- @class Negation
--- This class implements the negation of a Conditions `C` such that it evaluates to `not C:eval()`
Negation = Condition:new()
function Negation:new(condition)
  local n = {condition = condition}
  setmetatable(n, self)
  self.__index = self
  return n
end

function Negation:eval(x)
  return not self.condition:eval(x)
end

function Condition:negated()
  return Negation:new(self)
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
  local oop = TagPredicate:new(tag, sanitzer)
  oop.condition = function(x) return Set(values)[x] end
  setmetatable(oop, self)
  self.__index = self
  return oop
end
