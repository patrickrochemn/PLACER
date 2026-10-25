# Linux x86_64 / NVIDIA inference image, independent of Python packaging work.
FROM mambaorg/micromamba:2.9.0@sha256:7b93def90e48d6d7744938e31c29172e03b19bc9f56f0db512039f18efd21529 AS environment

COPY --chown=$MAMBA_USER:$MAMBA_USER docker/conda-linux-64.lock /tmp/conda-linux-64.lock
RUN micromamba install --yes --name base --file /tmp/conda-linux-64.lock && \
    micromamba clean --all --yes
ARG MAMBA_DOCKERFILE_ACTIVATE=1

# Git and build artifacts stay out of the final runtime image.
FROM environment AS se3-builder
USER root
RUN apt-get update && \
    apt-get install --yes --no-install-recommends git && \
    rm -rf /var/lib/apt/lists/*
USER $MAMBA_USER
RUN python -m pip wheel --no-deps --no-build-isolation --no-cache-dir \
    --wheel-dir /tmp/se3-wheels \
    "se3-transformer @ git+https://github.com/NVIDIA/DeepLearningExamples.git@729963dd47e7c8bd462ad10bfac7a7b0b604e6dd#subdirectory=DGLPyTorch/DrugDiscovery/SE3Transformer"

FROM environment AS runtime
COPY --from=se3-builder --chown=$MAMBA_USER:$MAMBA_USER /tmp/se3-wheels /tmp/se3-wheels
RUN python -m pip install --no-deps --no-cache-dir /tmp/se3-wheels/*.whl && \
    rm -rf /tmp/se3-wheels

USER root
RUN mkdir -p /work && chmod 1777 /work
COPY --chown=$MAMBA_USER:$MAMBA_USER PLACER.py run_PLACER.py LICENSE README.md /opt/placer/
COPY --chown=$MAMBA_USER:$MAMBA_USER modules/ /opt/placer/modules/
COPY --chown=$MAMBA_USER:$MAMBA_USER data/ /opt/placer/data/
COPY --chown=$MAMBA_USER:$MAMBA_USER weights/ /opt/placer/weights/
COPY --chown=$MAMBA_USER:$MAMBA_USER examples/inputs/dnHEM1_apo.pdb /opt/placer/examples/inputs/dnHEM1_apo.pdb
USER $MAMBA_USER

ENV PYTHONPATH=/opt/placer \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DGLBACKEND=pytorch \
    OMP_NUM_THREADS=1 \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility
WORKDIR /work
ENTRYPOINT ["/usr/local/bin/_entrypoint.sh", "python", "/opt/placer/run_PLACER.py"]
CMD ["--help"]
