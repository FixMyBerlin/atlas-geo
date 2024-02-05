package.path = package.path .. ";/geo/process/helper/?.lua"
package.path = package.path .. ";/geo/process/shared/?.lua"
package.path = package.path .. ";/geo/process/roads_bikelanes/surfaceQuality/?.lua"
require("TimeUtils")
require("DeriveSurface")
require("DeriveSmoothness")
require("Set")
require("CopyTags")

function SurfaceQuality(object)
  -- Same as roadClassification, except for `HighwayClasses`

  local tags = object.tags

  local surface_data = {}

  MergeTable(surface_data, DeriveSurface(tags))
  MergeTable(surface_data, DeriveSmoothness(tags))

  -- all tags that are shown on the application
  local tags_cc = {
    "name",
    "highway",
    "surface",
    "smoothness",
  }
  CopyTags(surface_data, tags, tags_cc, "osm_")

  -- 77,000+ https://taginfo.openstreetmap.org/keys/check_date%3Asurface
  if tags["check_date:surface"] then
    surface_data.surface_age = AgeInDays(ParseDate(tags["check_date:surface"]))
  end
  -- 4,000+ https://taginfo.openstreetmap.org/keys/check_date%3Asmoothness
  if tags["check_date:smoothness"] then
    surface_data.smoothness_age = AgeInDays(ParseDate(tags["check_date:smoothness"]))
  end


  return surface_data
end