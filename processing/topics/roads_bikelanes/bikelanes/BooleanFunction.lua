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

function BooleanFunction:__unm()
  return Negation:new(self)
end

function BooleanFunction.__add(X, Y)
  if getmetatable(Y) == Disjunction then
    return Disjunction.__add(Y, X)
  end
  return Disjunction:new({X, Y})
end

function BooleanFunction.__mul(X, Y)
  if getmetatable(Y) == Disjunction then
    return Disjunction.__mul(Y, X)
  end
  if getmetatable(Y) == Conjunction then
    return Conjunction.__mul(Y, X)
  end
  return Conjunction:new({X, Y})
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

function Variable:__tostring()
  return 'x' .. self.id
end

function Variable:__call()
  return self.value
end

--- @class Negation
--- This class implements the negation of a BooleanFunction `C` such that it evaluates to `not C`
Negation = subclass(BooleanFunction)

function Negation:new(variable)
  local neg = {variable = variable}
  setmetatable(neg, self)
  self.__index = self
  return neg
end

function Negation:__call(x)
  return not self.variable(x)
end

function Negation:__unm()
  return self.variable
end

function Negation:__tostring()
  return "¬" .. self.variable:__tostring()
end

--- @class Conjunction
--- This class implements the conjunction of two truth functions `X` and `Y` such that it evaluates to `X and Y`
Conjunction = subclass(BooleanFunction)

function Conjunction:new(conj)
  setmetatable(conj, self)
  self.__index = self
  return conj
end

function Conjunction:__call(x)
  for _, term in ipairs(self) do
    if not term(x) then return false end
  end
  return true
end

function Conjunction:__unm()
  local disj = {}
  for _, term in ipairs(self) do
    table.insert(disj, -term)
  end
  return Disjunction:new(disj)
end

function Conjunction.__mul(X, Y)
  if getmetatable(Y) == Conjunction then
    for _, term in Y do
      table.insert(X, term)
    end
  else
    table.insert(X, Y)
  end
  return X
end

function Conjunction:__tostring()
  local result = {}
  for _, term in ipairs(self) do
    local stringified = term:__tostring()
    if getmetatable(term) == Disjunction then
      stringified = '(' .. stringified .. ')'
    end
    table.insert(result, stringified)
  end
  return table.concat(result, ' ∧ ')
end

--- @class Disjunction
--- This class implements the disjunction of two truth functions `X` and `Y` such that it evaluates to `X or Y`
Disjunction = subclass(BooleanFunction)

function Disjunction:new(disj)
  setmetatable(disj, self)
  self.__index = self
  return disj
end

function Disjunction:__unm()
  local conj = {}
  for _, term in ipairs(self) do
    table.insert(conj, -term)
  end
  return Conjunction:new(conj)
end

function Disjunction:__call(x)
  for _, term in ipairs(self) do
    if term(x) then return true end
  end
  return false
end

function Disjunction.__add(X, Y)
  if getmetatable(Y) == Disjunction then
    for _, term in Y do
      table.insert(X, term)
    end
  else
    table.insert(X, Y)
  end
  return X
end

function Disjunction.__mul(X, Y)
  local disj = {}
  for _, subtermX in ipairs(X) do
    if getmetatable(Y) == Disjunction then
      for _, subtermY in ipairs(Y) do
        table.insert(disj, subtermX * subtermY)
      end
    else
      table.insert(disj, subtermX * Y)
    end
  end
  return Disjunction:new(disj)
end

function Disjunction:__tostring()
  local result = {}
  for _, term in ipairs(self) do
    local stringified = term:__tostring()
    if getmetatable(term) == Conjunction then
      stringified = '(' .. stringified .. ')'
    end
    table.insert(result, stringified)
  end
  return table.concat(result, ' ∨ ')
end


--- @class TagPredicate is a Predicate evaluated on `tag`
TagPredicate = subclass(BooleanFunction)

function TagPredicate:new(tag, sanitizer)
  local tPred = {
    tag = tag,
    sanitizer = sanitizer or function (x) return x end
  }
  setmetatable(tPred, self)
  self.__index = self
  return tPred
end

function TagPredicate:__call(x)
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
