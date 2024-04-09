---@param object_tags table
---@param result_tags table
---@param transformed_processed_cycleways table
---@return { minzoom: boolean|nil }
--- Return the minzoom and maxzoom for roads
function BikelaneMinzoom(object_tags, result_tags, transformed_processed_cycleways)
  local minzoom = nil

  -- First check if this is the result_tags._side == "right", by convention we only to this for the right side
  -- From transformed_processed_cycleways, get the other sides than our current result_tags.side
  -- Then check if this side.category is the same as our current result_tags.category
  -- If so, set the minzoom for the right side to zoom 9

  return { minzoom = minzoom }
end
