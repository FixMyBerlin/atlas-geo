package.path = package.path .. ";/app/process/helper/?.lua"
package.path = package.path .. ";/app/process/shared/?.lua"
package.path = package.path .. ";/app/process/roads_bikelanes/bikelanes/?.lua"
require("transformations")
require("HighwayClasses")

function BikelanesPresence(object, cycleways)
  local tags = object.tags
  local presence = {}
  local sides = { LEFT_SIGN, CENTER_SIGN, RIGHT_SIGN }
  for _, cycleway in pairs(cycleways) do
    local sign = cycleway.sign
    presence[sign] = presence[sign] or cycleway.category
  end

  -- Filter ways where we dont expect bicycle infrastructure
  -- TODO: filter on surface and traffic zone and maxspeed (maybe wait for maxspeed PR)
  local infrastrucuteNotExpected = Set({ "residential", "road", "living_street" })
  if infrastrucuteNotExpected[tags.highway] or presence[CENTER_SIGN] then
    -- set the nil values to 'not_expected', for all minor roads and complete data
    for _, side in pairs(sides) do presence[side] = presence[side] or NOT_EXPECTED end
  end
  if (presence[RIGHT_SIGN] or presence[LEFT_SIGN]) then
    presence[CENTER_SIGN] = presence[CENTER_SIGN] or NOT_EXPECTED
  end
  if tags.oneway == 'yes' and tags['oneway:bicycle'] ~= 'no' then
    presence[LEFT_SIGN] = presence[LEFT_SIGN] or NOT_EXPECTED
  end

  -- replace all nil values with 'missing'
  for _, side in pairs(sides) do presence[side] = presence[side] or "missing" end


  local presence_data = {
    bikelane_left = presence[LEFT_SIGN],
    bikelane_self = presence[CENTER_SIGN],
    bikelane_right = presence[RIGHT_SIGN]
  }

  return presence_data
end