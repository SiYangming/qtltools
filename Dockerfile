# QTLtools 1.3.1 — tag must match conda: quay.io/bioinfortools/qtltools:1.3.1
# linux/amd64. Compile from the official source tarball (no official bioconda/biocontainers).
FROM public.ecr.aws/docker/library/ubuntu:22.04 AS build

LABEL org.opencontainers.image.title="qtltools-build"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        build-essential \
        g++ \
        gfortran \
        make \
        wget \
        bzip2 \
        zlib1g-dev \
        libbz2-dev \
        liblzma-dev \
        libcurl4-openssl-dev \
        libssl-dev \
        libgsl-dev \
        libboost-iostreams-dev \
        libboost-program-options-dev \
        r-mathlib \
        pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/src

# HTSlib 1.9 (paths used in upstream Makefile examples)
RUN wget -q https://github.com/samtools/htslib/releases/download/1.9/htslib-1.9.tar.bz2 \
    && tar -xjf htslib-1.9.tar.bz2 \
    && cd htslib-1.9 \
    && ./configure --disable-libcurl \
    && make -j"$(nproc)"

COPY upstream/QTLtools_1.3.1_source.tar.gz /tmp/qtltools-src.tar.gz

RUN tar -xzf /tmp/qtltools-src.tar.gz -C /opt/src \
    && cd /opt/src/qtltools \
    && BOOST_LIB=$(dirname "$(find /usr -name 'libboost_iostreams.a' | head -1)") \
    && RMATH_LIB=$(dirname "$(find /usr -name 'libRmath.a' | head -1)") \
    && RMATH_INC=$(dirname "$(find /usr -name 'Rmath.h' | head -1)") \
    && sed -i \
        -e "s|^BOOST_INC=.*|BOOST_INC=/usr/include|" \
        -e "s|^BOOST_LIB=.*|BOOST_LIB=${BOOST_LIB}|" \
        -e "s|^RMATH_INC=.*|RMATH_INC=${RMATH_INC}|" \
        -e "s|^RMATH_LIB=.*|RMATH_LIB=${RMATH_LIB}|" \
        -e "s|^HTSLD_INC=.*|HTSLD_INC=/opt/src/htslib-1.9|" \
        -e "s|^HTSLD_LIB=.*|HTSLD_LIB=/opt/src/htslib-1.9|" \
        Makefile \
    && mkdir -p obj bin \
    && make -j"$(nproc)" \
    && make prefix=/opt/qtltools install

FROM public.ecr.aws/docker/library/ubuntu:22.04

LABEL org.opencontainers.image.title="qtltools" \
      org.opencontainers.image.version="1.3.1" \
      org.opencontainers.image.description="QTLtools 1.3.1 plus plink2/htslib helpers for cis mapping" \
      org.opencontainers.image.source="https://github.com/SiYangming/qtltools"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        wget \
        bzip2 \
        libgomp1 \
        libgsl27 \
        libboost-iostreams1.74.0 \
        libboost-program-options1.74.0 \
        libcurl4 \
        zlib1g \
        libbz2-1.0 \
        liblzma5 \
        tabix \
        gzip \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /opt/qtltools/bin/QTLtools /usr/local/bin/QTLtools

# plink2 2.00a5.10 linux-64 from bioconda (same pin as variant2qtl environment.yml)
RUN wget -q -O /tmp/plink2.tar.bz2 https://anaconda.org/bioconda/plink2/2.00a5.10/download/linux-64/plink2-2.00a5.10-h4ac6f70_0.tar.bz2 \
    && mkdir -p /tmp/plink2 \
    && tar -xjf /tmp/plink2.tar.bz2 -C /tmp/plink2 \
    && install -m 0755 /tmp/plink2/bin/plink2 /usr/local/bin/plink2 \
    && rm -rf /tmp/plink2.tar.bz2 /tmp/plink2

WORKDIR /data
