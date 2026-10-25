# PLACER Linux / NVIDIA container

This image packages the existing PLACER CLI, checkpoint, chemical dictionaries,
and an inference environment. It does not depend on the separate pip-packaging
branch and does not change the scientific implementation.

## Supported target

- Linux x86_64 with an NVIDIA GPU, including Docker Desktop with the WSL2 backend.
- Python 3.10.16, PyTorch 2.3.1, CUDA 12.1, DGL 2.4.0, OpenBabel 3.1.1.
- SE(3) Transformer from NVIDIA DeepLearningExamples commit
  `729963dd47e7c8bd462ad10bfac7a7b0b604e6dd`.

The host needs a compatible NVIDIA driver and working Docker GPU access. A host
Conda environment or CUDA toolkit installation is not required. Apple Silicon
GPU acceleration and ARM64 are not supported by this Linux/CUDA image; use the
repository's native Mac environment instead. Other GPUs/platforms are untested.

The image includes model weights covered by the repository LICENSE. It is a
local prototype, not an official upstream image or a published registry release.
Third-party packages retain their installed notices and licenses.

## Build

From the repository root, with a running Docker engine:

```bash
docker build --platform linux/amd64 -t placer:cuda12.1-local .
```

The initial build downloads approximately 3 GiB of Conda packages plus the base
image and SE(3) build sources. Allow additional space for extracted libraries,
build cache, and image layers. Notebook tools and the full CUDA development
toolkit are not included. Downloads are needed at build time; the bundled
example can run without network access afterward.

## Help and GPU check

The default command displays CLI help, without loading the model:

```bash
docker run --rm placer:cuda12.1-local
```

Verify PyTorch GPU access before running an inference job:

```bash
docker run --rm --gpus all --entrypoint /opt/conda/bin/python \
  placer:cuda12.1-local -c \
  'import torch; assert torch.cuda.is_available(); print(torch.cuda.get_device_name(0))'
```

## One-sample bundled example

From a Linux/WSL shell with Docker integration enabled:

```bash
mkdir -p container-output
docker run --rm --gpus all --network none \
  --user "$(id -u):$(id -g)" --env HOME=/tmp \
  --mount "type=bind,source=$(pwd)/container-output,target=/output" \
  placer:cuda12.1-local \
  --ifile /opt/placer/examples/inputs/dnHEM1_apo.pdb \
  --odir /output --target_res A-149 --nsamples 1
```

Expected outputs are `dnHEM1_apo_model.pdb` and `dnHEM1_apo.csv`. This is an
operational smoke test, not a scientific accuracy benchmark. Results are
stochastic and need not match another run numerically. The PDB represents the
modeled region rather than a replacement for the entire input structure.

Windows PowerShell users can run the same example with Docker Desktop:

```powershell
New-Item -ItemType Directory -Force .\container-output | Out-Null
$placerOutput = (Resolve-Path .\container-output).Path
docker run --rm --gpus all --network none `
  --mount "type=bind,source=$placerOutput,target=/output" `
  placer:cuda12.1-local `
  --ifile /opt/placer/examples/inputs/dnHEM1_apo.pdb `
  --odir /output --target_res A-149 --nsamples 1
```

## Your own structures

Mount the input folder read-only and the output folder separately. Paths passed
to PLACER must be container paths, not host paths:

```bash
docker run --rm --gpus all \
  --user "$(id -u):$(id -g)" --env HOME=/tmp \
  --mount "type=bind,source=/absolute/input-folder,target=/input,readonly" \
  --mount "type=bind,source=/absolute/output-folder,target=/output" \
  placer:cuda12.1-local \
  --ifile /input/structure.pdb --odir /output --target_res A-149 --nsamples 1
```

Use the appropriate target residue or ligand options for the input structure;
`A-149` is specific to the bundled example. The output directory must exist and
be writable by the selected container user. `OMP_NUM_THREADS` defaults to 1 to
avoid excessive worker creation; override with `-e OMP_NUM_THREADS=4` if needed.
The container runs as a non-root user by default. Linux users can select their
own UID/GID as shown above to keep generated files owned by their host account.
`HOME=/tmp` gives an arbitrary UID a writable location for temporary library caches.

Custom weights can be mounted read-only and selected using `--weights`.
No host source checkout, environment, or resource directories are needed at run
time for the bundled example.

For the measured local build size and checks, see [VALIDATION.md](VALIDATION.md).

## Dependency maintenance

`conda-linux-64.lock` contains exact package URLs and MD5 archive checksums,
exported from the working WSL environment's inference dependency closure. These
are historical compatibility pins rather than a rolling dependency update. Package channels must continue to serve these archives
for future builds. Explicit locks do not solve or validate compatibility; every
updated lock needs a fresh build and runtime checks.

To regenerate from an independently validated Linux x86_64 Conda environment:

```bash
python docker/lock_environment.py \
  --prefix "$CONDA_PREFIX" --output docker/conda-linux-64.lock
```

The exporter reads installed Conda package records and follows their declared
dependencies. It does not include arbitrary pip packages; the required SE(3)
source revision is pinned separately in the Dockerfile. Its upstream training
entry points are outside this image's supported inference workflow. Git/build
artifacts are isolated in a build stage rather than shipped in the runtime.

The base image is pinned by digest. Updating the base, lock, or SE(3) revision
requires rerunning CLI help, GPU checks, and the one-sample offline test. No image
is automatically published and no existing host environment is modified.
