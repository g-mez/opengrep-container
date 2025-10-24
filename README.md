# Opengrep Air-Gapped Docker Setup

This repository provides a simple workflow for fetching Opengrep binaries and rules to build a custom Opengrep container image.

## Folder Structure

```
artifacts/
├── Opengrep/
│   └── <version>/       # Downloaded Opengrep binary
│       └── Opengrep
└── rules/               # Cloned and cleaned Opengrep rules
```

## Usage

### 1. Fetch Opengrep Artifacts

Run the script to download the latest Opengrep binary and clone the rules repository:
```bash
./fetch_artifacts.sh
```
![fetch](https://github.com/user-attachments/assets/30122c90-d99d-4af0-9c33-c9c2caca0709)

This will:

* Download the Opengrep binary to `artifacts/Opengrep/<version>/Opengrep`
* Clone and clean the rules repository into `artifacts/rules/`, keeping only the rule directories

### 2. Build Docker Image

Once the artifacts are prepared, build the air-gapped Docker image:

```bash
docker build -t Opengrep-airgap:latest \
  --build-arg Opengrep_VERSION=<version> .
```

Replace `<version>` with the version printed by the fetch script.
![build](https://github.com/user-attachments/assets/337bdabf-e2db-4291-8dc1-cab59bf52400)

### 3. Run a Scan

To run a scan using the Opengrep Docker image:

```bash
docker run --rm -v $(pwd):/workspace opengrep-airgap:latest scan /workspace -f /rules --config auto
```

* `/workspace` maps your local project directory into the container.
* `/rules` points to the rules directory inside the container.

### 4. Example Using Example Pythone Rules and Example Code

```bash
docker run --rm -v $(pwd):/workspace opengrep-airgap:latest scan /workspace/example-code -f /rules/python --config auto
```
![scan](https://github.com/user-attachments/assets/691fe56b-28c1-4ef3-9ac8-eee3313ea1b8)

This will apply only the Python-specific rules to your code.

## Notes

* Ensure Docker is installed and running before building or running the container.
* The fetch script can optionally accept a version argument:

```bash
./fetch_artifacts.sh <version>
```

This will download and use the specified version instead of the latest.
