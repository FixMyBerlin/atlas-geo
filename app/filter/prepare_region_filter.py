import os
import json
from shapely.geometry import shape, MultiPolygon
from shapely.ops import cascaded_union


def process_geojson_file(file_path):
    with open(file_path) as file:
        data = json.load(file)

    features = data['features']
    return features


def perform_union(input_dir, output_file):
    # Create an empty list to hold the polygons
    polygons = []

    # Process each .geojson file in the input directory
    for file_name in os.listdir(input_dir):
        if file_name.endswith('.geojson'):
            file_path = os.path.join(input_dir, file_name)
            features = process_geojson_file(file_path)
            for feature in features:
                polygon = shape(feature['geometry'])
                polygons.append(polygon)

    # Perform the geometric union
    union_polygon = cascaded_union(polygons)

    # Convert the union result to GeoJSON format
    multipolygon = MultiPolygon([union_polygon])
    union_geojson = json.dumps(multipolygon.__geo_interface__)

    # Write the multipolygon to the output file
    with open(output_file, 'w') as outfile:
        outfile.write(union_geojson)


if __name__ == "__main__":
    input_dir = "./regions"
    output_file = "./regions_merged.geojson"

    perform_union(input_dir, output_file)
