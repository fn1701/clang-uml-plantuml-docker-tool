# clang-uml-plantuml-docker-tool

A container image bundling [clang-uml](https://github.com/bkryza/clang-uml),
[PlantUML](https://plantuml.com/), and Graphviz, for generating UML class,
sequence, and package diagrams from C++ source and rendering them straight
to SVG, PNG, or JPG.

## Purpose

clang-uml reads a project's `compile_commands.json` and a `.clang-uml` YAML
config and emits PlantUML/Mermaid diagram sources. This image adds the
rendering step (PlantUML + Graphviz's `dot`) on top, so one container call
produces ready-to-view images without installing a JVM, PlantUML, or
clang-uml (and its PPA) in every consuming project's own CI or dev
environment.

Meant to be reused across multiple C++ projects — it has no project-specific
configuration baked in. Each consuming project supplies its own
`.clang-uml` file.

## Usage

From a C++ project with a CMake-generated `compile_commands.json` and a
`.clang-uml` config at its root:

```sh
docker run --rm --network=none \
  -v "$PWD:/workspace" \
  ghcr.io/fn1701/clang-uml-plantuml-docker-tool:latest \
  --format svg,png
```

- `--format` accepts a comma-separated list of `svg`, `png`, `jpg` (default: `svg`).
- Any other arguments are passed through to `clang-uml` itself (e.g. `-c path/to/config.yml`).
- Output lands wherever `.clang-uml`'s `output_directory` points, as `.puml`
  sources plus one rendered image per format per diagram.

`--network=none` is recommended: diagram generation only needs to read your
source tree and write output, so there's no legitimate reason for the
container to reach the network at run time.

### Example (GitHub Actions)

```yaml
- name: Configure (compile_commands.json only)
  run: cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON .

- name: Generate diagrams
  run: |
    docker run --rm --network=none \
      -v "$PWD:/workspace" \
      ghcr.io/fn1701/clang-uml-plantuml-docker-tool:latest \
      --format svg
```

## Versioning

Image tags follow the bundled clang-uml version. Base image, clang-uml, and
PlantUML versions are tracked by Renovate (see `renovate.json`) and bumped
automatically via PR.
