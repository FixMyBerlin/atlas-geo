-- unnest all tags from ["prefix .. side:subtag"]=val -> ["subtag"]=val
local function unnestTags(tags, prefix, side, dest)
  dest = dest or {}
  dest.parent = tags
  local fullPrefix = prefix .. side
  local prefixLen = string.len(fullPrefix)
  for key, val in pairs(tags) do
    if osm2pgsql.has_prefix(key, fullPrefix) then
      if key == fullPrefix then -- self projection
        dest[prefix] = val
        dest.side = side
      else
        -- offset of 2 due to 1-indexing and for removing the ':'
        local prefixlessKey = string.sub(key, prefixLen + 2)
        local infix = string.match(prefixlessKey, '[^:]*')
        if side ~= '' or not Set({ 'left', 'right', 'both' })[infix] then
          -- avoid projecting sided tags in the implicit case
          dest[prefixlessKey] = val
          dest.side = side
        end
      end
    end
  end
  return dest
end

LEFT_SIGN = 1
CENTER_SIGN = 0
RIGHT_SIGN = -1
-- returns a list of all transformed objects created with the given `transformations` from `tags`
local sideSignMap = {
  [":left"] = LEFT_SIGN,
  [":right"] = RIGHT_SIGN
}
-- https://wiki.openstreetmap.org/wiki/Forward_%26_backward,_left_%26_right
local sideDirectionMap = {
  [":left"] = 'backward',
  [":right"] = 'forward',
}

-- these tags get transformed from the forward backward schema
local directedTags = { 'cycleway:lanes', 'bicycle:lanes', 'traffic_sign' }
function GetTransformedObjects(tags, transformations)
  local center = { sign = 0 }
  for k, v in pairs(tags) do center[k] = v end
  local results = { center }
  if PathClasses[tags.highway] then
    return results
  end
  for _, transformation in pairs(transformations) do
    for side, sign in pairs(sideSignMap) do
      if tags.highway ~= transformation.highway then
        local prefix = transformation.prefix
        local newObj = {
          _parent_highway = tags.highway,
          highway = transformation.highway,
          name = tags.name,
          prefix = prefix,
          sign = sign
        }
        -- we look for tags with the following hirachy: `prefix` < `prefix:both` < `prefix:side`
        -- thus a more specific tag will always overwrite a more general one
        unnestTags(tags, prefix, '', newObj)
        unnestTags(tags, prefix, ':both', newObj)
        unnestTags(tags, prefix, side, newObj)
        if newObj.side ~= nil then
          if not transformation.filter or transformation.filter(newObj) then
            table.insert(results, newObj)
          end
        end
        for _, key in pairs(directedTags) do
          local directedKey = key .. ':' .. sideDirectionMap[side]
          newObj[key] = tags[key] or tags[directedKey]
        end
      end
    end
  end
  return results
end
