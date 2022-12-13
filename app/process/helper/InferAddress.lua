-- Docs https://wiki.openstreetmap.org/wiki/Key:addr:*
-- * @return `dest` object
function InferAddress(tags, dest)
  dest = dest or {}
  dest.addr_street = tags.street or tags["addr:street"]
  dest.addr_zip = tags.postcode or tags["addr:postcode"]
  dest.addr_city = tags.city or tags["addr:city"]
  dest.addr_number = tags.housenumber or tags["addr:housenumber"]
  return dest
end

AddressKeys = { "addr_street", "addr_zip", "addr_city", "addr_number" }