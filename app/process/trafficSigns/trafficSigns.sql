-- SELECT avg(degrees(ST_Azimuth(st_pointn(geom, idx), st_pointn(geom, idx+1)))), node_id FROM "_trafficSignDirections" GROUP BY node_id;
-- SELECT *  FROM "trafficSigns" join orientations on "trafficSigns".osm_id = "orientations".node_id;