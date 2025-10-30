# Opengrep Custom Container Image

This repository provides a simple workflow for fetching the Opengrep binary (see [Opengrep repository](https://github.com/opengrep/opengrep)) and rule sets (see [Opengrep Rules](https://github.com/opengrep/opengrep-rules)) to build a custom Docker image for scanning your codebase.

- Wraps the Opengrep static code analysis engine in a Docker image, making it easy to integrate into CI/CD pipelines or local scans.
- Prepares artifacts (binary + rules) so you have full control of versions.

## Prerequisites
- Docker installed and running on your system.
- Internet access to download the Opengrep binary and clone the rules repository.

## Folder Structure
```
├── Dockerfile                
├── fetch_artifacts.sh        # Script to download the OpenGrep binary and rule set
├── scripts/import_scan.sh    # Defect Dojo scan import helper script
├── artifacts/                # Directory created by fetch_artifacts.sh
│   ├── Opengrep/
│   │   └── <version>/        
│   │       └── opengrep      # Downloaded OpenGrep binary
│   └── rules/                # Cloned OpenGrep rule set repository
└── example-code/             # Example code for test scanning
```


## Usage
### 1. Fetch Opengrep Artifacts
Run the fetch script which downloads the latest Opengrep binary and clones the rules repository:

```bash
./fetch_artifacts.sh
```

You may optionally specify a version:

```bash
./fetch_artifacts.sh <version>
```

This will:  
- Download the Opengrep binary into `artifacts/Opengrep/<version>/opengrep`  
- Clone the rules repository into `artifacts/rules/`, keeping only the rule directories  

### 2. Build the Docker Image  
Once artifacts are prepared, build the Docker image:

```bash
docker build -t opengrep-container:latest \
  --build-arg OPENGREP_VERSION=<version> .
```

Replace `<version>` with the version printed by the fetch script.

### 3. Run a Scan  
To scan your project directory using the built image:

```bash
docker run --rm -v $(pwd):/workspace opengrep-container:latest \
scan /workspace -f /rules --config auto
```

- `/workspace` maps your local project directory into the container  
- `/rules` points to the rules directory inside the container  

Example: scan using python rule set on  `example-code` folder:

```bash
docker run --rm -v $(pwd):/workspace opengrep-container:latest \
scan /workspace/example-code -f /rules/python --config auto
```

Example: scan using python rule set on  `example-code` folder with json output report:

```bash
docker run --rm -v $(pwd):/workspace opengrep-container:latest \
scan /workspace/example-code -f /rules/python --config auto --json > python-scan-results.json
```

![scan](https://github.com/user-attachments/assets/4838f87e-88e1-45dc-b870-9b98d8320c17)

## Defect Dojo Import Scans
To import Opengrep scans into Defect Dojo you can utilized the `scripts/import_scan.sh` script. 

1. Export Defect Dojo API token:
```bash
export DEFECT_DOJO_API_TOKEN="<defect-dojo-api-token>"
```

1. Run the import_scan.sh script
```bash
./scripts/import_scan.sh --host https://<defect-dojo-hostname> --product-name "<product-name>" \
--engagement-name "<engagment-name>" --report <path-to-scan-results>.json
```
This will
- Upload Opengrep grep json formatted scan results into Defect Dojo.
- Assumes that the product name exists in Defect Dojo.
- Loads results into exsiting engagment or creates the engagment if it is not found.

## Links & Resources  
- [Opengrep project on GitHub](https://github.com/opengrep/opengrep)  
- [Opengrep Rules repository on GitHub](https://github.com/opengrep/opengrep-rules)  
- [Opengrep official website](https://opengrep.dev)  
