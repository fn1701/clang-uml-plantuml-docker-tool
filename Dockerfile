# syntax=docker/dockerfile:1.4
#
# clang-uml + PlantUML + Graphviz, bundled for generating C++ UML diagrams
# (class/sequence/package) as SVG, PNG, or JPG in CI or locally.
#
# renovate: datasource=docker depName=ubuntu
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    ca-certificates \
    curl \
    gnupg \
    graphviz \
    default-jre-headless \
    && add-apt-repository -y ppa:bkryza/clang-uml \
    && apt-get update \
    # renovate: datasource=deb depName=clang-uml
    && apt-get install -y --no-install-recommends clang-uml=0.6.3-0ubuntu1ppa1~noble \
    && apt-get purge -y software-properties-common gnupg \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# renovate: datasource=github-releases depName=plantuml/plantuml
ARG PLANTUML_VERSION=1.2026.7
RUN curl -fsSL -o /usr/local/bin/plantuml.jar \
    "https://github.com/plantuml/plantuml/releases/download/v${PLANTUML_VERSION}/plantuml-${PLANTUML_VERSION}.jar" \
    && printf '#!/bin/sh\nexec java -jar /usr/local/bin/plantuml.jar "$@"\n' > /usr/local/bin/plantuml \
    && chmod +x /usr/local/bin/plantuml

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /workspace
ENTRYPOINT ["entrypoint.sh"]
