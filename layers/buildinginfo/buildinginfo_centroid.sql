DROP TRIGGER IF EXISTS trigger_flag ON osm_buildinginfo_point;
DROP TRIGGER IF EXISTS trigger_refresh ON buildinginfo.updates;

-- etldoc: osm_building_point -> osm_building_point
CREATE OR REPLACE FUNCTION convert_buildinginfo_point() RETURNS VOID AS $$
BEGIN
  UPDATE osm_buildinginfo_point
  SET geometry =
           CASE WHEN ST_NPoints(ST_ConvexHull(geometry))=ST_NPoints(geometry)
           THEN ST_Centroid(geometry)
           ELSE ST_PointOnSurface(geometry)
    END
  WHERE ST_GeometryType(geometry) <> 'ST_Point';
END;
$$ LANGUAGE plpgsql;

SELECT convert_buildinginfo_point();

-- Handle updates

CREATE SCHEMA IF NOT EXISTS buildinginfo;

CREATE TABLE IF NOT EXISTS buildinginfo.updates(id serial primary key, t text, unique (t));
CREATE OR REPLACE FUNCTION buildinginfo.flag() RETURNS trigger AS $$
BEGIN
    INSERT INTO buildinginfo.updates(t) VALUES ('y')  ON CONFLICT(t) DO NOTHING;
    RETURN null;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION buildinginfo.refresh() RETURNS trigger AS
  $BODY$
  BEGIN
    RAISE LOG 'Refresh buildinginfo';
    PERFORM convert_buildinginfo_point();
    DELETE FROM buildinginfo.updates;
    RETURN null;
  END;
  $BODY$
language plpgsql;

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE ON osm_buildinginfo_point
    FOR EACH STATEMENT
    EXECUTE PROCEDURE buildinginfo.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT ON buildinginfo.updates
    INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE PROCEDURE buildinginfo.refresh();
