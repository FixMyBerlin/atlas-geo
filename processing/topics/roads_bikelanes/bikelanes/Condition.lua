package.path = package.path .. ";/processing/topics/helper/?.lua"
require("Set")

local _metamethods = { -- all metamethods except __index
  '__add', '__call', '__concat', '__div', '__le', '__lt', '__mod', '__mul', '__pow', '__sub', '__tostring', '__unm'
}

local function inheritmetamethods(class)
  local superClass = getmetatable(class)
  for _, mm in pairs(_metamethods) do
    class[mm] = superClass[mm]
  end
end

local function subclass(superClass)
  local class = superClass:new()
  inheritmetamethods(class)
  return class
end

--- @class BooleanFunction
--- This class is an abstract class from which specific implementatios can inhert from.
BooleanFunction = {}
BooleanFunction.__index = BooleanFunction

function BooleanFunction:new(name)
  local cond = {name = name}
  setmetatable(cond, self)
  self.__index = self
  return cond
end

function BooleanFunction.__unm(cond)
  return Negation:new(cond)
end

function BooleanFunction.__add(A, B)
  return Disjunction:new(A, B)
end

function BooleanFunction.__mul(A, B)
  if getmetatable(A) == Disjunction or getmetatable(B) == Disjunction then
    return Disjunction.__mul(A, B)
  end
  return Conjunction:new(A, B)
end

--- @class Variable
Variable = subclass(BooleanFunction)
Variable.count = 0

function Variable:new(value)
  local var = {value = value, id=self.count}
  self.count = self.count + 1
  setmetatable(var, self)
  self.__index = self
  return var
end

function BooleanFunction:__tostring()
  return 'x' .. self.id
end

function BooleanFunction:eval()
  return self.value
end

--- @class Negation
--- This class implements the negation of a BooleanFunction `C` such that it evaluates to `not C:eval()`
Negation = subclass(BooleanFunction)

function Negation:new(bf)
  local neg = {bf = bf}
  setmetatable(neg, self)
  self.__index = self
  return neg
end

function Negation:eval(x)
  return not self.bf:eval(x)
end

function Negation.__unm(neg)
  return neg.bf
end

function Negation:__tostring()
  return "¬" .. self.bf:__tostring()
end

--- @class Conjunction
--- This class implements the conjunction of two truth functions `A` and `B` such that it evaluates to `A:eval() and B:eval()`
Conjunction = subclass(BooleanFunction)

function Conjunction:new(A, B)
  local conj = {A = A, B = B}
  setmetatable(conj, self)
  self.__index = self
  return conj
end

function Conjunction:eval(x)
  return self.A:eval(x) and self.B:eval(x)
end

function Conjunction.__unm(conj)
  return -conj.A + -conj.B
end

function Conjunction:__tostring()
  local stringA = self.A:__tostring()
  local stringB = self.B:__tostring()
  if getmetatable(self.A) == Disjunction then
    stringA = '(' .. stringA .. ')'
  end
  if getmetatable(self.B) == Disjunction then
    stringB = '(' .. stringB .. ')'
  end
  return stringA .. ' ∧ ' .. stringB
end

--- @class Disjunction
--- This class implements the disjunction of two truth functions `A` and `B` such that it evaluates to `A:eval() or B:eval()`
Disjunction = subclass(BooleanFunction)

function Disjunction:new(A, B)
  local disj = {A = A, B = B}
  setmetatable(disj, self)
  self.__index = self
  return disj
end

function Disjunction.__unm(disj)
  return -disj.A * -disj.B
end

function Disjunction:eval(x)
  return self.A:eval(x) or self.B:eval(x)
end

function Disjunction.__mul(A, B)
  if getmetatable(A) == getmetatable(B) then
    return (A.A * B.A) + (A.A * B.B) + (A.B * B.A) + (A.B * B.B)
  end
  if getmetatable(A) == Disjunction then
    return (A.A * B) + (A.B * B)
  end
   if getmetatable(B) == Disjunction then
    return (B.A * A) + (B.B * A)
  end
  error("This should never happen")
end

function Disjunction:__tostring()
  local stringA = self.A:__tostring()
  local stringB = self.B:__tostring()
  if getmetatable(self.A) == Conjunction then
    stringA = '(' .. stringA .. ')'
  end
  if getmetatable(self.B) == Conjunction then
    stringB = '(' .. stringB .. ')'
  end
  return stringA .. ' ∨ ' .. stringB
end

-- PREDICATES: are truth functions specific to our data
--- @class Predicate is an atomic condition
Predicate = subclass(BooleanFunction)
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
  return x[self.tag] ~= nil and self.predicate(self.sanitizer(x[self.tag]))
end

EqualsPredicate = subclass(TagPredicate)

function EqualsPredicate:new(tag, val, sanitizer)
  local ePred = TagPredicate:new(tag, sanitizer)
  ePred.predicate = function(x) return x == val end
  setmetatable(ePred, self)
  self.__index = self
  return ePred
end

ContainsPredicate = subclass(TagPredicate)

function ContainsPredicate:new(tag, val, sanitizer)
  local cPred = TagPredicate:new(tag, sanitizer)
  cPred.predicate = function(x) return string.find(x, val, 1, true) ~= nil end
  setmetatable(cPred, self)
  self.__index = self
  return cPred
end

PrefixPredicate = subclass(TagPredicate)

function PrefixPredicate:new(tag, prefix, sanitzer)
  local pPred = TagPredicate:new(tag, sanitzer)
  pPred.predicate = function(x) return string.find(x, prefix, 1, true) == 1 end
  setmetatable(pPred, self)
  self.__index = self
  return pPred
end

OneOfPredicate = subclass(TagPredicate)

function OneOfPredicate:new(tag, values, sanitzer)
  local ooPred = TagPredicate:new(tag, sanitzer)
  ooPred.predicate = function(x) return Set(values)[x] end
  setmetatable(ooPred, self)
  self.__index = self
  return ooPred
end
