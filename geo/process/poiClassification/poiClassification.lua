package.path = package.path ..
    ";/geo/process/helper/?.lua;/geo/process/shared/?.lua;/geo/process/poiClassification/?.lua"
require("Set")
require("ExtractKeys")
require("FilterTags")
require("InferAddress")
require("MergeArray")
require("Metadata")

-- Shared:
require("ShoppingAllowedListWithCategories")

-- We look at shop=* and amenity=<allowed_values>. We also `category`ze each into one of 4 categories for filtering.
local table = osm2pgsql.define_table({
  name = 'poiClassification',
  ids = { type = 'any', id_column = 'osm_id', type_column = 'osm_type' },
  columns = {
    { column = 'tags', type = 'jsonb' },
    { column = 'meta', type = 'jsonb' },
    { column = 'geom', type = 'point' },
  }
})

-- * @desc Guards extracted to be used inside osm2pgsql.process_*
-- * @returns `true` whenever we want to exit processing the given data
local function ExitProcessing(object)
  if not (object.tags.amenity or object.tags.shop or object.tags.tourism or object.tags.leisure) then
    return true
  end

  -- Ignore all which are explicity restricted
  if object.tags.access == "private" then
    return true
  end

  -- We allow all shop=* but heavily filter amenity, tourism, leisure
  local allowed_values = Set(ExtractKeys(ShoppingAllowedListWithCategories))
  if object.tags.shop
      or allowed_values[object.tags.amenity]
      or allowed_values[object.tags.tourism]
      or allowed_values[object.tags.leisure]
  then
    -- Special case: For https://wiki.openstreetmap.org/wiki/Tag:tourism=information
    -- only allow some values
    if object.tags.tourism == "information" then
      if object.tags.information == 'office' or object.tags.information == 'visitor_centre' then
        return false
      end
      return true
    end

    return false
  end

  return true
end

-- Tag processing extracted to be used inside projcess_*
local function processTags(tags)
  -- Set our custom `category` value with one of our 4 values.
  -- We also introduce `type` as a unified way to speicify the shop-or-amenity type.
  if tags.shop then
    tags.category = 'Einkauf'
    tags.type = "shop-" .. tags.shop
  end
  if tags.amenity then
    tags.category = ShoppingAllowedListWithCategories[tags.amenity]
    tags.type = "amenity-" .. tags.amenity
  end
  if tags.tourism then
    tags.category = ShoppingAllowedListWithCategories[tags.tourism]
    tags.type = "tourism-" .. tags.tourism
  end
  if tags.leisure then
    tags.category = ShoppingAllowedListWithCategories[tags.leisure]
    tags.type = "leisure-" .. tags.leisure
  end

  -- This part was previously a separate dataset "education"
  local formalEducation = Set({
    "childcare",
    "college",
    "kindergarten",
    "research_institute",
    "school",
    "university"
  })
  if formalEducation[tags.amenity] then
    tags.formalEducation = tags.amenity
  end

  InferAddress(tags, tags)
  local allowed_tags = MergeArray({ "name", "category", "type", "formalEducation" }, AddressKeys)
  FilterTags(tags, Set(allowed_tags))
end

function osm2pgsql.process_node(object)
  if ExitProcessing(object) then return end

  processTags(object.tags)

  table:insert({
    tags = object.tags,
    meta = Metadata(object),
    geom = object:as_point()
  })
end

function osm2pgsql.process_way(object)
  if ExitProcessing(object) then return end
  if not object.is_closed then return end

  processTags(object.tags)

  table:insert({
    tags = object.tags,
    meta = Metadata(object),
    geom = object:as_polygon():centroid()
  })
end

function osm2pgsql.process_relation(object)
  if ExitProcessing(object) then return end
  if not object.tags.type == 'multipolygon' then return end

  processTags(object.tags)

  table:insert({
    tags = object.tags,
    meta = Metadata(object),
    geom = object:as_multipolygon():centroid()
  })
end