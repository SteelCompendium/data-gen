extract_to_metadata abilities_json_fpath metadata_json_fpath:
    #!/usr/bin/env python3
    import json

    # Load abilities JSON
    with open("{{abilities_json_fpath}}", "r") as f:
            data = json.load(f)

    with open("{{metadata_json_fpath}}", "r") as f:
        metadata = json.load(f)

    for ability in data.get("abilities", []):
        if "cost" in ability and ability["cost"] in ["Signature", "Free Strike"]:
            for scc in ability["metadata"].get("scc", []):
                if scc not in metadata:
                    metadata[scc] = {}
                metadata[scc]["ability_type"] = ability["cost"]

    print(json.dumps(metadata))

# just extract_to_metadata ../../../features.json ../../input/heroes/
[no-cd]
extract_features_to_metadata features_json_fpath metadata_json_fpath:
    #!/usr/bin/env python3
    import json

    # Load features JSON
    with open("{{features_json_fpath}}", "r") as f:
            data = json.load(f)

    with open("{{metadata_json_fpath}}", "r") as f:
        metadata = json.load(f)

    for feature in data.get("features", []):
        if "metadata" in feature and "subclass" in feature["metadata"]:
            for scc in feature["metadata"].get("scc", []):
                if scc not in metadata:
                    metadata[scc] = {}
                metadata[scc]["subclass"] = feature["metadata"]["subclass"]

    print(json.dumps(metadata))