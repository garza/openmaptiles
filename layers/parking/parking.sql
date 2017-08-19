CREATE OR REPLACE FUNCTION layer_parking(bbox geometry, zoom_level int)
RETURNS TABLE(geometry geometry, osm_id bigint,
  amenity text, name text, parking text) AS $$
    SELECT geometry, osm_id,
      COALESCE(NULLIF(amenity, '')) AS amenity,
      COALESCE(NULLIF(name, '')) AS name,
      COALESCE(NULLIF(parking, '')) AS parking
    FROM (
        -- etldoc: osm_building_polygon_gen1 -> layer_building:z13
        SELECT osm_id, geometry, amenity, name, parking, NULL::int as scalerank
        FROM osm_parking_polygon
        WHERE zoom_level >= 6
    ) AS zoom_levels
    WHERE geometry && bbox;
$$ LANGUAGE SQL IMMUTABLE;
