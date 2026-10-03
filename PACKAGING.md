# QTLtools packaging (conda + Docker)

Fork of [qtltools/qtltools](https://github.com/qtltools/qtltools) for reproducible conda/Docker builds used by [SiYangming/variant2qtl](https://github.com/SiYangming/variant2qtl). Official bioconda/biocontainers packages are **absent**.

| Field | Value |
| --- | --- |
| Package version | `1.3.1` |
| Upstream | [QTLtools 1.3.1 source](https://qtltools.github.io/qtltools/binaries/QTLtools_1.3.1_source.tar.gz) |
| Conda | `YangmingSi::qtltools=1.3.1` |
| Docker | `quay.io/bioinfortools/qtltools:1.3.1` |

**Version rule:** conda package version and Docker image tag are the **same string** (`1.3.1`).

## Contents

- `upstream/QTLtools_1.3.1_source.tar.gz` — official source tarball
- `upstream/SHA256SUMS` — checksum
- `recipe/` — conda-build / rattler-build recipe (linux-64 binary)
- `Dockerfile` — linux/amd64 image with `QTLtools`, `plink2`, `tabix`/`bgzip`

## License / attribution

Upstream is GPL-3.0. Cite:

> Delaneau O, et al. (2017) A complete tool set for molecular QTL discovery and analysis. *Nat Commun* 8:15452.

## Build (maintainers)

```bash
conda activate conda_build

# Docker (linux/amd64)
docker build --platform linux/amd64 -t quay.io/bioinfortools/qtltools:1.3.1 .
docker push quay.io/bioinfortools/qtltools:1.3.1

# After the image exists, export the QTLtools ELF for the conda recipe:
cid=$(docker create --platform linux/amd64 quay.io/bioinfortools/qtltools:1.3.1)
mkdir -p upstream/bin
docker cp "$cid":/usr/local/bin/QTLtools upstream/bin/QTLtools
docker rm "$cid"
tar -C upstream -czf upstream/QTLtools_1.3.1_linux64.tar.gz bin/QTLtools
shasum -a 256 upstream/QTLtools_1.3.1_linux64.tar.gz >> upstream/SHA256SUMS

# Conda (linux-64 binary package; build from macOS is OK — no relink)
rattler-build build -r recipe --target-platform linux-64
anaconda upload --user YangmingSi output/linux-64/qtltools-*.conda
```
