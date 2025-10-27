# Opengrep Custom Container Image

This repository provides a simple workflow for fetching the Opengrep binary (see [Opengrep repository](https://github.com/opengrep/opengrep)) and rule sets (see [Opengrep Rules](https://github.com/opengrep/opengrep-rules)) to build a custom Docker image for scanning your codebase.

- Wraps the Opengrep static code analysis engine in a Docker image, making it easy to integrate into CI/CD pipelines or local scans.
- Prepares artifacts (binary + rules) so you have full control of versions.

## Prerequisites
- Docker installed and running on your system.
- Internet access to download the Opengrep binary and clone the rules repository.

## Folder Structure
```
artifacts/
├── Opengrep/
│   └── <version>/        # Downloaded by the fetch artifacts script (Opengrep binary)
│       └── opengrep
└── rules/                # Cloned by the fetch artifacts script (Opengrep rule set)
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
docker run --rm -v $(pwd):/workspace opengrep-container:latest scan /workspace -f /rules --config auto
```

- `/workspace` maps your local project directory into the container  
- `/rules` points to the rules directory inside the container  

For example, to scan only Python code in the `example-code` folder:

```bash
docker run --rm -v $(pwd):/workspace opengrep-container:latest scan /workspace/example-code -f /rules/python --config auto
```

## Links & Resources  
- [Opengrep project on GitHub](https://github.com/opengrep/opengrep)  
- [Opengrep Rules repository on GitHub](https://github.com/opengrep/opengrep-rules)  
- [Opengrep official website](https://opengrep.dev)  