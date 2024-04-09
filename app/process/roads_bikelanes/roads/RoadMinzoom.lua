-- Hide those roads with road=*
local minzoom11RoadClasses = Set({
  'residential',
  'living_street',
  'bicycle_road',
  'pedestrian',
  'unclassified',
  'residential_priority_road',
  'unspecified_road',
  'service_road',
  'service_alley',
})

---@param object_tags table
---@param result_tags table
---@return { minzoom: boolean|nil }
--- Return the minzoom and maxzoom for roads
function RoadMinzoom(object_tags, result_tags)
  local minzoom = nil

  -- Handle **roadsPathClasses** table
  if PathClasses[object_tags.highway] then
    -- highway=path only from zoom 13 and below
    if object_tags.highway == "path" then
      minzoom = 13
    end
    -- highway=track and not trackgrade=grade1|grade2 only from zoom 11 and below
    if object_tags.highway == "trach"
        and not (object_tags.trackgrade == "grade2" or object_tags.trackgrade == "grade1")
    then
      minzoom = 11
    end
    return { minzoom = minzoom }
  end

  -- Handle **roads** table
  if minzoom11RoadClasses[result_tags.road] then
    minzoom = 11
  end

  return { minzoom = minzoom }
end
