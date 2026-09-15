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
  -v "$PWD:$PWD" -w "$PWD" \
  ghcr.io/fn1701/clang-uml-plantuml-docker-tool:latest \
  --format svg,png
```

- `--format` accepts a comma-separated list of `svg`, `png`, `jpg` (default: `svg`).
- Any other arguments are passed through to `clang-uml` itself (e.g. `-c path/to/config.yml`).
- Output lands wherever `.clang-uml`'s `output_directory` points, as `.puml`
  sources plus one rendered image per format per diagram.

Mount the project at the **same absolute path** inside the container as on
the host (`-v "$PWD:$PWD" -w "$PWD"`), not at an arbitrary path like
`/workspace`. `compile_commands.json` bakes in absolute host paths at
`cmake configure` time; if the container mounts the project elsewhere,
clang-uml's glob patterns won't match any translation unit and every
diagram fails with `no translation units found`.

If your project's headers pull in system libraries not present in the
image (e.g. Qt, yaml-cpp), bind-mount those include directories at their
original host paths too, so clang can resolve them without extra `-I`
flags:

```sh
docker run --rm --network=none \
  -v "$PWD:$PWD" -w "$PWD" \
  -v /usr/include/qt6:/usr/include/qt6:ro \
  -v /usr/include/yaml-cpp:/usr/include/yaml-cpp:ro \
  ghcr.io/fn1701/clang-uml-plantuml-docker-tool:latest \
  --format svg,png
```

Compiler-specific flags in `compile_commands.json` that Clang doesn't
recognize (e.g. GCC's `-mno-direct-extern-access`) can be stripped with
`clang-uml`'s own `--remove-compile-flag`, passed through after `--format`.

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
      -v "$PWD:$PWD" -w "$PWD" \
      ghcr.io/fn1701/clang-uml-plantuml-docker-tool:latest \
      --format svg
```

## Versioning

The base image and PlantUML version are pinned and tracked by Renovate (see
`renovate.json`), bumped automatically via PR. clang-uml is installed
unpinned from its [Launchpad PPA](https://launchpad.net/~bkryza/+archive/ubuntu/clang-uml) —
Renovate has no confirmed, reliable way to track versions from a
third-party PPA, so the image instead rebuilds automatically on the 1st of
each month to pick up whatever clang-uml release is current at that point
(see `.github/workflows/scheduled-rebuild.yml`).
