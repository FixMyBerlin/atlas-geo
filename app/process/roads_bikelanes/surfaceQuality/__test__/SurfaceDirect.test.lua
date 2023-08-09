package.path = package.path .. ";./app/process/roads/surfaceQuality/?.lua"
require('SurfaceDirect')

print('=== Test SurfaceDirect: correct source, confidence for tag ===')
local value, source, confidence = SurfaceDirect("asphalt")
assert(value == "asphalt")
assert(source == "tag")
assert(confidence == "high")

print('=== Test SurfaceDirect: correct source, confidence for nil ===')
local value, source, confidence = SurfaceDirect(nil)
assert(value == nil)
assert(source == nil)
assert(confidence == nil)