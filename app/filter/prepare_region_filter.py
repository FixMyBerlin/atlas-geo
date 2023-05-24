import os
import json
from turfpy.transformation import combine
from turfpy.helpers import feature_collection


def process_geojson_file(file_path):
    with open(file_path) as file:
        data = json.load(file)

    features = data['features']
    return features


def perform_union(input_dir, output_file):
    # Create an empty FeatureCollection to hold the polygons
    fc = []

    # Process each .geojson file in the input directory
    for file_name in os.listdir(input_dir):
        if file_name.endswith('.geojson'):
            file_path = os.path.join(input_dir, file_name)
            features = process_geojson_file(file_path)
            fc.extend(features)

    # Perform the geometric union
    merged = combine(feature_collection(fc))

    # Write the multipolygon to the output file
    with open(output_file, 'w') as outfile:
        json.dump(merged, outfile)


if __name__ == "__main__":
    input_dir = "./regions"
    output_file = "./regions_merged.geojson"

    perform_union(input_dir, output_file)
