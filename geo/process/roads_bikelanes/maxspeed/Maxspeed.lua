package.path = package.path .. ";/geo/process/helper/?.lua"
package.path = package.path .. ";/geo/process/shared/?.lua"
package.path = package.path .. ";/geo/process/roads_bikelanes/maxspeed/?.lua"
require("TimeUtils")
require("MaxspeedDirect")
require("MaxspeedFromZone")
require("CopyTags")
require("Set")

function Maxspeed(object)
  local tags = object.tags

  local maxspeed_data = {}

  -- Try to find maxspeed information in the following order:
  -- 1. `maxspeed` tag
  -- 2. maxspeed zones tags
  -- 3. highway type
  -- 4. SQL: intersecting landuse
  local maxspeed, source, confidence = MaxspeedDirect(tags)

  if maxspeed == nil then
    maxspeed, source, confidence = MaxspeedFromZone(tags)
  end

  if maxspeed == nil then
    local highway_speeds = {
      ["living_street"] = 7
    }
    if highway_speeds[tags.highway] then
      maxspeed = highway_speeds[tags.highway]
      source = "inferred_from_highway"
      confidence = 'high' -- living_street is 'high', others would be 'medium
    end
  end

  -- all tags that are shown on the application
  local tags_cc = {
    "maxspeed",
    "maxspeed:backward",
    "maxspeed:forward",
    "maxspeed:conditional",
    "maxspeed:type",
    "zone:maxspeed",
    "source:maxspeed",
  }

  CopyTags(maxspeed_data, tags, tags_cc, "osm_")

  -- Freshness of data (AFTER `FilterTags`!)
  -- 700+ https://taginfo.openstreetmap.org/keys/check_date%3Amaxspeed
  if tags["check_date:maxspeed"] then
    maxspeed_data.maxspeed_age = AgeInDays(ParseDate(tags["check_date:maxspeed"]))
  end

  maxspeed_data.maxspeed = maxspeed
  maxspeed_data.maxspeed_source = source
  maxspeed_data.maxspeed_confidence = confidence

  if maxspeed ~= nil then
    return maxspeed_data
  end
  return {}
end