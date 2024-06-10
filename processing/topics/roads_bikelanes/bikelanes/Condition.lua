package.path = package.path .. ";/processing/topics/helper/?.lua"
require("Set")

--- @class Condition
--- This class is an abstract class from which specific implementatios can inhert from.
--- It implements only the two function `__add` and `__mul`.
Condition = {}
Condition.__index = Condition

function Condition:new(name)
  local cond = {name = name}
  setmetatable(cond, self)
  self.__index = self
  return cond
end

-- JUNCTORS: are used to combine different conditions
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

--- @class Negation
--- This class implements the negation of a Condition `C` such that it evaluates to `not C:eval()`
Negation = Condition:new()
function Negation:new(condition)
  local neg = {condition = condition}
  setmetatable(neg, self)
  self.__index = self
  return neg
end

function Negation:eval(x)
  return not self.condition:eval(x)
end

function Condition.__unm(cond)
  return Negation:new(cond)
end

-- double negation equals the original condition
function Negation.__unm(neg)
  return neg.condition
end

-- DeMorgan rules
function Conjunction.__unm(conj)
  return Disjunction:new(-conj.A, -conj.B)
end

function Disjunction.__unm(disj)
  return Conjunction:new(-disj.A, -disj.B)
end

function Condition.__add(A, B)
  return Disjunction:new(A, B)
end

-- Assoziativity
function Disjunction.__mul(A, B)
  if getmetatable(A) == getmetatable(B) then
    return Disjunction:new(Disjunction:new(A.A * B.A, A.B * B.A), Disjunction:new(A.A * B.B, A.B * B.B))
  end
  if getmetatable(A) == Disjunction then
    return Disjunction:new(A.A * B, A.B * B)
  end
   if getmetatable(B) == Disjunction then
    return Disjunction:new(B.A * A, B.B * A )
  end
  error("This should never happen")
end

function Condition.__mul(A, B)
  return Conjunction:new(A, B)
end

-- tostring methods
function Condition:__tostring()
  return self.name
end

function Negation:__tostring()
  return "¬" .. self.condition:__tostring()
end

function Disjunction:__tostring()
  return "(" .. self.A:__tostring() .. " ∨ " .. self.B:__tostring() .. ")"
end

function Conjunction:__tostring()
  return "(" .. self.A:__tostring() .. " ∧ " .. self.B:__tostring() .. ")"
end

-- PREDICATES: are conditions specific to our data
--- @class Predicate is an atomic condition
Predicate = Condition:new()
Predicate.count = 0
function Predicate:new()
  local pred = {id = self.count}
  self.count = self.count + 1
  setmetatable(pred, self)
  self.__index = self
  return pred
end

--- @class TagPredicate is a Predicate evaluated on `tag`
TagPredicate = Predicate:new()
function TagPredicate:new(tag, sanitizer)
  local tPred = Predicate:new()
  tPred.sanitizer = sanitizer or function (x) return x end
  tPred.tag = tag
  setmetatable(tPred, self)
  self.__index = self
  return tPred
end

function TagPredicate:eval(x)
  return x[self.tag] ~= nil and self.condition(self.sanitizer(x[self.tag]))
end

EqualsPredicate = TagPredicate:new()

function EqualsPredicate:new(tag, val, sanitizer)
  local ePred = TagPredicate:new(tag, sanitizer)
  ePred.condition = function(x) return x == val end
  setmetatable(ePred, self)
  self.__index = self
  return ePred
end

ContainsPredicate = TagPredicate:new()

function ContainsPredicate:new(tag, val, sanitizer)
  local cPred = TagPredicate:new(tag, sanitizer)
  cPred.condition = function(x) return string.find(x, val, 1, true) ~= nil end
  setmetatable(cPred, self)
  self.__index = self
  return cPred
end

PrefixPredicate = TagPredicate:new()

function PrefixPredicate:new(tag, prefix, sanitzer)
  local pPred = TagPredicate:new(tag, sanitzer)
  pPred.condition = function(x) return string.find(x, prefix, 1, true) == 1 end
  setmetatable(pPred, self)
  self.__index = self
  return pPred
end

OneOfPredicate = TagPredicate:new()

function OneOfPredicate:new(tag, values, sanitzer)
  local ooPred = TagPredicate:new(tag, sanitzer)
  ooPred.condition = function(x) return Set(values)[x] end
  setmetatable(ooPred, self)
  self.__index = self
  return ooPred
end
