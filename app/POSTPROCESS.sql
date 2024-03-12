BEGIN;
DROP TABLE IF EXISTS bikelanes CASCADE;
ALTER TABLE _bikelanes_temp RENAME TO bikelanes;
COMMIT;

CREATE OR REPLACE
    FUNCTION public.roads_generalized(z integer, x integer, y integer)
    RETURNS bytea AS $$
DECLARE
  mvt bytea;
BEGIN
  SELECT INTO mvt ST_AsMVT(tile, 'roads_generalized', 4096, 'g') FROM (
    select
    *,
      ST_AsMVTGeom(
          geom,
          ST_TileEnvelope(z, x, y),
          4096, 64, true) AS g
    FROM roads
    WHERE (geom && ST_TileEnvelope(z, x, y)) and (not tags?'_minZoom' or z >= (tags->'_minZoom')::integer )
  ) as tile WHERE geom IS NOT NULL;
  RETURN mvt;
END
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

select * from roads where not tags?'_minZoom';
