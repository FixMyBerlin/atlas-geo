  -- SQL:
  -- für alle linien die kein maxpseed haben (auch nicht über die source-tags)
  --  wir nehmen die landuse=residential+industrial+commerical+retail
  --  buffer von ~10m um die fläche
  --  dann alle linien die (TODO) vollständig / am meisten / … in der fläche fläche sind
  --  (tendentizell dafür nicht schneiden, weil wir am liebsten die OSM ways so haben wie in OSM)
  --  und dann können wir in sql "maxspeed" "maxspeed_source='infereed from landuse'"
  --  UND dann auch einen "_todo="add 'maxspeed:source=DE:urban' to way"
  -- hinweis: außerstädtisch extrapolieren wir aber keine daten, da zu wenig "richtig"

-- TODO add other landuse than residential

-- create one unified geometry from 'landuse' which is then used in the geometric intersection
create table filterTable as
select st_union(st_expand(geom, 10)) as "buffer" from landuse where tags->>'landuse' = 'residential';

-- delete all objects that don't intersect the geometry of 'filterTable'
delete from "_maxspeed_missing" where osm_id not in (select maxspeed.osm_id from "_maxspeed_missing" as maxspeed, filterTable where st_intersects("buffer", "geom"));
drop table filterTable;

-- set the guessed values
alter table "_maxspeed_missing" add "maxspeed" int default 50;
alter table "_maxspeed_missing" add "present" bool default false;
update "_maxspeed_missing" set tags = jsonb_set(tags, '{_maxspeed_source}','"infereed from landuse"');

-- insert into main maxspeed table
insert into "maxspeed" select osm_type, osm_id, tags, meta, maxspeed, present, geom from "_maxspeed_missing";



-- TODO copy to maxspeed main table


