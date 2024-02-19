package.path = package.path .. ";/app/process/helper/?.lua"
package.path = package.path .. ";/app/process/shared/?.lua"
package.path = package.path .. ";/app/process/roads_bikelanes/bikelanes/?.lua"
require("Set")
require("HighwayClasses")
require("TimeUtils")
require("categories")
require("transformations")
require("CopyTags")
require("RoadWidth")
require("ToMarkdownList")
require("DeriveSurface")
require("DeriveSmoothness")
require("BikelanesTodos")
require("Sanitize")
require("InferOneway")

local tags_copied = {
  "mapillary",
  "description",
}
local tags_prefixed = {
  'surface:colour',
  'traffic_sign',
  'traffic_sign:forward',
  'traffic_sign:backward',
  'separation',
  'separation:left',
  'separation:right',
  'traffic_mode',
  'traffic_mode:left',
  'traffic_mode:right',
}

function Bikelanes(object)
  local tags = object.tags

  -- transformations
  local footwayTransformation = {
    highway = "footway",
    prefix = "sidewalk",
    filter = function(tags)
      return not (tags.footway == 'no' or tags.footway == 'separate')
    end
  }
  -- cycleway transformer:
  local cyclewayTransformation = {
    highway = "cycleway",
    prefix = "cycleway",
  }
  local transformations = { cyclewayTransformation, footwayTransformation } -- order matters for presence

  -- generate cycleways from center line tagging, also includes the original object with `sign = 0`
  local transformedObjects = GetTransformedObjects(tags, transformations)
  local bikelanes = {}
  for i, cycleway in pairs(transformedObjects) do
    local sign = cycleway.sign
    local onlyPresent = CategorizeOnlyPresent(cycleway)
    if onlyPresent ~= nil then
      bikelanes[i] = { _infrastructureExists = false, category = onlyPresent, sign = sign }
    else
      local category = CategorizeBikelane(cycleway)
      if category ~= nil then
        local results = {
          _infrastructureExists = true,
          category = category,
          offset = sign * RoadWidth(tags) / 2, -- TODO: Should be `_offset`
        }

        -- Our data should be explicit about tagging that OSM considers default/implicit as well assumed defaults.
        results.oneway = Sanitize(cycleway.oneway, Set({'yes', 'no'})) or InferOneway(category)

        -- === Processing on the transformed dataset ===
        local freshTag = "check_date"
        if sign == CENTER_SIGN then
          results.sign = CENTER_SIGN
          results.width = ParseLength(tags.width)
        else
          MergeTable(results, cycleway)
          freshTag = "check_date:" .. cycleway.prefix
        end

        results.age = AgeInDays(ParseCheckDate(tags[freshTag]))

        MergeTable(results, DeriveSmoothness(cycleway))
        MergeTable(results, DeriveSurface(cycleway))
        CopyTags(results, tags, tags_copied)
        CopyTags(results, tags, tags_prefixed, 'osm_')
        -- cycleway._todos = ToMarkdownList(BikelanesTodos(cycleway))

        bikelanes[i] = results
      end
    end
  end

  return bikelanes
end
